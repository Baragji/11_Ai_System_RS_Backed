import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildServer, type BuildServerOptions } from './server.js';
import type { AuthContext } from './lib/oidc.js';
import type { TaskPayload } from './routes/tasks.js';

const sampleTask: TaskPayload = {
  taskId: '123e4567-e89b-12d3-a456-426614174000',
  agent: 'planner',
  payload: { example: 'payload' },
  priority: 5
};

const authorizedContext: AuthContext = {
  subject: 'tester',
  scope: 'tasks:write',
  claims: { sub: 'tester' }
};

function createServer(options: Partial<BuildServerOptions> = {}) {
  const mergedOptions: BuildServerOptions = {
    enqueueTask: async () => undefined,
    enableDependencyHealthChecks: false,
    verifyAccessToken: async () => authorizedContext,
    skipResourceShutdown: true,
    ...options
  };
  const app = buildServer(mergedOptions);
  return app;
}

test('returns RFC 9457 problem when bearer token is missing', async (t) => {
  const app = createServer();
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: 'POST',
    url: '/tasks',
    payload: sampleTask
  });

  assert.equal(response.statusCode, 401);
  const body = response.json();
  assert.equal(body.status, 401);
  assert.equal(body.title, 'Missing bearer token');
  assert.equal(body.type, 'about:blank');
});

test('returns RFC 9457 problem when bearer token verification fails', async (t) => {
  let verifyAttempts = 0;
  const app = createServer({
    verifyAccessToken: async () => {
      verifyAttempts += 1;
      throw new Error('invalid token');
    }
  });
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: 'POST',
    url: '/tasks',
    payload: sampleTask,
    headers: {
      authorization: 'Bearer invalid'
    }
  });

  assert.equal(verifyAttempts, 1);
  assert.equal(response.statusCode, 401);
  const body = response.json();
  assert.equal(body.status, 401);
  assert.equal(body.title, 'Invalid bearer token');
  assert.equal(body.type, 'about:blank');
});

test('readiness succeeds without invoking dependency checks when disabled', async (t) => {
  let dependencyChecks = 0;
  const app = createServer({
    dependencyHealthCheck: async () => {
      dependencyChecks += 1;
    },
    enableDependencyHealthChecks: false
  });
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: 'GET',
    url: '/health/ready'
  });

  assert.equal(response.statusCode, 200);
  const body = response.json();
  assert.equal(body.status, 'ok');
  assert.equal(dependencyChecks, 0);
});

test('readiness executes dependency checks when enabled', async (t) => {
  let dependencyChecks = 0;
  const app = createServer({
    dependencyHealthCheck: async () => {
      dependencyChecks += 1;
    },
    enableDependencyHealthChecks: true
  });
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: 'GET',
    url: '/health/ready'
  });

  assert.equal(response.statusCode, 200);
  assert.equal(dependencyChecks, 1);
});

test('authorized task submission enqueues payload', async (t) => {
  const enqueued: TaskPayload[] = [];
  const app = createServer({
    enqueueTask: async (payload) => {
      enqueued.push(payload);
    }
  });
  t.after(async () => {
    await app.close();
  });

  const response = await app.inject({
    method: 'POST',
    url: '/tasks',
    payload: sampleTask,
    headers: {
      authorization: 'Bearer valid'
    }
  });

  assert.equal(response.statusCode, 202);
  assert.deepEqual(enqueued, [sampleTask]);
});
