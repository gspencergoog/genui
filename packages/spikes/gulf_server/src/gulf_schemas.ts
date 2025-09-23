import { z } from './genkit';

// Base schema for a component, derived from gulf_schema.json
export const gulfComponentSchema = z.object({
  id: z.string().describe('A unique identifier for this component instance.'),
  weight: z
    .number()
    .optional()
    .describe(
      'The proportional weight of this component within its container (Row or Column).',
    ),
  componentProperties: z
    .object({})
    .describe(
      'Defines the component type and its properties. Exactly ONE key must be set.',
    ),
});

// Schema for the input of the componentUpdateTool
export const componentUpdateToolSchema = z.object({
  components: z
    .array(gulfComponentSchema)
    .describe(
      'A list of one or more component definitions to add or update.',
    ),
});

// Schema for the input of the dataModelUpdateTool
export const dataModelUpdateToolSchema = z.object({
  path: z
    .string()
    .optional()
    .describe(
      'A dot-separated path to the location in the data model to update. If omitted, the entire data model is replaced.',
    ),
  contents: z.any().describe('The JSON content to place at the specified path.'),
});

// Schema for the input of the beginRenderingTool
export const beginRenderingToolSchema = z.object({
  root: z
    .string()
    .describe(
      'The ID of the root component from which rendering should begin.',
    ),
});
