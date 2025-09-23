import { z } from './genkit';

// A schema for a JSON schema. It was recursive, but that causes issues with zod-to-json-schema.
// We've replaced the recursive parts with z.any() to break the recursion.
export const jsonSchema: z.ZodType = z.lazy(() =>
  z
    .object({
      description: z.string().optional(),
      type: z.string().optional(),
      properties: z.record(z.any()).optional(),
      required: z.array(z.string()).optional(),
      items: z.any().optional(),
      anyOf: z.array(z.any()).optional(),
      allOf: z.array(z.any()).optional(),
      oneOf: z.array(z.any()).optional(),
      enum: z.array(z.any()).optional(),
    })
    .catchall(z.any()),
);
