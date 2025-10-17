// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    // Placeholder implementation
    eventBus.finished();
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
const appBuilder = new A2AExpressApp(requestHandler);
export const a2aApp = appBuilder.setupRoutes(express());
