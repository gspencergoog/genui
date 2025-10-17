# Modification Implementation Plan: A2A Protocol Integration

This document outlines the phased implementation plan for refactoring the `a2ui_server` to use the A2A protocol.

## Journal

- **2025-10-17:** Initial plan created.

## Phase 1: Setup and Initial A2A Server

- [ ] Run all existing tests to ensure the project is in a good state before starting modifications.
- [ ] Install necessary dependencies: `a2a-js`, `express`, and `@types/express`.
- [ ] Create a new file `src/a2a.ts` to house the A2A server logic.
- [ ] In `src/a2a.ts`, define the `AgentCard` with the details provided.
- [ ] In `src/a2a.ts`, create a placeholder `A2UIAgentExecutor` class that implements the `AgentExecutor` interface but has empty `execute` and `cancelTask` methods for now.
- [ ] In `src/a2a.ts`, set up the `DefaultRequestHandler` and `A2AExpressApp`.
- [ ] Modify `src/index.ts` to import and run the `A2AExpressApp` instead of the Genkit flow server.
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run any relevant code formatters or linters to clean up the code.
- [ ] Run static analysis tools and fix any issues.
- [ ] Run all relevant tests to make sure they all pass.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, reload it if possible.

## Phase 2: Integrating Genkit Flow

- [ ] In `src/a2a.ts`, implement the `execute` method of the `A2UIAgentExecutor`.
- [ ] Inside the `execute` method, extract the user's prompt from the incoming A2A message.
- [ ] Call the `generateUiFlow.stream()` with the user's prompt and a default/static catalog.
- [ ] Iterate through the stream returned by the flow. For each chunk (which is an A2UI message), wrap it in an A2A `DataPart` and publish it to the `ExecutionEventBus`.
- [ ] Implement the `cancelTask` method to handle task cancellation.
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run any relevant code formatters or linters to clean up the code.
- [ ] Run static analysis tools and fix any issues.
- [ ] Run all relevant tests to make sure they all pass.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, reload it if possible.

## Phase 3: Finalization and Documentation

- [ ] Update the `README.md` file in `a2ui_server` to reflect the new A2A-based architecture, removing instructions about the old Genkit flow endpoint.
- [ ] Update any other project documentation (e.g., `IMPLEMENTATION.md`) so that it still correctly describes the app, its purpose, and implementation details.
- [ ] Ask the user to inspect the project (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.
- [ ] After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks so that you can come back and complete them later.
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run any relevant code formatters or linters to clean up the code.
- [ ] Run static analysis tools and fix any issues.
- [ ] Run all relevant tests to make sure they all pass.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, reload it if possible.
