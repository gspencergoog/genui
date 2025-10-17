import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import {
  AgentCard,
  Message,
  DataPart,
} from '@a2a-js/sdk';
import {
  AgentExecutor,
  RequestContext,
  ExecutionEventBus,
  DefaultRequestHandler,
  InMemoryTaskStore,
} from '@a2a-js/sdk/server';
import { A2AExpressApp } from '@a2a-js/sdk/server/express';
import { generateUiFlow } from './generate';
import { GenerateUiRequest } from './schemas';

// 1. Define the Agent Card
const a2uiAgentCard: AgentCard = {
  name: 'A2UI Genkit Server',
  description: 'An agent that generates UIs using the A2UI protocol.',
  protocolVersion: '0.3.0',
  version: '1.0.0',
  url: 'http://localhost:10002/', // This needs to be publicly accessible in production
  skills: [
    {
      id: 'a2ui-chat',
      name: 'A2UI Chat',
      description: 'Generates a UI based on a chat conversation.',
      tags: ['chat'],
    },
  ],
  capabilities: {
    streaming: true,
  },
  defaultInputModes: ['text/plain'],
  defaultOutputModes: ['text/plain'],
};

// 2. Implement the AgentExecutor
class A2UIAgentExecutor implements AgentExecutor {
  async execute(
    requestContext: RequestContext,
    eventBus: ExecutionEventBus
  ): Promise<void> {
    const { userMessage: message, taskId, contextId } = requestContext;

    // Extract the text prompt from the incoming message
    const userPrompt = message.parts
      .filter((part: any) => part.kind === 'text')
      .map((part: any) => (part as any).text)
      .join('\n');

    if (!userPrompt) {
      eventBus.finished();
      return;
    }

    // TODO: We need to adapt the `generateUiFlow` to accept a simpler input
    // and to handle conversation history. For now, we'll just pass the prompt.
    const flowRequest: GenerateUiRequest = {
      // This needs to be adapted based on how we manage the catalog.
      // For now, we'll assume a static or default catalog.
      catalog: { type: 'object', properties: {} },
      conversation: [
        {
          role: 'user',
          parts: [{ type: 'text', text: userPrompt }],
        },
      ],
    };

    try {
      // Call the Genkit flow and get the stream
      const { stream } = generateUiFlow.stream(flowRequest);

      // Process the stream from the Genkit flow
      for await (const chunk of stream) {
        // Wrap the A2UI message in an A2A DataPart
        const dataPart: DataPart = {
          kind: 'data',
          data: { a2uiMessages: [chunk] },
        };

        // Publish the data part on the event bus
        eventBus.publish({
          kind: 'message',
          messageId: uuidv4(),
          role: 'agent',
          parts: [dataPart],
          contextId: contextId,
          referenceTaskIds: [taskId],
        });
      }
    } catch (error) {
      console.error('Error executing Genkit flow:', error);
      // Optionally publish an error message back to the client
    } finally {
      // Signal that the task is finished
      eventBus.finished();
    }
  }

  async cancelTask(taskId: string, eventBus: ExecutionEventBus): Promise<void> {
    console.log(`Cancellation requested for task: ${taskId}`);
    eventBus.finished();
  }
}

// 3. Set up the A2A Express App
const agentExecutor = new A2UIAgentExecutor();
const requestHandler = new DefaultRequestHandler(
  a2uiAgentCard,
  new InMemoryTaskStore(),
  agentExecutor
);
export const appBuilder = new A2AExpressApp(requestHandler);
