
import { startSessionFlow } from '../session';
import { v4 as uuidv4 } from 'uuid';

jest.mock('uuid', () => ({
  v4: jest.fn(),
}));

describe('startSessionFlow', () => {
  it('should start a session and return a session ID', async () => {
    const mockSessionId = 'mock-session-id';
    (uuidv4 as jest.Mock).mockReturnValue(mockSessionId);

    const catalog = { version: '1.0' };
    const session = await startSessionFlow.run({
      protocolVersion: '0.1.0',
      catalog,
    });

    expect(session.result).toBe(mockSessionId);
  });
});
