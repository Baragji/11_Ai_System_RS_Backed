import 'fastify';
import type { AuthContext } from '../lib/oidc.js';

declare module 'fastify' {
  interface FastifyRequest {
    auth: AuthContext | null;
  }
}
