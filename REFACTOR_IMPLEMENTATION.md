# Refactor Implementation Plan

This document outlines the phased implementation plan for refactoring the `flutter_genui` package into a client-server architecture.

## Journal

- **Phase 1**: Completed the initial project scaffolding. Created the `genui_server` and `genui_client` packages. The basic project structure is now in place for the client-server split.
- **Phase 2**: Migrated core UI rendering logic from `flutter_genui` to `genui_client`. Refactored `GenUiManager` to be client-focused and created a stub for `GenUIClient`.
- **Phase 3**: Implemented the `genui_server` with Genkit. The server now has flows for starting a session and generating UI, exposed as HTTP endpoints. Corrected Genkit usage patterns after studying documentation examples.

## Phase 1: Project Scaffolding and Setup

- [x] **Create `genui_server` package directory.**
  - Create a new directory `packages/genui_server`.
- [x] **Create `genui_client` Flutter package.**
  - Create a new empty Flutter package in `packages/genui_client`.
- [x] Create a detailed design document for the genui_server in `packages/genui_server/IMPLEMENTATION.md`.
- [x] Create a detailed design document for the genui_client in `packages/genui_client/IMPLEMENTATION.md`.
- [x] Get approval for the two design docs before continuing.
- [x] **Initialize a new TypeScript project with pnpm.**
  - Run `pnpm init` inside `packages/genui_server`.
- [x] **Initialize a new Genkit project.**
  - Follow the Genkit documentation to initialize a new project within the `packages/genui_server` directory. This will include setting up the Gemini plugin.
- [x] **Create `genui_client` Flutter package.**
  - Create a new Flutter package in `packages/genui_client`.

### Verification and Commit (End of Phase 1)

- [x] If the phase includes Dart, run the `dart_fix` and `dart_format` tools to clean up the code.
- [x] If the phase includes Dart, run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] If the phase includes Dart, run `dart_format` one more time to make sure that the formatting is still correct if you made any changes during the analysis and testing steps.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to me for approval.
- [x] Update the REFACTOR_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until I approve the commit.

---

## Phase 2: Migrating Core Logic to `genui_client`

- [x] **Copy UI Rendering Logic.**
- [x] **Refactor `GenUiManager`.**
- [x] **Create `GenUIClient` Stub.**

### Verification and Commit (End of Phase 2)

- [x] If the phase includes Dart, run the `dart_fix` and `dart_format` tools to clean up the code.
- [x] If the phase includes Dart, run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] If the phase includes Dart, run `dart_format` one more time to make sure that the formatting is still correct if you made any changes during the analysis and testing steps.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to me for approval.
- [x] Update the REFACTOR_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until I approve the commit.

---

## Phase 3: Implementing the `genui_server`

- [x] **Define Zod Schemas.**
- [x] **Implement `startSession` Flow.**
- [x] **Implement `generateUI` Streaming Flow.**
- [x] **Expose Flows as HTTP Endpoints.**

### Verification and Commit (End of Phase 3)

- [x] If the phase includes Dart, run the `dart_fix` and `dart_format` tools to clean up the code.
- [x] If the phase includes Dart, run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] If the phase includes Dart, run `dart_format` one more time to make sure that the formatting is still correct if you made any changes during the analysis and testing steps.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to me for approval.
- [x] Update the REFACTOR_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until I approve the commit.

---

## Phase 4: Connecting Client-Server and Finalizing

- [x] **Implement `GenUIClient` in `genui_client`.**
  - Fully implement the `GenUIClient` to make real HTTP calls to the `genui_server` endpoints for both `startSession` and `generateUI`.
  - The `generateUI` method should handle the streaming response.
- [x] **Migrate the examples/minimal_genui example to `genui_client`.**
  - [x] **Copy `minimal_genui` example.**
    - Copy the contents of `examples/minimal_genui` to a new `packages/genui_client/example` directory.
  - [x] **Update new example's dependencies.**
    - Modify the `pubspec.yaml` in `packages/genui_client/example` to use a path dependency on the `genui_client` package.
- [x] **Update `genui_client/example` to Use the New Architecture.**
  - In the new `minimal_genui` example, update `main.dart` to:
    - Instantiate the `GenUIClient`.
    - Call `startSession` during initialization.
    - Replace direct AI calls with calls to `generateUI` on the `GenUIClient` and handle the stream of UI updates.
    - Use the `GenUiManager` to apply the received UI definitions to the `SurfaceManager`.

### Verification and Commit (End of Phase 4)

- [x] If the phase includes Dart, run the `dart_fix` and `dart_format` tools to clean up the code.
- [x] If the phase includes Dart, run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] If the phase includes Dart, run `dart_format` one more time to make sure that the formatting is still correct if you made any changes during the analysis and testing steps.
- [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to me for approval.
- [x] Update the REFACTOR_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section.
- [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until I approve the commit.
