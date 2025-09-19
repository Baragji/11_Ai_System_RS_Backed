import { Kafka, logLevel } from 'kafkajs';
import { env } from '../config/env.js';

const brokers = env.KAFKA_BROKERS.split(',').map((broker: string) => broker.trim());
const isTest = env.NODE_ENV === 'test';

export const kafka = new Kafka({
  clientId: 'platform-api',
  brokers,
  ssl: true,
  sasl: {
    mechanism: 'scram-sha-512',
    username: env.KAFKA_USERNAME,
    password: env.KAFKA_PASSWORD
  },
  connectionTimeout: 5000,
  requestTimeout: 10000,
  logLevel: logLevel.WARN
});

export async function verifyKafka(): Promise<void> {
  if (isTest) {
    // Skip external Kafka connectivity checks during tests
    return;
  }
  const admin = kafka.admin();
  await admin.connect();
  try {
    await admin.listTopics();
  } finally {
    await admin.disconnect();
  }
}
