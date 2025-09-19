import { Pool } from 'pg';
import { env } from '../config/env.js';
const sslConfig = env.POSTGRES_SSL === 'require'
  ? {
      rejectUnauthorized: true
    }
  : undefined;

export const postgresPool = new Pool({
  host: env.POSTGRES_HOST,
  port: Number(env.POSTGRES_PORT),
  database: env.POSTGRES_DB,
  user: env.POSTGRES_USER,
  password: env.POSTGRES_PASSWORD,
  ssl: sslConfig,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  statement_timeout: 15000,
  query_timeout: 15000
});

export async function verifyPostgres(): Promise<void> {
  const client = await postgresPool.connect();
  try {
    await client.query('SELECT 1');
  } finally {
    client.release();
  }
}

export function getPool(): Pool {
  return postgresPool;
}
