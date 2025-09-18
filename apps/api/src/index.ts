import { buildServer } from './server.js';
import { env } from './config/env.js';
import { startTelemetry, shutdownTelemetry } from './observability/otel.js';

async function main(): Promise<void> {
  await startTelemetry();

  const server = buildServer();

  const close = async () => {
    await server.close();
    await shutdownTelemetry();
    process.exit(0);
  };

  process.on('SIGTERM', close);
  process.on('SIGINT', close);

  try {
    await server.listen({
      port: Number(env.PORT),
      host: '0.0.0.0'
    });
    server.log.info({ port: env.PORT }, 'Server listening');
  } catch (error) {
    server.log.error({ err: error }, 'Failed to start server');
    await close();
  }
}

void main();
