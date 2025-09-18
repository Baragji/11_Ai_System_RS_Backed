import type { FastifyInstance } from 'fastify';
import { env } from '../config/env.js';

interface Dependencies {
  check: () => Promise<void>;
}

export function registerHealthRoutes(app: FastifyInstance, deps: Dependencies): void {
  app.get('/health/live', async () => ({
    status: 'ok',
    uptime: process.uptime(),
    version: env.SERVICE_VERSION
  }));

  app.get('/health/ready', async () => {
    await deps.check();
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: env.SERVICE_VERSION
    };
  });
}
