import Fastify, { type FastifyInstance, type FastifyError } from 'fastify';
import fastifyHelmet from '@fastify/helmet';
import fastifyRateLimit from '@fastify/rate-limit';
import fastifySensible from '@fastify/sensible';
import { ZodTypeProvider, validatorCompiler, serializerCompiler } from 'fastify-type-provider-zod';
import { env } from './config/env.js';
import { problemErrorHandler } from './lib/problem.js';
import { verifyPostgres, postgresPool } from './lib/postgres.js';
import { redisClient, verifyRedis } from './lib/redis.js';
import { kafka, verifyKafka } from './lib/kafka.js';
import { verifyAccessToken, type AuthContext } from './lib/oidc.js';
import { registerHealthRoutes } from './routes/health.js';
import { registerTaskRoutes, type TaskPayload } from './routes/tasks.js';
import workflowRoutes from './routes/workflow.js';

export interface BuildServerOptions {
  verifyAccessToken?: (token: string) => Promise<AuthContext>;
  dependencyHealthCheck?: () => Promise<void>;
  enableDependencyHealthChecks?: boolean;
  enqueueTask?: (payload: TaskPayload) => Promise<void>;
  skipResourceShutdown?: boolean;
}

function hasStatusCode(error: unknown): error is FastifyError {
  return typeof error === 'object' && error !== null && 'statusCode' in error &&
    typeof (error as Partial<FastifyError>).statusCode === 'number';
}

export function buildServer(options: BuildServerOptions = {}): FastifyInstance {
  const app = Fastify({
    trustProxy: true,
    logger: {
      level: env.NODE_ENV === 'production' ? 'info' : 'debug',
      transport: env.NODE_ENV === 'development' ? { target: 'pino-pretty' } : undefined
    }
  }).withTypeProvider<ZodTypeProvider>();

  // Enable Zod-based validation and serialization
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  void app.register(fastifyHelmet, {
    contentSecurityPolicy: false
  });
  void app.register(fastifyRateLimit, {
    max: 100,
    timeWindow: '1 minute'
  });
  void app.register(fastifySensible);

  app.decorateRequest('auth', null);

  const verifyToken = options.verifyAccessToken ?? verifyAccessToken;
  const dependencyHealthCheck = options.dependencyHealthCheck ?? (async () => {
    await Promise.all([verifyPostgres(), verifyRedis(), verifyKafka()]);
  });
  const shouldCheckDependencies = options.enableDependencyHealthChecks ?? (env.ENABLE_DEPENDENCY_HEALTHCHECKS === 'true');

  app.addHook('onRequest', async (request) => {
    const routeUrl = request.routeOptions?.url;
    if (routeUrl?.startsWith('/health')) {
      request.auth = null;
      return;
    }

    const authHeader = request.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw app.httpErrors.unauthorized('Missing bearer token');
    }
    const token = authHeader.slice('Bearer '.length);
    try {
      request.auth = await verifyToken(token);
    } catch (error) {
      request.auth = null;
      if (hasStatusCode(error)) {
        throw error;
      }
      request.log.warn({ err: error }, 'Failed to verify access token');
      throw app.httpErrors.unauthorized('Invalid bearer token');
    }
  });

  app.setErrorHandler(problemErrorHandler);

  registerHealthRoutes(app, {
    async check() {
      if (!shouldCheckDependencies) {
        return;
      }
      await dependencyHealthCheck();
    }
  });

  let closeTaskResources: (() => Promise<void>) | null = null;
  let enqueueTask: (payload: TaskPayload) => Promise<void>;
  const skipResourceShutdown = options.skipResourceShutdown ?? false;

  if (options.enqueueTask) {
    enqueueTask = options.enqueueTask;
  } else {
    const producer = kafka.producer();
    let producerReady = false;
    let producerConnectPromise: Promise<void> | null = null;

    const ensureProducer = async (): Promise<void> => {
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
    };

    enqueueTask = async (payload: TaskPayload) => {
      await ensureProducer();
      await producer.send({
        topic: 'agent.tasks',
        messages: [{
          key: payload.taskId,
          value: JSON.stringify(payload)
        }]
      });
    };

    closeTaskResources = async () => {
      await producer.disconnect().then(() => {
        producerReady = false;
      }).catch(() => undefined);
    };
  }

  registerTaskRoutes(app, {
    async enqueueTask(payload: TaskPayload) {
      await enqueueTask(payload);
    }
  });

  void app.register(workflowRoutes);

  app.addHook('onClose', async () => {
    const shutdownTasks: Array<Promise<unknown>> = [];
    if (!skipResourceShutdown) {
      shutdownTasks.push(postgresPool.end());
      shutdownTasks.push(redisClient.quit().catch(() => undefined));
    }
    if (closeTaskResources) {
      shutdownTasks.push(closeTaskResources().catch(() => undefined));
    }
    await Promise.all(shutdownTasks);
  });

  return app as FastifyInstance;
}

