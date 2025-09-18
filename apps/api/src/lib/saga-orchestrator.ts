import { SpanStatusCode, trace } from '@opentelemetry/api';
import type { Pool, PoolClient } from 'pg';
import { EventStore, EventStoreConcurrencyError } from './event-store.js';
import { getPool } from './postgres.js';
import { logger } from '../observability/otel.js';

export interface SagaStep {
  stepId: string;
  action: () => Promise<unknown>;
  compensation: () => Promise<void>;
}

export interface SagaExecutionOptions {
  tenantId: string;
  sagaType: string;
  payload?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
  expectedVersion?: number;
}

export class SagaOrchestrator {
  private readonly tracer = trace.getTracer('saga-orchestrator');

  constructor(
    private readonly eventStore: EventStore,
    private readonly pool: Pool = getPool()
  ) {}

  async executeSaga(sagaId: string, steps: SagaStep[], options: SagaExecutionOptions): Promise<void> {
    if (!options) {
      throw new Error('Saga execution options are required');
    }

    const { tenantId, sagaType, payload = {}, metadata, expectedVersion = 0 } = options;
    const stepIds = steps.map((step) => step.stepId);
    const completedSteps: SagaStep[] = [];
    let currentVersion = expectedVersion;

    return this.tracer.startActiveSpan('SagaOrchestrator.executeSaga', async (span) => {
      span.setAttributes({
        'saga.id': sagaId,
        'saga.type': sagaType,
        'saga.step.count': steps.length
      });

      try {
        await this.initializeSagaInstance({ sagaId, tenantId, sagaType, payload, metadata });
        await this.appendSagaEvent({
          sagaId,
          tenantId,
          sagaType,
          metadata,
          eventType: 'SagaStarted',
          eventData: { steps: stepIds },
          expectedVersion: currentVersion
        });
        currentVersion += 1;

        for (let index = 0; index < steps.length; index += 1) {
          const step = steps[index];
          await this.updateSagaProgress({ sagaId, tenantId, currentStep: index + 1, status: 'running' });
          await this.tracer.startActiveSpan(`SagaStep.${step.stepId}`, async (stepSpan) => {
            stepSpan.setAttributes({ 'saga.step.id': step.stepId, 'saga.step.index': index });
            try {
              await step.action();
              completedSteps.push(step);
              await this.appendSagaEvent({
                sagaId,
                tenantId,
                sagaType,
                metadata,
                eventType: 'SagaStepCompleted',
                eventData: { stepId: step.stepId },
                expectedVersion: currentVersion
              });
              currentVersion += 1;
              stepSpan.setStatus({ code: SpanStatusCode.OK });
            } catch (error) {
              stepSpan.recordException(error as Error);
              const message = error instanceof Error ? error.message : 'Unknown saga step failure';
              stepSpan.setStatus({ code: SpanStatusCode.ERROR, message });
              throw error;
            } finally {
              stepSpan.end();
            }
          });
        }

        await this.updateSagaProgress({ sagaId, tenantId, currentStep: steps.length, status: 'completed' });
        await this.appendSagaEvent({
          sagaId,
          tenantId,
          sagaType,
          metadata,
          eventType: 'SagaCompleted',
          eventData: { steps: stepIds },
          expectedVersion: currentVersion
        });
        currentVersion += 1;

        span.setStatus({ code: SpanStatusCode.OK });
        logger.info({ sagaId, sagaType }, 'Saga completed successfully');
      } catch (error) {
        const failure = error instanceof Error ? error : new Error('Saga execution failed');
        span.recordException(failure);
        span.setStatus({ code: SpanStatusCode.ERROR, message: failure.message });
        logger.error({ err: failure, sagaId, sagaType }, 'Saga execution failed');

        await this.handleSagaFailure({
          sagaId,
          tenantId,
          sagaType,
          metadata,
          failure,
          completedSteps,
          currentVersion,
          failedStepId: completedSteps.length < steps.length ? steps[completedSteps.length]?.stepId : undefined
        });

        throw failure;
      } finally {
        span.end();
      }
    });
  }

  private async handleSagaFailure(params: {
    sagaId: string;
    tenantId: string;
    sagaType: string;
    metadata?: Record<string, unknown>;
    failure: Error;
    completedSteps: SagaStep[];
    currentVersion: number;
    failedStepId?: string;
  }): Promise<void> {
    const { sagaId, tenantId, sagaType, metadata, failure, completedSteps, failedStepId } = params;
    let { currentVersion } = params;

    await this.updateSagaProgress({ sagaId, tenantId, currentStep: completedSteps.length, status: 'compensating' });
    await this.appendSagaEvent({
      sagaId,
      tenantId,
      sagaType,
      metadata,
      eventType: 'SagaCompensationStarted',
      eventData: { failedStepId },
      expectedVersion: currentVersion
    });
    currentVersion += 1;

    for (let index = completedSteps.length - 1; index >= 0; index -= 1) {
      const step = completedSteps[index];
      try {
        await step.compensation();
        await this.appendSagaEvent({
          sagaId,
          tenantId,
          sagaType,
          metadata,
          eventType: 'SagaStepCompensated',
          eventData: { stepId: step.stepId },
          expectedVersion: currentVersion
        });
        currentVersion += 1;
      } catch (compensationError) {
        const compFailure = compensationError instanceof Error
          ? compensationError
          : new Error('Saga compensation failed');
        logger.error({ err: compFailure, sagaId, sagaType, stepId: step.stepId }, 'Saga compensation step failed');
        await this.appendSagaEvent({
          sagaId,
          tenantId,
          sagaType,
          metadata,
          eventType: 'SagaCompensationFailed',
          eventData: { stepId: step.stepId, reason: compFailure.message },
          expectedVersion: currentVersion
        });
        currentVersion += 1;
        break;
      }
    }

    await this.updateSagaProgress({ sagaId, tenantId, currentStep: completedSteps.length, status: 'failed' });
    await this.appendSagaEvent({
      sagaId,
      tenantId,
      sagaType,
      metadata,
      eventType: 'SagaFailed',
      eventData: { reason: failure.message, failedStepId },
      expectedVersion: currentVersion
    });
  }

  private async initializeSagaInstance(params: {
    sagaId: string;
    tenantId: string;
    sagaType: string;
    payload: Record<string, unknown>;
    metadata?: Record<string, unknown>;
  }): Promise<void> {
    const { sagaId, tenantId, sagaType, payload, metadata } = params;
    await this.withTenantConnection(tenantId, async (client) => {
      await client.query(
        `INSERT INTO saga_instances (saga_id, tenant_id, saga_type, payload, metadata, status, current_step)
         VALUES ($1, $2, $3, $4, COALESCE($5::jsonb, '{}'::jsonb), 'running', 0)
         ON CONFLICT (saga_id) DO UPDATE
           SET saga_type = EXCLUDED.saga_type,
               payload = EXCLUDED.payload,
               metadata = EXCLUDED.metadata,
               status = 'running',
               current_step = 0,
               updated_at = now()`,
        [sagaId, tenantId, sagaType, payload, metadata ?? {}]
      );
    });
  }

  private async updateSagaProgress(params: {
    sagaId: string;
    tenantId: string;
    currentStep: number;
    status: 'running' | 'completed' | 'compensating' | 'failed';
  }): Promise<void> {
    const { sagaId, tenantId, currentStep, status } = params;
    await this.withTenantConnection(tenantId, async (client) => {
      await client.query(
        `UPDATE saga_instances
            SET current_step = $2,
                status = $3
          WHERE saga_id = $1`,
        [sagaId, currentStep, status]
      );
    });
  }

  private async appendSagaEvent(params: {
    sagaId: string;
    tenantId: string;
    sagaType: string;
    metadata?: Record<string, unknown>;
    eventType: string;
    eventData: Record<string, unknown>;
    expectedVersion: number;
  }): Promise<void> {
    const { sagaId, tenantId, sagaType, metadata, eventType, eventData, expectedVersion } = params;
    try {
      await this.eventStore.appendEvents(
        sagaId,
        [
          {
            aggregateId: sagaId,
            aggregateType: `saga:${sagaType}`,
            eventType,
            eventData: sanitizeEventData(eventData),
            metadata,
            tenantId
          }
        ],
        expectedVersion
      );
    } catch (error) {
      if (error instanceof EventStoreConcurrencyError) {
        logger.error({ err: error, sagaId, sagaType }, 'Concurrency error while appending saga event');
      }
      throw error;
    }
  }

  private async withTenantConnection<T>(tenantId: string, handler: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('SET LOCAL app.current_tenant = $1', [tenantId]);
      const result = await handler(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await safeRollback(client);
      throw error;
    } finally {
      client.release();
    }
  }
}

async function safeRollback(client: PoolClient): Promise<void> {
  try {
    await client.query('ROLLBACK');
  } catch {
    // ignore rollback failures so the original error surfaces
  }
}

function sanitizeEventData(eventData: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(eventData).filter(([, value]) => value !== undefined)
  );
}
