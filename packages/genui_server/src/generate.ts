// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { ai, z } from './genkit';
import { generateUiRequestSchema } from './schemas';
import { googleAI } from '@genkit-ai/googleai';
import { sessionCache } from './cache';

export const generateUiFlow = ai.defineFlow(
  {
    name: 'generateUi',
    inputSchema: generateUiRequestSchema,
    outputSchema: z.any(),
  },
  async function* (request) {
    const catalog = sessionCache.get(request.sessionId);
    if (!catalog) {
      throw new Error('Invalid session ID');
    }

    const addOrUpdateSurfaceTool = ai.defineTool(
      {
        name: 'addOrUpdateSurface',
        description: 'Add or update a UI surface.',
        inputSchema: z.object({
          surfaceId: z.string(),
          definition: z.any(),
        }),
        outputSchema: z.void(),
      },
      async (input) => {}
    );

    const deleteSurfaceTool = ai.defineTool(
      {
        name: 'deleteSurface',
        description: 'Delete a UI surface.',
        inputSchema: z.object({
          surfaceId: z.string(),
        }),
        outputSchema: z.void(),
      },
      async (input) => {}
    );

    const { stream, response } = ai.generateStream({
      model: googleAI.model('gemini-pro'),
      prompt: request.conversation as any,
      tools: [addOrUpdateSurfaceTool, deleteSurfaceTool],
      config: {
        temperature: 0.3,
      },
    });

    for await (const chunk of stream) {
      if (chunk.toolRequests) {
        yield {
          type: 'toolRequest',
          toolRequests: chunk.toolRequests,
        };
      }
    }
  }
);
