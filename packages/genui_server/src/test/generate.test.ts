import { generateUiFlow } from "../generate";
import { startSessionFlow } from "../session";
import { v4 as uuidv4 } from "uuid";
import { sessionCache } from "../cache";

jest.mock("uuid", () => ({
  v4: jest.fn(),
}));

describe("generateUiFlow", () => {
  beforeEach(() => {
    sessionCache.clear();
  });

  it("should throw an error for an invalid session ID", async () => {
    await expect(async () => {
      const stream = generateUiFlow.stream({
        sessionId: "invalid-session-id",
        conversation: [],
      });
      for await (const chunk of await stream.output) {
        // This should not be reached.
      }
    }).rejects.toThrow("Invalid session ID");
  });

  it("should generate UI", async () => {
    const mockSessionId = "mock-session-id";
    (uuidv4 as jest.Mock).mockReturnValue(mockSessionId);

    const catalog = {
      schema: {
        properties: [
          {
            name: "testWidget",
            dataSchema: {
              type: "object",
              properties: {
                text: {
                  type: "string",
                },
              },
            },
          },
        ],
      },
    };
    await startSessionFlow.run({
      protocolVersion: "0.1.0",
      catalog,
    });

    const conversation = [
      {
        role: "user",
        content: [{ text: "Hello" }],
      },
    ];
    const result = await generateUiFlow.run({
      sessionId: mockSessionId,
      conversation,
    });

    expect(result).toBeDefined();
  });
});
