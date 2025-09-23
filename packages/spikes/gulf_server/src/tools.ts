import { ai, z } from './genkit';
import {
  componentUpdateToolSchema,
  dataModelUpdateToolSchema,
  beginRenderingToolSchema,
} from './gulf_schemas';
import { logger } from './logger';

export const componentUpdateTool = ai.defineTool(
  {
    name: 'componentUpdate',
    description:
      'Define one or more UI components. Components are defined in a flat list and reference each other by ID.',
    inputSchema: componentUpdateToolSchema,
    outputSchema: z.object({ status: z.string() }),
  },
  async (input) => {
    logger.info(
      `componentUpdateTool called with ${input.components.length} components.`,
    );
    return { status: 'ok' };
  },
);

export const dataModelUpdateTool = ai.defineTool(
  {
    name: 'dataModelUpdate',
    description:
      "Set or update the UI's state data model. You can replace the entire data model or update a specific path.",
    inputSchema: dataModelUpdateToolSchema,
    outputSchema: z.object({ status: z.string() }),
  },
  async (input) => {
    logger.info(`dataModelUpdateTool called for path: ${input.path || 'root'}`);
    return { status: 'ok' };
  },
);

export const beginRenderingTool = ai.defineTool(
  {
    name: 'beginRendering',
    description:
      'Signal that the client has all necessary components and data to perform the initial render.',
    inputSchema: beginRenderingToolSchema,
    outputSchema: z.object({ status: z.string() }),
  },
  async (input) => {
    logger.info(`beginRenderingTool called with root: ${input.root}`);
    return { status: 'ok' };
  },
);
