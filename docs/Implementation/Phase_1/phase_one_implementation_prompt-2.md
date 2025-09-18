# PHASE 1 IMPLEMENTATION - CONTEXTUAL FOUNDATION FIRST

You are a senior distributed systems engineer implementing Phase 1 of the AI platform. Before building anything new, you must first understand the Phase 0 foundation that was delivered.

## STEP 1: ANALYZE THE EXISTING CODEBASE

Examine and understand these Phase 0 components:
- Database schema in `/apps/api/migrations/001_init.sql`
- API structure and patterns in `/apps/api/src/`
- Kafka integration in `/apps/api/src/lib/kafka.ts`
- Redis integration in `/apps/api/src/lib/redis.ts`
- OpenTelemetry setup in `/apps/api/src/observability/otel.ts`
- Health check patterns in `/apps/api/src/routes/health.ts`

**DELIVERABLE**: Provide a technical summary of the existing architecture and integration patterns you'll build upon.

## STEP 2: EVENT SOURCING FOUNDATION (Focus on Database First)

Build the event sourcing layer that integrates with the existing Postgres setup:

**DELIVER**:
```sql
-- /apps/api/migrations/002_event_sourcing.sql
CREATE TABLE event_store (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_id UUID NOT NULL,
  aggregate_type VARCHAR(100) NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB NOT NULL,
  event_version INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(aggregate_id, event_version)
);

-- Add complete schema with indexes and RLS
```

```typescript
// /apps/api/src/lib/event-store.ts
import { Pool } from 'pg';
import { getPool } from './postgres.js';

export interface DomainEvent {
  aggregateId: string;
  eventType: string;
  eventData: any;
  metadata?: any;
}

export class EventStore {
  private pool: Pool;
  
  constructor() {
    this.pool = getPool(); // Use existing connection
  }
  
  async appendEvents(
    aggregateId: string,
    events: DomainEvent[],
    expectedVersion: number
  ): Promise<void> {
    // Complete implementation using existing transaction patterns
  }
}
```

**VALIDATION**: The code must compile with existing TypeScript setup and use the established database connection patterns.

## STEP 3: SIMPLE SAGA ORCHESTRATOR (Build on Existing Patterns)

Create a basic saga engine that extends the current API structure:

**DELIVER**:
```typescript
// /apps/api/src/lib/saga-orchestrator.ts
import { EventStore } from './event-store.js';
import { logger } from '../observability/otel.js';

export interface SagaStep {
  stepId: string;
  action: () => Promise<any>;
  compensation: () => Promise<void>;
}

export class SagaOrchestrator {
  constructor(private eventStore: EventStore) {}
  
  async executeSaga(sagaId: string, steps: SagaStep[]): Promise<void> {
    // Implementation with proper error handling and OpenTelemetry tracing
  }
}
```

```sql
-- Add to migration 002
CREATE TABLE saga_instances (
  saga_id UUID PRIMARY KEY,
  saga_type VARCHAR(100) NOT NULL,
  current_step INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'running',
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## STEP 4: INTEGRATE WITH EXISTING API ROUTES

Add state management endpoints to the current API:

**DELIVER**:
```typescript
// /apps/api/src/routes/workflow.ts
import { FastifyPluginAsync } from 'fastify';
import { SagaOrchestrator } from '../lib/saga-orchestrator.js';
import { withErrorHandling } from '../lib/problem.js'; // Use existing error handling

const workflow: FastifyPluginAsync = async (fastify) => {
  const orchestrator = new SagaOrchestrator(/* existing dependencies */);
  
  fastify.post('/workflow/start', {
    schema: {
      body: {
        type: 'object',
        required: ['workflowType', 'payload'],
        properties: {
          workflowType: { type: 'string' },
          payload: { type: 'object' }
        }
      }
    }
  }, withErrorHandling(async (request, reply) => {
    // Implementation using established patterns
  }));
};

export default workflow;
```

## PERFORMANCE REQUIREMENTS (Realistic for Phase 1)

- Event append latency: < 50ms p95 (achievable with proper indexing)
- Saga step execution: < 5 seconds p95 (reasonable for initial implementation)
- Support 100 concurrent workflows (scale up later)
- Database connection reuse (leverage existing pool)

## INTEGRATION CONSTRAINTS

- Must use existing OpenTelemetry instrumentation patterns
- Must follow established error handling with RFC 9457
- Must integrate with existing health check system
- Cannot break existing API functionality
- Must use existing Kafka/Redis connection patterns

## VALIDATION REQUIREMENTS

After each deliverable:
```bash
# These must pass
npm run build --workspace apps/api
npm run test --workspace apps/api  # if tests exist
kubectl apply --dry-run=client -f k8s/
```

## NO ARCHITECTURAL REWRITES

- Build ON TOP of existing code, don't replace it
- Reuse existing database connections, don't create new ones
- Extend existing API routes, don't restructure them
- Add observability to existing patterns, don't reinvent them

Your response should focus on ONE step at a time, starting with Step 1 (codebase analysis) and then moving to Step 2 (event sourcing foundation). Build incrementally and validate each step before proceeding.