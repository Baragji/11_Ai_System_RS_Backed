import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';
import { env } from '../config/env.js';

const jwks = createRemoteJWKSet(new URL(env.OIDC_JWKS_URI));

export interface AuthContext {
  subject: string;
  scope?: string;
  claims: JWTPayload;
}

export async function verifyAccessToken(token: string): Promise<AuthContext> {
  const { payload } = await jwtVerify(token, jwks, {
    issuer: env.OIDC_ISSUER,
    audience: env.OIDC_AUDIENCE
  });

  return {
    subject: payload.sub ?? 'anonymous',
    scope: typeof payload.scope === 'string' ? payload.scope : undefined,
    claims: payload
  };
}
