import { config as loadEnv } from 'dotenv';
import { z } from 'zod';

loadEnv();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.string().default('8080'),
  POSTGRES_HOST: z.string(),
  POSTGRES_PORT: z.string().default('5432'),
  POSTGRES_DB: z.string(),
  POSTGRES_USER: z.string(),
  POSTGRES_PASSWORD: z.string(),
  POSTGRES_SSL: z.enum(['require', 'disable']).default('require'),
  REDIS_ENDPOINT: z.string(),
  REDIS_PASSWORD: z.string(),
  REDIS_TLS_CA: z.string(),
  KAFKA_BROKERS: z.string(),
  KAFKA_USERNAME: z.string(),
  KAFKA_PASSWORD: z.string(),
  OTEL_EXPORTER_OTLP_ENDPOINT: z.string(),
  OTEL_EXPORTER_OTLP_HEADERS: z.string().optional(),
  OTEL_SERVICE_NAME: z.string().default('platform-api'),
  OIDC_ISSUER: z.string(),
  OIDC_AUDIENCE: z.string(),
  OIDC_JWKS_URI: z.string(),
  SERVICE_VERSION: z.string().default('1.0.0')
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  throw new Error(`Environment validation failed: ${parsed.error.message}`);
}

export const env = parsed.data;
