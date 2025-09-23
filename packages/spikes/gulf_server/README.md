# GULF Server

This server is a Genkit-based implementation that serves UIs conforming to the GULF (Generative UI Language Format) Protocol.

## Prerequisites

-   Node.js
-   pnpm

## Setup

1.  Install the dependencies:
    ```bash
    pnpm install
    ```

## Environment Variables

This server uses the Google AI provider. You must set the `GEMINI_API_KEY` environment variable to your Google AI key.

```bash
export GEMINI_API_KEY="YOUR_API_KEY"
```

## Running the Server

To run the server in development mode with live reloading, use the following command:

```bash
pnpm run genkit:dev
```

This will start the Genkit developer UI and the flow server. The output in your terminal will show the URL for the flow server, which is typically `http://localhost:3400`.

## Connecting a Client

To connect a GULF client, send a `POST` request to the `gulfFlow` endpoint.

-   **URL:** `http://localhost:3400/gulfFlow` (or the URL provided when you start the server)
-   **Method:** `POST`
-   **Headers:**
    -   `Content-Type: application/json`

The body of the request must be a JSON object containing the `catalog` (the client's widget capabilities as a JSON schema) and the `conversation` history.

### Example `curl` Command

Here is an example of how to connect to the server using `curl`. This example uses an empty catalog and a simple user request.

```bash
curl -X POST http://localhost:3400/gulfFlow \
-H "Content-Type: application/json" \
-d 
'{'
  "catalog": {
    "type": "object",
    "properties": {
      "Text": {
        "type": "object",
        "properties": {
          "text": {
            "type": "string"
          }
        },
        "required": ["text"]
      }
    }
  },
  "conversation": [
    {
      "role": "user",
      "parts": [
        {
          "text": "Show me a simple text widget."
        }
      ]
    }
  ]
}'
```

The server will respond with a Server-Sent Events (SSE) stream of JSONL messages representing the generated UI.

## Running Tests

To run the unit tests for the server, use the following command:

```bash
pnpm test
```