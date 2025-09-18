import { diag, DiagConsoleLogger, DiagLogLevel } from '@opentelemetry/api';
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-grpc';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-grpc';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { env } from '../config/env.js';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.ERROR);

function parseHeaders(headerList?: string): Record<string, string> | undefined {
  if (!headerList) {
    return undefined;
  }

  const entries = headerList.split(',').map((header: string) => {
    const [key, value] = header.split('=');
    return [key.trim(), value.trim()] as const;
  });
  return Object.fromEntries(entries);
}

const traceExporter = new OTLPTraceExporter({
  url: env.OTEL_EXPORTER_OTLP_ENDPOINT,
  headers: parseHeaders(env.OTEL_EXPORTER_OTLP_HEADERS)
});

const metricReader = new PeriodicExportingMetricReader({
  exporter: new OTLPMetricExporter({
    url: env.OTEL_EXPORTER_OTLP_ENDPOINT,
    headers: parseHeaders(env.OTEL_EXPORTER_OTLP_HEADERS)
  }),
  exportIntervalMillis: 60000,
  exportTimeoutMillis: 30000
});

export const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: env.OTEL_SERVICE_NAME,
    [SemanticResourceAttributes.SERVICE_VERSION]: env.SERVICE_VERSION,
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: env.NODE_ENV
  }),
  traceExporter,
  metricReader,
  instrumentations: [getNodeAutoInstrumentations()]
} as unknown as ConstructorParameters<typeof NodeSDK>[0]);

export async function startTelemetry(): Promise<void> {
  await sdk.start();
}

export async function shutdownTelemetry(): Promise<void> {
  await sdk.shutdown();
}
