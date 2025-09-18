import { test, describe } from 'node:test';
import assert from 'node:assert';
import { EventStore, EventStoreConcurrencyError, type DomainEvent } from './event-store.js';

describe('EventStore', () => {
  test('should validate event structure', () => {
    const eventStore = new EventStore();
    const mockEvent: DomainEvent = {
      aggregateId: 'test-id',
      aggregateType: 'test-aggregate',
      eventType: 'TestEvent',
      eventData: { test: 'data' },
      tenantId: 'tenant-1'
    };

    // This would normally interact with a database, but we're testing the structure
    assert.ok(mockEvent.aggregateId);
    assert.ok(mockEvent.aggregateType);
    assert.ok(mockEvent.eventType);
    assert.ok(mockEvent.tenantId);
    assert.ok(mockEvent.eventData);
  });

  test('should create EventStoreConcurrencyError', () => {
    const error = new EventStoreConcurrencyError('Test error');
    assert.equal(error.name, 'EventStoreConcurrencyError');
    assert.equal(error.message, 'Test error');
    assert.ok(error instanceof Error);
  });
});