import Fastify, { type FastifyInstance } from 'fastify';
import fastifyHelmet from '@fastify/helmet';
import fastifyRateLimit from '@fastify/rate-limit';
import fastifySensible from '@fastify/sensible';
import { ZodTypeProvider } from 'fastify-type-provider-zod';
import { env } from './config/env.js';
import { problemErrorHandler } from './lib/problem.js';
import { verifyPostgres, postgresPool } from './lib/postgres.js';
import { redisClient, verifyRedis } from './lib/redis.js';
import { kafka, verifyKafka } from './lib/kafka.js';
import { verifyAccessToken } from './lib/oidc.js';
import { registerHealthRoutes } from './routes/health.js';
import { registerTaskRoutes, type TaskPayload } from './routes/tasks.js';
import workflowRoutes from './routes/workflow.js';

export function buildServer(): FastifyInstance {
  const app = Fastify({
    trustProxy: true,
    logger: {
      level: env.NODE_ENV === 'production' ? 'info' : 'debug',
      transport: env.NODE_ENV === 'development' ? { target: 'pino-pretty' } : undefined
    }
  }).withTypeProvider<ZodTypeProvider>();

  void app.register(fastifyHelmet, {
    contentSecurityPolicy: false
  });
  void app.register(fastifyRateLimit, {
    max: 100,
    timeWindow: '1 minute'
  });
  void app.register(fastifySensible);

  app.decorateRequest('auth', null);

  app.addHook('onRequest', async (request, reply) => {
    if (request.routerPath?.startsWith('/health')) {
      request.auth = null;
      return;
    }

    const authHeader = request.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      reply.code(401);
      throw new Error('Missing bearer token');
    }
    const token = authHeader.slice('Bearer '.length);
    request.auth = await verifyAccessToken(token);
  });

  app.setErrorHandler(problemErrorHandler);

  registerHealthRoutes(app, {
    async check() {
      await Promise.all([verifyPostgres(), verifyRedis(), verifyKafka()]);
    }
  });
  const producer = kafka.producer();
  let producerReady = false;
  let producerConnectPromise: Promise<void> | null = null;

  async function ensureProducer(): Promise<void> {
    if (producerReady) {
      return;
    }
    if (!producerConnectPromise) {
      producerConnectPromise = producer.connect()
        .then(() => {
          producerReady = true;
        })
        .finally(() => {
          producerConnectPromise = null;
        });
    }
    await producerConnectPromise;
  }

  registerTaskRoutes(app, {
    async enqueueTask(payload: TaskPayload) {
      await ensureProducer();
      await producer.send({
        topic: 'agent.tasks',
        messages: [{
          key: payload.taskId,
          value: JSON.stringify(payload)
        }]
      });
    }
  });

  void app.register(workflowRoutes);

  app.addHook('onClose', async () => {
    await Promise.all([
      postgresPool.end(),
      redisClient.quit(),
      producer.disconnect().then(() => {
        producerReady = false;
      }).catch(() => undefined)
    ]);
  });

  return app as FastifyInstance;
}
