import { z } from "./genkit";

export const startSessionRequestSchema = z.object({
  protocolVersion: z.string(),
  catalog: z.any(),
});

// Based on Genkit's Part type. This schema ensures that each part of a message
// has the correct structure.
const partSchema = z
  .object({
    text: z.string().optional(),
    media: z
      .object({
        url: z.string(),
        contentType: z.string().optional(),
      })
      .optional(),
    data: z.unknown().optional(),
    toolRequest: z
      .object({
        name: z.string(),
        input: z.unknown(),
      })
      .optional(),
  })
  .refine(
    (data) => !!data.text || !!data.media || !!data.data || !!data.toolRequest,
    "A Part object must have one of 'text', 'media', 'data', or 'toolRequest'."
  );

// This defines the valid structure for a message in the conversation.
const messageSchema = z.object({
  role: z.enum(["user", "model", "system", "tool"]),
  content: z.array(partSchema),
});

export const generateUiRequestSchema = z.object({
  sessionId: z.string(),
  // By using a strict messageSchema, we can validate the conversation structure.
  conversation: z.array(messageSchema),
});