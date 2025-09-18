import { randomUUID } from 'node:crypto';
import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { EventStore } from '../lib/event-store.js';
import { SagaOrchestrator, type SagaStep } from '../lib/saga-orchestrator.js';
import { withErrorHandling } from '../lib/problem.js';
import type { AuthContext } from '../lib/oidc.js';
import { redisClient } from '../lib/redis.js';
import { logger } from '../observability/otel.js';

type UnknownRecord = Record<string, unknown>;

const workflowStartSchema = z.object({
  workflowType: z.string().min(1),
  payload: z.record(z.string(), z.unknown()),
  metadata: z.record(z.string(), z.unknown()).optional()
});

export interface WorkflowPluginOptions {
  orchestrator?: SagaOrchestrator;
}

const workflow: FastifyPluginAsync<WorkflowPluginOptions> = async (fastify, options) => {
  const eventStore = new EventStore();
  const orchestrator = options.orchestrator ?? new SagaOrchestrator(eventStore);

  fastify.post('/workflow/start', {
    schema: {
      body: workflowStartSchema
    }
  }, withErrorHandling(async (request, reply) => {
    const body = workflowStartSchema.parse(request.body);
    const tenantId = resolveTenantId(request.auth, request.headers['x-tenant-id']);

    if (!tenantId) {
      throw fastify.httpErrors.forbidden('Tenant context missing from authentication token');
    }

    const sagaId = randomUUID();
    const steps = buildSagaSteps({
      tenantId,
      sagaId,
      workflowType: body.workflowType,
      payload: body.payload as UnknownRecord
    });

    const metadata = {
      ...(body.metadata as UnknownRecord | undefined ?? {}),
      requestedBy: request.auth?.subject ?? 'anonymous',
      requestId: request.id
    } satisfies UnknownRecord;

    void orchestrator.executeSaga(sagaId, steps, {
      tenantId,
      sagaType: body.workflowType,
      payload: body.payload as UnknownRecord,
      metadata,
      expectedVersion: 0
    }).catch((error) => {
      request.log.error({ err: error, sagaId, tenantId }, 'Saga execution failed');
    });

    logger.info({ sagaId, workflowType: body.workflowType, tenantId }, 'Workflow saga started');

    return reply.status(202).send({
      sagaId,
      workflowType: body.workflowType,
      status: 'accepted'
    });
  }));
};

export default workflow;

function resolveTenantId(auth: AuthContext | null, headerValue: string | string[] | undefined): string | null {
  return extractTenantFromClaims(auth) ?? extractTenantFromHeader(headerValue);
}

function extractTenantFromClaims(auth: AuthContext | null): string | null {
  if (!auth?.claims) {
    return null;
  }

  const claims = auth.claims as Record<string, unknown>;
  const candidateKeys = ['tenant_id', 'tenantId', 'tid', 'org_id', 'orgId'];

  for (const key of candidateKeys) {
    const value = claims[key];
    if (typeof value === 'string' && value.length > 0) {
      return value;
    }
  }

  for (const [key, value] of Object.entries(claims)) {
    if (typeof value === 'string' && (key.endsWith('/tenant') || key.endsWith('/tenant_id'))) {
      return value;
    }
  }

  return null;
}

function extractTenantFromHeader(headerValue: string | string[] | undefined): string | null {
  if (!headerValue) {
    return null;
  }

  if (Array.isArray(headerValue)) {
    return headerValue.find((value) => typeof value === 'string' && value.length > 0) ?? null;
  }

  return typeof headerValue === 'string' && headerValue.length > 0 ? headerValue : null;
}

function buildSagaSteps(params: {
  tenantId: string;
  sagaId: string;
  workflowType: string;
  payload: UnknownRecord;
}): SagaStep[] {
  const { tenantId, sagaId, workflowType, payload } = params;
  const redisKey = `workflow:${tenantId}:${sagaId}`;

  const serializeState = (state: string): string => JSON.stringify({
    state,
    workflowType,
    payload,
    updatedAt: new Date().toISOString()
  });

  const setState = async (state: string): Promise<void> => {
    await redisClient.set(redisKey, serializeState(state), 'EX', 3600);
  };

  return [
    {
      stepId: 'cache-workflow-payload',
      action: async () => {
        await setState('pending');
      },
      compensation: async () => {
        await redisClient.del(redisKey);
      }
    },
    {
      stepId: 'mark-workflow-prepared',
      action: async () => {
        await setState('prepared');
      },
      compensation: async () => {
        await setState('pending');
      }
    }
  ];
}
