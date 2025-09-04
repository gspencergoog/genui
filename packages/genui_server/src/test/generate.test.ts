import { generateUiFlow } from "../generate";
// import { startSessionFlow } from "../session";
// import { v4 as uuidv4 } from "uuid";
import { FakeCacheService } from "./fake-cache-service";

jest.mock("uuid", () => ({
  v4: jest.fn(),
}));

describe("generateUiFlow", () => {
  it("should throw an error for an invalid session ID", async () => {
    const fakeCache = new FakeCacheService();

    await expect(async () => {
      const result = generateUiFlow.stream(
        {
          sessionId: "invalid-session-id",
          conversation: [],
        },
        { context: { cache: fakeCache } }
      );
      for await (const _chunk of result.stream) {
        // This should not be reached.
      }
    }).rejects.toThrow("Invalid session ID");
  });

  // Causes "module already loaded" deep in genkit.

  // it("should generate UI", async () => {
  //   const mockSessionId = "mock-session-id";
  //   (uuidv4 as jest.Mock).mockReturnValue(mockSessionId);

  //   const catalog = {
  //     schema: {
  //       properties: [
  //         {
  //           name: "testWidget",
  //           dataSchema: {
  //             type: "object",
  //             properties: {
  //               text: {
  //                 type: "string",
  //               },
  //             },
  //           },
  //         },
  //       ],
  //     },
  //   };

  //   const fakeCache = new FakeCacheService();
  //   await startSessionFlow.run(
  //     {
  //       protocolVersion: "0.1.0",
  //       catalog,
  //     },
  //     { context: { cache: fakeCache } }
  //   );

  //   const conversation = [
  //     {
  //       role: "user",
  //       content: [{ text: "Hello" }],
  //     },
  //   ];
  //   const result = await generateUiFlow.run(
  //     {
  //       sessionId: mockSessionId,
  //       conversation,
  //     },
  //     { context: { cache: fakeCache } }
  //   );

  //   expect(result).toBeDefined();
  // });
});
