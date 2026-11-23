# 8. Cross-cutting Concepts

## 8.1 Authentication and Authorisation

The system is local-only with no user accounts, tokens, or access control (constraint from Chapter 2). No authentication or authorisation layer is implemented. All requests arriving at the API Gateway are accepted without any identity check.

If the system were ever exposed beyond localhost, an authentication layer (e.g. HTTP Basic or a token header) would need to be added at the API Gateway before any service processes a request.

---

## 8.2 Input Validation

Validation is applied at two levels and must never be duplicated into the domain core.

| Level | Where | What is validated |
|-------|-------|-------------------|
| **Schema validation** | FastAPI / Pydantic, in the API Router of each service | Required fields present, correct types, value ranges (e.g. plateau coordinates > 0, heading is one of N/E/S/W, command string contains only printable characters) |
| **Domain validation** | Domain layer of each service | Business rules (e.g. no two rovers on the same initial cell, command characters must be L/R/M) |

Schema errors return `422 Unprocessable Entity` with a Pydantic error body. Domain errors (e.g. `UnknownCommandError`, overlapping initial placements) are caught by the API Router and mapped to `422` or `409 Conflict` with a structured JSON error body:

```json
{
  "error": "UNKNOWN_COMMAND",
  "detail": "Unrecognised character 'X' at position 2"
}
```

The Frontend displays the `detail` string to the player rather than a generic failure message.

---

## 8.3 Error Handling

### Backend services

Each FastAPI service registers a global exception handler that catches domain exceptions and maps them to HTTP responses. No stack traces are exposed to callers.

| Exception | HTTP status | Error code in body |
|-----------|------------|-------------------|
| `UnknownCommandError` | 422 | `UNKNOWN_COMMAND` |
| `OverlappingRoversError` | 422 | `OVERLAPPING_ROVERS` |
| `SessionNotFoundError` | 404 | `SESSION_NOT_FOUND` |
| Unhandled exception | 500 | `INTERNAL_ERROR` |

### Inter-service calls (Mission Service HTTP Client)

The Mission Service calls Command Service and Simulation Service via `httpx`. Network errors and non-2xx responses are caught by the HTTP Client component and re-raised as typed domain exceptions, which the Mission Service's API Router then maps to HTTP responses. This keeps error-handling logic out of the application layer.

| Situation | HTTP Client raises | Mission API Router returns |
|-----------|-------------------|---------------------------|
| Connection refused / timeout | `ServiceUnavailableError` | 503 Service Unavailable |
| Non-2xx from downstream service | `DownstreamError(status, body)` | 502 Bad Gateway |

### Frontend

The API Client wraps every `fetch` call. On a non-2xx response it reads the JSON error body and surfaces the `detail` field in the UI. Network errors (no connection) show a generic "Cannot reach server" message. No raw HTTP status codes or stack traces are shown to the player.

---

## 8.4 Logging and Monitoring

The system is a local kata with no production observability requirements. The following minimal logging policy applies:

| Service | What is logged | Where |
|---------|---------------|-------|
| All FastAPI services | Incoming request method and path, response status, latency (via uvicorn access log) | stdout, visible via `docker compose logs` |
| Mission Service | Session created/reset; command string received; each step result (operation, rover index, rejection if any) | stdout at `INFO` level using Python `logging` |
| nginx gateway | Access log (method, path, upstream, status) | stdout |

Log level is controlled by an environment variable `LOG_LEVEL` (default `INFO`). No log aggregation, tracing, or metrics are set up for this kata.

---

## 8.5 Configuration

Each service is configured entirely through environment variables, with defaults suitable for local development. No secrets are involved (no auth, no database passwords).

| Variable | Service | Default | Description |
|----------|---------|---------|-------------|
| `LOG_LEVEL` | All backend services | `INFO` | Python logging level |
| `COMMAND_SERVICE_URL` | Mission Service | `http://command:8001` | Base URL of the Command Service |
| `SIMULATION_SERVICE_URL` | Mission Service | `http://simulation:8002` | Base URL of the Simulation Service |
| `UVICORN_HOST` | All backend services | `0.0.0.0` | Bind address inside the container |
| `UVICORN_PORT` | Mission / Command / Simulation | `8000` / `8001` / `8002` | Listening port inside the container |

Environment variables are set in `docker-compose.yml`. No `.env` secrets file is required.

---

## 8.6 Testing Strategy

Each service is tested independently. Tests are written before the production code they cover (TDD).

| Layer | Tool | Scope |
|-------|------|-------|
| Domain unit tests | `pytest` | Pure Python domain logic (rover movement, command parsing, collision detection); no HTTP, no I/O |
| Service integration tests | `pytest` + FastAPI `TestClient` | API Router to domain, in-process; no real HTTP server started |
| Inter-service contract tests | `pytest` + `httpx` against a live container | Mission Service calling real Command and Simulation containers; run via `docker compose -f docker-compose.test.yml` |
| Frontend unit tests | Vitest + React Testing Library | Individual React components in isolation |
| Frontend integration tests | Vitest + mock API Client | App component with mocked HTTP responses |

The domain layer of each service must be testable with `pytest` alone (no Docker, no FastAPI, no network). This is enforced by the inward-dependency rule: the Domain layer has no dependency on FastAPI, `httpx`, or any infrastructure component.

---

## 8.7 Domain Model Conventions

These conventions apply uniformly across all three services and are enforced by the inward-dependency rule.

| Convention | Rule |
|------------|------|
| **Immutability** | All domain value objects (`Plateau`, `Position`, `Rover`, `Heading`, `Operation`, `CommandRejection`, `Step`) are immutable Python dataclasses with `frozen=True`. Mutation is never performed in-place; a new object is returned. |
| **No framework imports in the domain** | Domain modules must not import `fastapi`, `pydantic`, `httpx`, or any other infrastructure library. Pydantic schemas used for HTTP I/O live in the Interface layer only. |
| **Explicit error types** | Every domain error condition is a named exception class (e.g. `UnknownCommandError`, `OverlappingRoversError`). Generic `ValueError` or `Exception` are not raised from the domain. |
| **No shared code between services** | Each service has its own copy of any type it needs (e.g. `Operation` and `Rover` are defined in the Simulation Service; the Mission Service uses the HTTP contract, not shared Python types). This preserves independent deployability. |
