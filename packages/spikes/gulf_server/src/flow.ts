import { ai, z } from "./genkit";
import {
  componentUpdateTool,
  dataModelUpdateTool,
  beginRenderingTool,
} from './tools';
import { logger } from "./logger";
import { Message, Part } from "@genkit-ai/ai";
import { jsonSchema } from './schemas';

const gulfRequestSchema = z.object({
  catalog: jsonSchema,
  conversation: z.array(
    z.object({
      role: z.enum(['user', 'model']),
      parts: z.array(z.any()), // Simplified for now
    }),
  ),
});

function createSystemPrompt(catalogSchemaString: string): string {
  return `
You are an expert UI generation agent. Your goal is to generate a UI based on the user's request by incrementally calling tools to emit messages that conform to the GULF (Generative UI Language Format) Protocol.

You must build the UI piece by piece using the following tools:
- \`componentUpdate\`: Use this to define one or more UI components. Components are defined in a flat list and reference each other by ID.
- \`dataModelUpdate\`: Use this to set or update the UI's state.
- \`beginRendering\`: You MUST call this tool once, and only once, after all initial components and data have been defined.

When you use the \`componentUpdate\` tool, the \`componentProperties\` for each component you provide MUST be a JSON object that strictly conforms to the following JSON Schema:
\`\`\`json
${catalogSchemaString}
\`\`\`

When the user interacts with the UI, you will receive a message containing a JSON block with a GULF ClientEvent. Use the 'resolvedContext' to understand the user's action and decide on the next step.

First, define all the components. Then, provide the data. Finally, call beginRendering.
`.trim();
}

export const gulfFlow = ai.defineFlow(
  {
    name: "gulfFlow",
    inputSchema: gulfRequestSchema,
    outputSchema: z.unknown(),
  },
  async (request, streamingCallback) => {
    const catalog = request.catalog;
    if (!catalog) {
      logger.error(`No catalog provided in the request.`);
      throw new Error("No catalog provided in the request.");
    }
    logger.debug("Successfully retrieved catalog from request.");

    const catalogSchemaString = JSON.stringify(catalog, null, 2);
    const systemPrompt = createSystemPrompt(catalogSchemaString);

    // Transform conversation to Genkit's format
    const genkitConversation: Message[] = request.conversation.map(
      (message) => {
        const content: Part[] = message.parts.map((part: any) => {
          if (part.text) {
            return { text: part.text };
          }
          // Handle GULF ClientEvent
          if (part.gulfEvent) {
            return {
              text: `The user triggered the '${
                part.gulfEvent.actionName
              }' action with the following context: ${JSON.stringify(
                part.gulfEvent.resolvedContext,
                null,
                2,
              )}`,
            };
          }
          return { text: '' }; // Should not happen
        });

        return new Message({
          role: message.role,
          content,
        });
      },
    );

    try {
      logger.debug(
        genkitConversation,
        "Starting AI generation for conversation",
      );
      const { stream, response } = ai.generateStream({
        model: 'gemini-1.5-pro-latest',
        system: systemPrompt,
        messages: genkitConversation,
        tools: [componentUpdateTool, dataModelUpdateTool, beginRenderingTool],
      });

      for await (const chunk of stream) {
        if (chunk.toolRequests) {
          for (const toolRequest of chunk.toolRequests) {
            logger.info({ toolRequest }, 'Received tool request from AI.');
            let gulfMessage = {};
            switch (toolRequest.toolRequest.name) {
              case 'componentUpdate':
                gulfMessage = { componentUpdate: toolRequest.toolRequest.input };
                break;
              case 'dataModelUpdate':
                gulfMessage = { dataModelUpdate: toolRequest.toolRequest.input };
                break;
              case 'beginRendering':
                gulfMessage = { beginRendering: toolRequest.toolRequest.input };
                break;
            }
            const jsonl = JSON.stringify(gulfMessage);
            // streamingCallback({ content: jsonl + '\n' });
            // toolRequest.confirm({ status: 'ok' });
          }
        }
      }

      const finalResponse = await response;
      if (finalResponse.text) {
        logger.info("Yielding final text response from AI.");
        streamingCallback({ text: finalResponse.text });
      }

      return finalResponse;
    } catch (error) {
      logger.error(error, "An error occurred during AI generation");
      throw error;
    }
  },
);
