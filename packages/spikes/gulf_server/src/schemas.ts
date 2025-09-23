import { z } from './genkit';

// A schema for a JSON schema. It's recursive.
export const jsonSchema: z.ZodType = z.lazy(() =>
  z
    .object({
      description: z.string().optional(),
      type: z.string().optional(),
      properties: z.record(z.union([jsonSchema, z.boolean()])).optional(),
      required: z.array(z.string()).optional(),
      items: z.union([jsonSchema, z.boolean()]).optional(),
      anyOf: z.array(z.union([jsonSchema, z.boolean()])).optional(),
      allOf: z.array(z.union([jsonSchema, z.boolean()])).optional(),
      oneOf: z.array(z.union([jsonSchema, z.boolean()])).optional(),
      enum: z
        .array(z.union([z.string(), z.number(), z.boolean(), z.null()]))
        .optional(),
    })
    .catchall(z.any()),
);
