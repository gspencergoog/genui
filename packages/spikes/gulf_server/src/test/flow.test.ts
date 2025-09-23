import { Genkit } from 'genkit';
import { createGulfFlow } from '../flow';

jest.mock('../logger', () => ({
  logger: {
    info: jest.fn(),
    debug: jest.fn(),
    error: jest.fn(),
  },
}));

describe('gulfFlow', () => {
  const mockGenerateStream = jest.fn();
  const fakeAi = {
    defineFlow: jest.fn((_, implementation) => implementation),
    generateStream: mockGenerateStream,
  };

  // Create a testable instance of the flow using the fake AI object
  const gulfFlow = createGulfFlow(fakeAi as unknown as Genkit);

  beforeEach(() => {
    mockGenerateStream.mockClear();
  });

  it('should not throw an error on a simple run', async () => {
    const mockStream = (async function* () {
      yield { text: 'response part' };
    })();

    mockGenerateStream.mockReturnValue({
      stream: mockStream,
      response: Promise.resolve({ text: 'final response' }),
    });

    const request = {
      catalog: { type: 'object' },
      conversation: [],
    };
    await expect(gulfFlow(request, () => {})).resolves.not.toThrow();
  });

  it('should handle tool requests and stream them as GULF messages', async () => {
    const mockToolRequest = {
      name: 'componentUpdate',
      input: { components: [{ id: 'test', componentProperties: {} }] },
      confirm: jest.fn(),
    };

    const mockStream = (async function* () {
      yield { toolRequests: [mockToolRequest] };
    })();

    mockGenerateStream.mockReturnValue({
      stream: mockStream,
      response: Promise.resolve({}),
    });

    const request = {
      catalog: { type: 'object' },
      conversation: [],
    };

    const streamingCallback = jest.fn();

    await gulfFlow(request, streamingCallback);

    expect(streamingCallback).toHaveBeenCalledWith({
      content:
        JSON.stringify({ componentUpdate: mockToolRequest.input }) + '\n',
    });
    expect(mockToolRequest.confirm).toHaveBeenCalledWith({ status: 'ok' });
  });

  it('should stream the final text response', async () => {
    const mockStream = (async function* () {})(); // Empty stream

    mockGenerateStream.mockReturnValue({
      stream: mockStream,
      response: Promise.resolve({ text: 'This is the final text.' }),
    });

    const request = {
      catalog: { type: 'object' },
      conversation: [],
    };

    const streamingCallback = jest.fn();

    await gulfFlow(request, streamingCallback);

    expect(streamingCallback).toHaveBeenCalledWith({
      text: 'This is the final text.',
    });
  });

  it('should throw an error if AI generation fails', async () => {
    const testError = new Error('AI failed');
    mockGenerateStream.mockImplementation(() => {
      throw testError;
    });

    const request = {
      catalog: { type: 'object' },
      conversation: [],
    };

    await expect(gulfFlow(request, () => {})).rejects.toThrow(testError);
  });
});