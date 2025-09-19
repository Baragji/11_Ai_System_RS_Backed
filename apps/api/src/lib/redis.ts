import { Redis, type RedisOptions } from 'ioredis';
import { env } from '../config/env.js';

const isTest = env.NODE_ENV === 'test';

const redisOptions: RedisOptions = {
  host: env.REDIS_ENDPOINT,
  port: 6379,
  password: env.REDIS_PASSWORD,
  tls: {
    rejectUnauthorized: true,
    ca: Buffer.from(env.REDIS_TLS_CA, 'base64')
  },
  // Prevent eager network connections during tests to avoid hanging the test runner
  lazyConnect: isTest,
  maxRetriesPerRequest: isTest ? 0 : 3,
  enableAutoPipelining: true
};

export const redisClient = new Redis(redisOptions);

redisClient.on('error', (error: Error) => {
  console.error('Redis connection error', error);
});

export async function verifyRedis(): Promise<void> {
  if (isTest) {
    // In test mode, skip active health checks to avoid external dependencies
    return;
  }
  const status = await redisClient.ping();
  if (status !== 'PONG') {
    throw new Error('Redis health check failed');
  }
}
