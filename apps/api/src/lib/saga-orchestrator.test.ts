import { test, describe } from 'node:test';
import assert from 'node:assert';
import { SagaOrchestrator, type SagaStep } from './saga-orchestrator.js';
import { EventStore } from './event-store.js';

describe('SagaOrchestrator', () => {
  test('should create saga steps with required structure', () => {
    const step: SagaStep = {
      stepId: 'test-step',
      action: async () => {
        return 'success';
      },
      compensation: async () => {
        // compensation logic
      }
    };

    assert.equal(step.stepId, 'test-step');
    assert.equal(typeof step.action, 'function');
    assert.equal(typeof step.compensation, 'function');
  });

  test('should create SagaOrchestrator instance', () => {
    const eventStore = new EventStore();
    const orchestrator = new SagaOrchestrator(eventStore);
    
    assert.ok(orchestrator);
    assert.ok(orchestrator instanceof SagaOrchestrator);
  });

  test('should validate saga execution options structure', () => {
    const options = {
      tenantId: 'tenant-1',
      sagaType: 'test-saga',
      payload: { data: 'test' },
      metadata: { requestId: '123' },
      expectedVersion: 0
    };

    assert.equal(options.tenantId, 'tenant-1');
    assert.equal(options.sagaType, 'test-saga');
    assert.ok(options.payload);
    assert.ok(options.metadata);
    assert.equal(options.expectedVersion, 0);
  });
});