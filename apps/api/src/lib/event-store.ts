import { DatabaseError, Pool, PoolClient } from 'pg';
import { getPool } from './postgres.js';

export interface DomainEvent {
  aggregateId: string;
  aggregateType: string;
  eventType: string;
  eventData: unknown;
  tenantId: string;
  metadata?: Record<string, unknown>;
}

export class EventStoreConcurrencyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'EventStoreConcurrencyError';
  }
}

export class EventStore {
  private readonly pool: Pool;

  constructor(pool: Pool = getPool()) {
    this.pool = pool;
  }

  async appendEvents(
    aggregateId: string,
    events: DomainEvent[],
    expectedVersion: number
  ): Promise<void> {
    if (events.length === 0) {
      return;
    }

    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const tenantId = events[0]?.tenantId;
      if (!tenantId) {
        throw new Error('Tenant id is required to append events');
      }
      await client.query('SET LOCAL app.current_tenant = $1', [tenantId]);
      await this.assertAggregateVersion(client, aggregateId, expectedVersion);

      for (let index = 0; index < events.length; index += 1) {
        const event = events[index];
        this.validateEvent(event, aggregateId);
        if (event.tenantId !== tenantId) {
          throw new Error('All events appended in a batch must belong to the same tenant');
        }
        const nextVersion = expectedVersion + index + 1;

        await client.query(
          `INSERT INTO event_store (
            tenant_id,
            aggregate_id,
            aggregate_type,
            event_type,
            event_data,
            metadata,
            event_version
          ) VALUES ($1, $2, $3, $4, $5, COALESCE($6::jsonb, '{}'::jsonb), $7)`,
          [
            event.tenantId,
            aggregateId,
            event.aggregateType,
            event.eventType,
            event.eventData,
            event.metadata ?? {},
            nextVersion
          ]
        );
      }

      await client.query('COMMIT');
    } catch (error) {
      await this.safeRollback(client);
      if (error instanceof EventStoreConcurrencyError) {
        throw error;
      }
      if (isUniqueViolation(error)) {
        throw new EventStoreConcurrencyError(
          `Concurrency conflict while appending events for aggregate ${aggregateId}`
        );
      }
      throw error;
    } finally {
      client.release();
    }
  }

  private async assertAggregateVersion(
    client: PoolClient,
    aggregateId: string,
    expectedVersion: number
  ): Promise<void> {
    const { rows } = await client.query<{ event_version: number }>(
      `SELECT event_version
         FROM event_store
        WHERE aggregate_id = $1
        ORDER BY event_version DESC
        LIMIT 1
        FOR UPDATE`,
      [aggregateId]
    );
    const currentVersion = rows[0]?.event_version ?? 0;
    if (currentVersion !== expectedVersion) {
      throw new EventStoreConcurrencyError(
        `Expected version ${expectedVersion} but found ${currentVersion} for aggregate ${aggregateId}`
      );
    }
  }

  private validateEvent(event: DomainEvent, aggregateId: string): void {
    if (event.aggregateId !== aggregateId) {
      throw new Error('Event aggregateId must match append aggregateId');
    }
    if (!event.aggregateType) {
      throw new Error('Event aggregateType is required');
    }
    if (!event.tenantId) {
      throw new Error('Event tenantId is required');
    }
  }

  private async safeRollback(client: PoolClient): Promise<void> {
    try {
      await client.query('ROLLBACK');
    } catch {
      // ignore rollback errors to surface original issue
    }
  }
}

function isUniqueViolation(error: unknown): error is DatabaseError {
  return (
    error instanceof DatabaseError &&
    (error.code === '23505' || error.constraint === 'event_store_aggregate_id_event_version_key')
  );
}
