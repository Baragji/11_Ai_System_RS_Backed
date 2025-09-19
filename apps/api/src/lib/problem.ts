import type { FastifyError, FastifyReply, FastifyRequest } from 'fastify';

interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  detail?: string;
  instance: string;
  errors?: unknown;
}

export function buildProblemDetails(error: FastifyError, request: FastifyRequest): ProblemDetails {
  const statusCode = error.statusCode ?? 500;
  return {
    type: error.validation ? 'https://datatracker.ietf.org/doc/html/rfc9457#section-3.2' : 'about:blank',
    title: error.message,
    status: statusCode,
    detail: error.validation ? 'Request validation failed' : error.message,
    instance: request.url,
    errors: error.validation
  };
}

export function problemErrorHandler(error: FastifyError, request: FastifyRequest, reply: FastifyReply): void {
  const body = buildProblemDetails(error, request);
  void reply
    .status(body.status)
    .type('application/problem+json')
    .send(body);
}

export function withErrorHandling<
  Request extends FastifyRequest = FastifyRequest,
  Reply extends FastifyReply = FastifyReply,
  Result = unknown
>(handler: (request: Request, reply: Reply) => Promise<Result>): (request: Request, reply: Reply) => Promise<Result> {
  return async (request, reply) => {
    try {
      return await handler(request, reply);
    } catch (error) {
      request.log.error({ err: error }, 'Route handler threw an error');
      if (error instanceof Error) {
        throw error;
      }
      const wrapped = new Error('Unknown error occurred');
      (wrapped as Partial<FastifyError>).statusCode = 500;
      throw wrapped;
    }
  };
}
