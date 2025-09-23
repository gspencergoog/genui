# Refactor Implementation Plan: `genui_server` to GULF Protocol

This document outlines the detailed, phased plan for refactoring the `genui_server` to use the GULF protocol, following the approved tool-based, incremental streaming design.

## Journal

*This section will be updated after each phase to track progress, learnings, and any deviations from the plan.*

-   **Current Status:** Phase 1 is complete. Awaiting approval for the commit before proceeding to Phase 2.

## Phased Implementation

### Phase 1: Project Scaffolding and Setup

This phase focuses on creating a new, isolated environment for the GULF server implementation without modifying the existing code.

-   [x] Create a new directory `packages/spikes/gulf_server`.
-   [x] Copy the essential configuration files from `packages/spikes/genui_server` to `packages/spikes/gulf_server`:
    -   `package.json`
    -   `tsconfig.json`
    -   `pnpm-lock.yaml`
-   [x] Create the source directory `packages/spikes/gulf_server/src`.
-   [x] Create an initial `packages/spikes/gulf_server/src/index.ts` to define and export the flow (it will be a placeholder for now).
-   [x] Create a `packages/spikes/gulf_server/src/genkit.ts` and `logger.ts` by copying them from the old server.
-   [x] Run `pnpm install` within the new `packages/spikes/gulf_server` directory to ensure dependencies are set up correctly.

#### Post-Phase 1 Actions

-   [x] Run `git diff` to verify the changes that have been made.
-   [x] Present the following commit message for approval: `feat(server): scaffold new gulf_server package for GULF protocol implementation`.
-   [x] Update the "Journal" section in this document.
-   [ ] Wait for approval before committing the changes or moving on.

### Phase 2: GULF Schema and Tool Definitions

This phase involves creating strongly-typed Zod schemas based on the `gulf_schema.json` and defining the new Genkit tools that the LLM will use.

-   [ ] Create a new file: `packages/spikes/gulf_server/src/gulf_schemas.ts`.
-   [ ] In this file, define Zod schemas for the GULF components and tool inputs, referencing `gulf_schema.json` as the source of truth.
    -   `gulfComponentSchema`
    -   `componentUpdateToolSchema`
    -   `dataModelUpdateToolSchema`
    -   `beginRenderingToolSchema`
-   [ ] Create a new file: `packages/spikes/gulf_server/src/tools.ts`.
-   [ ] In this file, define the new Genkit tools using `ai.defineTool`:
    -   `componentUpdateTool`
    -   `dataModelUpdateTool`
    -   `beginRenderingTool`
-   [ ] The implementation of these tools will be simple placeholders for now (e.g., they can just log their input). The flow will handle the actual logic.

#### Post-Phase 2 Actions

-   [ ] Run the project's TypeScript linter/formatter to clean up the code.
-   [ ] Run `pnpm tsc --noEmit` to check for any compilation errors.
-   [ ] Run `git diff` to verify the changes that have been made.
-   [ ] Present the following commit message for approval: `feat(server): define Zod schemas and Genkit tools for GULF protocol`.
-   [ ] Update the "Journal" section in this document.
-   [ ] Wait for approval before committing the changes or moving on.

### Phase 3: Core Flow and System Prompt

This phase implements the main `gulfFlow` and the critical system prompt that will guide the LLM to use the new tools correctly.

-   [ ] Create a new file: `packages/spikes/gulf_server/src/flow.ts`.
-   [ ] Define the new `gulfFlow` using `ai.defineFlow`.
-   [ ] Implement the new system prompt as a function that takes the client `catalog` schema and injects it. The prompt will instruct the LLM on how to build a UI incrementally using the new tools.
-   [ ] Implement the main body of the flow to call `ai.generateStream()` with the new system prompt, the conversation history, and the GULF tools.
-   [ ] Update `src/index.ts` to export and serve the `gulfFlow`.

#### Post-Phase 3 Actions

-   [ ] Run the project's TypeScript linter/formatter to clean up the code.
-   [ ] Run `pnpm tsc --noEmit` to check for any compilation errors.
-   [ ] Run `git diff` to verify the changes that have been made.
-   [ ] Present the following commit message for approval: `feat(server): implement core gulfFlow and system prompt for tool-based generation`.
-   [ ] Update the "Journal" section in this document.
-   [ ] Wait for approval before committing the changes or moving on.

### Phase 4: Tool Handling and Streaming Logic

This phase adds the logic to handle the tool calls from the LLM and serialize their output into the GULF JSONL stream.

-   [ ] In `packages/spikes/gulf_server/src/flow.ts`, add the streaming logic to the `gulfFlow`.
-   [ ] As `toolRequest` chunks are received from the `ai.generateStream()` call, inspect the tool name.
-   [ ] Based on the tool name, construct the appropriate GULF message object (e.g., `{ "componentUpdate": ... }`).
-   [ ] Serialize the object to a JSON string and use the `streamingCallback` to send it to the client.
-   [ ] Immediately send a `toolResponse` back to the LLM so it can continue its work.

#### Post-Phase 4 Actions

-   [ ] Run the project's TypeScript linter/formatter to clean up the code.
-   [ ] Run `pnpm tsc --noEmit` to check for any compilation errors.
-   [ ] Run `git diff` to verify the changes that have been made.
-   [ ] Present the following commit message for approval: `feat(server): implement GULF JSONL streaming from tool requests`.
-   [ ] Update the "Journal" section in this document.
-   [ ] Wait for approval before committing the changes or moving on.

### Phase 5: Testing and Finalization

This phase focuses on ensuring the new implementation is working correctly and replacing the old server.

-   [ ] Create a test file `packages/spikes/gulf_server/src/test/flow.test.ts`.
-   [ ] Write a unit test for the `gulfFlow` that mocks the `ai.generateStream` call and verifies that the flow produces a valid, well-ordered JSONL stream in response to mock tool requests.
-   [ ] Manually test the flow using the Genkit developer UI to ensure it works end-to-end.
-   [ ] Delete the now-obsolete `packages/spikes/genui_server` directory.
-   [ ] Rename `packages/spikes/gulf_server` to `packages/spikes/genui_server`.

#### Post-Phase 5 Actions

-   [ ] Run the project's TypeScript linter/formatter to clean up the code.
-   [ ] Run `pnpm tsc --noEmit` and `pnpm test` to ensure all checks pass.
-   [ ] Run `git diff` to verify the changes that have been made.
-   [ ] Present the following commit message for approval: `feat(server): add tests for gulfFlow and replace old server implementation`.
-   [ ] Update the "Journal" section in this document.
-   [ ] Wait for approval before committing the changes or moving on.

### Phase 6: Documentation Update

The final phase is to update the project's documentation to reflect the new architecture.

-   [ ] Update the `packages/spikes/genui_server/IMPLEMENTATION.md` file.
-   [ ] Replace the existing content with a description of the new GULF-based, tool-calling architecture.
-   [ ] Include the new Mermaid sequence diagram from the approved design document.
-   [ ] Ensure the documentation accurately reflects the final state of the code.

#### Post-Phase 6 Actions

-   [ ] Run `git diff` to verify the changes that have been made.
-   [ ] Present the following commit message for approval: `docs(server): update IMPLEMENTATION.md to reflect new GULF architecture`.
-   [ ] Update the "Journal" section in this document.
-   [ ] Wait for approval.
