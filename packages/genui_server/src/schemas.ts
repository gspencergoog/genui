import { z } from './genkit';

export const startSessionRequestSchema = z.object({
  protocolVersion: z.string(),
  catalog: z.any(),
});

export const generateUiRequestSchema = z.object({
  sessionId: z.string(),
  conversation: z.array(z.any()),
});
