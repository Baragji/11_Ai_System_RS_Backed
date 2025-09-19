import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

export const taskSchema = z.object({
  taskId: z.string().uuid(),
  agent: z.enum(['planner', 'coder', 'critic']),
  payload: z.record(z.string(), z.any()),
  priority: z.number().int().min(0).max(10).default(5)
});

export type TaskPayload = z.infer<typeof taskSchema>;

interface TaskDependencies {
  enqueueTask: (payload: TaskPayload) => Promise<void>;
}

export function registerTaskRoutes(app: FastifyInstance, deps: TaskDependencies): void {
  app.post('/tasks', {
    schema: {
      body: {
        type: 'object',
        required: ['taskId', 'agent', 'payload'],
        properties: {
          taskId: { type: 'string', format: 'uuid' },
          agent: { type: 'string', enum: ['planner', 'coder', 'critic'] },
          payload: { type: 'object' },
          priority: { type: 'integer', minimum: 0, maximum: 10, default: 5 }
        }
      }
    }
  }, async (request, reply) => {
    const body = taskSchema.parse(request.body);
    await deps.enqueueTask(body);
    return reply.status(202).send({ accepted: true });
  });
}
