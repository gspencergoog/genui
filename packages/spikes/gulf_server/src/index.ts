import { startFlowServer } from "@genkit-ai/express";
import { gulfFlow } from "./flow";

startFlowServer({
  flows: [gulfFlow],
});
