# 4. Solution Strategy

## Summary

The system is decomposed into five independently deployable containers managed by Docker Compose: a React/TypeScript frontend, an nginx reverse proxy (the single entry point), and three Python/FastAPI microservices, one per bounded context (Simulation, Command Parsing, Mission). Each microservice owns its in-memory state and exposes a REST API over the Docker Compose container network. Services communicate through synchronous REST over HTTP/JSON only; no message broker or event bus is used. The domain core of each service has no dependency on FastAPI, keeping it fully unit-testable in isolation.

## Mapping of Quality Goals to Approaches

| Quality Goal | Approach |
|-------------|----------|
| **Correctness** | Domain logic (plateau, rover, command execution, collision detection) is implemented as pure Python value objects, covered by unit tests written before the production code (TDD). No business rules live in HTTP handlers. |
| **Usability** | A React SPA renders a live grid that updates after every command. Step-by-step replay is driven client-side from the full step history returned by the Mission Service. |
| **Testability** | Each service's domain core has zero framework dependencies and is exercised with plain `pytest`. FastAPI handlers are covered by integration tests using the built-in `TestClient`. React components are covered by unit tests using Vitest and React Testing Library. See ADR-007. |
| **Simplicity** | A single `docker compose up` starts the whole system. In-memory state removes any database setup. No auth layer, no message broker, no cloud services. |
| **Extensibility** | The domain model uses a command-dispatch pattern: each command letter maps to a handler function. Adding a new command type requires only a new handler with no changes to the dispatcher or the HTTP layer. |

## Key Technology Decisions

Each decision is backed by an ADR in Chapter 9.

| Decision | Choice | ADR |
|----------|--------|-----|
| Backend language and runtime | Python 3.12+ | ADR-001 |
| Backend web framework | FastAPI | ADR-002 |
| Frontend language and framework | React with TypeScript | ADR-003 |
| Local orchestration | Docker Compose | ADR-004 |
| State management | In-process memory (Python dict) per service | ADR-005 |
| API style | REST over HTTP/JSON | ADR-006 |
| Testing strategy | pytest, FastAPI TestClient, Vitest, React Testing Library | ADR-007 |
| Architectural style | Microservices, one per bounded context | ADR-008 |
| Inter-service communication | Synchronous REST only; no message broker | ADR-009 |

## Architectural Patterns

| Pattern | Where applied |
|---------|--------------|
| **Microservices** | The backend is decomposed into three independently deployable services: **Simulation Service** (plateau grid, rover state, boundary enforcement), **Command Service** (translating raw command strings into domain operations), and **Mission Service** (orchestrating a full mission, tracking step history, holding session state). Each runs in its own container with its own process and in-memory store. |
| **Reverse proxy as single entry point** | An nginx container routes all inbound requests from the frontend to the correct backend service, shielding the frontend from individual service addresses. |
| **Layered architecture with inward dependencies** | Inside each service: Interface layer (HTTP handlers) depends on the Application layer, which depends on the Domain layer. The Domain layer has no outward dependencies. |
| **Domain-Driven Design** | Bounded contexts drive service boundaries. Each context has its own model, ubiquitous language and data store. Chapter 5 details each context. |
| **Single-page application** | Frontend: React SPA fetches data via the reverse proxy; no server-side rendering. |
| **Command pattern** | Domain: `L`, `R`, `M` letters are dispatched to individual command handlers within the Command Service. |
| **In-memory repository** | Application layer of Mission Service: a process-scoped dictionary holds the single active session (plateau + rovers + history). |
