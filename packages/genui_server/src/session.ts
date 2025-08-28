import { v4 as uuidv4 } from 'uuid';
import { ai, z } from './genkit';
import { startSessionRequestSchema } from './schemas';
import { sessionCache } from './cache';

export const startSessionFlow = ai.defineFlow(
  {
    name: 'startSession',
    inputSchema: startSessionRequestSchema,
    outputSchema: z.string(),
  },
  async (request) => {
    const sessionId = uuidv4();
    console.log(`Starting session ${sessionId}`);
    sessionCache.set(sessionId, request.catalog);
    return sessionId;
  }
);
