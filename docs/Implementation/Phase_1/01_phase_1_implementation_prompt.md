# PHASE 1 IMPLEMENTATION - BUILD THE DISTRIBUTED STATE FABRIC NOW

You are a senior distributed systems engineer who has been tasked with IMPLEMENTING Phase 1 on top of the Phase 0 foundation that was just delivered. Your job is to build the actual distributed state management, event sourcing, and resilience infrastructure - not document it.

## IMMEDIATE DELIVERABLES REQUIRED

You MUST create working code and configurations for the distributed state fabric. No theoretical bullshit - IMPLEMENT:

### 1. EVENT SOURCING & TRANSACTIONAL OUTBOX
Build the actual event sourcing infrastructure:

**DELIVER**:
- SQL schemas for event_store, event_outbox, saga_orchestration tables
- Node.js event sourcing library with aggregate root pattern
- Transactional outbox implementation with Postgres triggers
- Debezium connector configuration for CDC to Kafka
- Event replay mechanism with snapshotting
- Idempotency key enforcement for commands

### 2. KAFKA INTEGRATION & SCHEMA REGISTRY
Create production Kafka setup:

**DELIVER**:
- Schema Registry deployment with AVRO schemas for all events
- Kafka topic configurations with partitioning strategy
- Producer/Consumer implementations with exactly-once semantics
- Dead letter queue handling for poison messages
- Consumer lag monitoring and alerting
- Topic ACL configurations for security

### 3. SAGA ORCHESTRATION ENGINE
Build the distributed workflow coordinator:

**DELIVER**:
- Saga definition framework with compensation logic
- State machine implementation for Planner→Coder→Critic workflow
- Timeout and retry mechanisms with exponential backoff
- Manual intervention hooks for stuck sagas
- Saga instance persistence and recovery
- Workflow visualization endpoints

### 4. REDIS STATE MANAGEMENT
Implement high-performance state caching:

**DELIVER**:
- Redis Cluster configuration with replication
- Distributed locking implementation with lease renewal
- Session state management with TTL policies
- Cache invalidation patterns
- Redis Streams for real-time updates
- Lua scripts for atomic operations

### 5. SELF-HEALING & CHAOS TESTING
Build resilience mechanisms:

**DELIVER**:
- Circuit breaker implementation for all external calls
- Kubernetes liveness/readiness probes with proper health checks
- Auto-scaling policies based on queue depth and CPU
- Chaos Monkey configuration for Litmus
- Automated recovery scripts for common failure scenarios
- SLA monitoring with breach alerting

### 6. STATE API & CONTEXT MANAGEMENT
Create the shared context service:

**DELIVER**:
- gRPC service definition for state operations
- Optimistic concurrency control with version vectors
- Context snapshot + delta compression
- Multi-tenant data isolation with RLS
- Audit logging for all state mutations
- GraphQL subscription layer for real-time updates

## TECHNICAL REQUIREMENTS

### DISTRIBUTED SYSTEMS FUNDAMENTALS
- Implement proper vector clocks for causality
- Handle network partitions with eventual consistency
- Use CRDTs where appropriate for conflict resolution
- Implement proper leader election for singleton processes
- Handle split-brain scenarios gracefully

### PRODUCTION RESILIENCE
- All services must have proper graceful shutdown
- Database connections must use connection pooling
- Implement proper backpressure mechanisms
- Handle cascading failure scenarios
- Provide proper circuit breaker patterns

### PERFORMANCE REQUIREMENTS
- Event processing latency < 100ms p95
- Saga completion time < 30 seconds p95
- Redis operations < 10ms p99
- Support 1000+ concurrent workflows
- Handle 10k+ events per second throughput

## SPECIFIC DELIVERABLE FORMAT

For each component, provide:

### 1. DATABASE SCHEMAS
```sql
-- /apps/api/migrations/002_event_sourcing.sql
CREATE TABLE event_store (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id UUID NOT NULL,
    aggregate_type VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(aggregate_id, version)
);

-- Include complete schemas for all tables
```

### 2. EVENT SOURCING IMPLEMENTATION
```typescript
// /apps/api/src/lib/event-store.ts
export class EventStore {
  async appendEvents(
    aggregateId: string,
    events: DomainEvent[],
    expectedVersion: number
  ): Promise<void> {
    // Complete implementation with optimistic concurrency
  }
}

// Complete working TypeScript code
```

### 3. KAFKA CONFIGURATIONS
```yaml
# /k8s/kafka/schema-registry.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: schema-registry
spec:
  # Complete working Kubernetes manifest
```

### 4. SAGA ORCHESTRATOR
```typescript
// /apps/api/src/lib/saga-orchestrator.ts
export class SagaOrchestrator {
  async startSaga(sagaType: string, payload: any): Promise<string> {
    // Complete saga implementation with compensation
  }
}
```

### 5. CHAOS TESTING CONFIG
```yaml
# /k8s/chaos/litmus-experiments.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: postgres-pod-delete
spec:
  # Complete chaos experiment definitions
```

## INTEGRATION REQUIREMENTS

### PHASE 0 FOUNDATION INTEGRATION
- Use the existing OpenTelemetry setup for distributed tracing
- Integrate with the Postgres/Redis/Kafka from Phase 0
- Leverage the security policies and RBAC already established
- Build on the observability stack (Prometheus/Grafana)

### API INTEGRATION POINTS
- Extend the existing Fastify API with state management endpoints
- Add gRPC server alongside REST API
- Integrate with existing health check framework
- Use the established error handling patterns

### TESTING REQUIREMENTS
- Unit tests with >85% coverage
- Integration tests for all Kafka/Redis/Postgres interactions
- Chaos engineering tests with recovery validation
- Load testing scenarios with performance benchmarks
- End-to-end saga execution tests

## MONITORING & OBSERVABILITY

### METRICS TO IMPLEMENT
- Event processing throughput and latency
- Saga success/failure rates and duration
- Redis cache hit/miss rates
- Database connection pool utilization
- Kafka consumer lag by topic/partition

### ALERTS TO CONFIGURE
- Saga timeout/failure rate > 5%
- Event processing lag > 1 minute
- Redis memory usage > 80%
- Database connection pool exhaustion
- Kafka consumer lag > 10,000 messages

## NO FUCKING SHORTCUTS

- Every service must handle graceful shutdown properly
- All database operations must be transactional where required
- Error handling must include proper logging and metrics
- All external calls must have timeouts and retries
- Configuration must be externalized and validated

Your response should contain ONLY working code, configurations, and deployment manifests. No explanations, no architecture discussions - just the actual distributed state fabric that can be deployed and will handle production workloads.

BUILD THE STATE FABRIC NOW.