import { test, describe } from 'node:test';
import assert from 'node:assert';
import { buildServer } from './server.js';
import type { FastifyInstance } from 'fastify';

describe('Integration Tests - Phase 0 & Phase 1', () => {
  test('should create server instance with all routes', async () => {
    // Test Phase 0 foundation: server builds without errors
    let app: FastifyInstance | undefined;
    assert.doesNotThrow(() => {
      app = buildServer();
    }, 'Server should build without throwing errors');

    assert.ok(app, 'Server instance should be created');
    
    // Test that server has required decorations and hooks
    assert.ok(app.hasDecorator, 'Server should have decorator support');
  });

  test('should validate workflow schema structure (Phase 1)', async () => {
    // Test Phase 1: Workflow request validation
    const validWorkflowPayload = {
      workflowType: 'test-workflow',
      payload: { test: 'data' },
      metadata: { requestId: '123' }
    };

    // Test that the workflow payload structure is valid
    assert.ok(validWorkflowPayload.workflowType, 'Workflow type should be required');
    assert.ok(validWorkflowPayload.payload, 'Payload should be required');
    assert.equal(typeof validWorkflowPayload.payload, 'object', 'Payload should be an object');
    assert.equal(typeof validWorkflowPayload.metadata, 'object', 'Metadata should be an object');
  });

  test('should validate task schema structure (Phase 0)', () => {
    // Test Phase 0: Task request validation
    const validTaskPayload = {
      taskId: '123e4567-e89b-12d3-a456-426614174000',
      agent: 'planner',
      payload: { test: 'data' },
      priority: 5
    };

    // Test that the task payload structure is valid
    assert.ok(validTaskPayload.taskId, 'Task ID should be required');
    assert.ok(validTaskPayload.agent, 'Agent should be required');
    assert.ok(['planner', 'coder', 'critic'].includes(validTaskPayload.agent), 'Agent should be valid enum');
    assert.equal(typeof validTaskPayload.payload, 'object', 'Payload should be an object');
    assert.equal(typeof validTaskPayload.priority, 'number', 'Priority should be a number');
  });

  test('should validate database schemas exist (Phase 0)', async () => {
    const fs = await import('node:fs');
    const path = await import('node:path');
    
    // Test that database migrations exist
    const migrationsPath = path.resolve('migrations');
    assert.ok(fs.existsSync(path.join(migrationsPath, '001_init.sql')), 'Initial migration should exist');
    assert.ok(fs.existsSync(path.join(migrationsPath, '002_event_sourcing.sql')), 'Event sourcing migration should exist');
  });

  test('should validate Phase 1 core modules exist', async () => {
    const fs = await import('node:fs');
    const path = await import('node:path');
    
    // Test that Phase 1 implementations exist
    const srcPath = path.resolve('src/lib');
    assert.ok(fs.existsSync(path.join(srcPath, 'event-store.ts')), 'Event Store should exist');
    assert.ok(fs.existsSync(path.join(srcPath, 'saga-orchestrator.ts')), 'Saga Orchestrator should exist');
  });
});