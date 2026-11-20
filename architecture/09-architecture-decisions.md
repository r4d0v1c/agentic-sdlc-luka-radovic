# 9. Architecture Decisions

## ADR-001: Python 3.12+ as the backend language

**Status:** Accepted

**Context:**
The kata requires a backend that implements domain rules (rover movement, collision detection, command parsing). The developer is working in an academic TDD context where readability, fast test cycles, and a clean domain model matter more than raw throughput.

**Decision:**
Use Python 3.12+ for all three backend microservices.

**Rationale:**
- Python's standard library and dataclass support make immutable value objects concise and readable, which directly serves the Testability and Correctness quality goals.
- `pytest` provides a first-class unit testing experience with minimal boilerplate, supporting the TDD constraint.
- Python 3.12 improves error messages and performance over earlier versions; `frozen=True` dataclasses enforce immutability at the language level.
- Alternatives considered: Java/Spring Boot (verbose for a kata, slower TDD cycle), Node.js/TypeScript (acceptable, but sharing a language with the frontend adds accidental coupling pressure), Go (less expressive domain modelling for DDD value objects).

**Consequences:**
- All three backend services share the same language and can reuse tooling (pytest, uvicorn, Dockerfile base image).
- The GIL is not a concern given the single-user, local-only scope.
- Python type hints require discipline; mypy should be run in CI to catch type errors early.

---

## ADR-002: FastAPI as the backend web framework

**Status:** Accepted

**Context:**
Each backend microservice needs an HTTP layer that validates request bodies, serialises responses, and maps domain errors to HTTP status codes. The domain core must remain framework-independent.

**Decision:**
Use FastAPI with Pydantic v2 for all three backend microservices.

**Rationale:**
- FastAPI generates OpenAPI documentation automatically, which helps the developer and reviewer verify the API contract without running the UI.
- Pydantic v2 provides schema validation at the boundary, keeping validation logic out of the domain.
- The built-in `TestClient` (backed by `httpx`) allows integration tests to exercise the full request-response cycle in-process, without starting a real server, directly serving the Testability goal.
- FastAPI's dependency injection supports swapping the `InMemorySessionRepository` for a test double without modifying production code.
- Alternatives considered: Flask (no built-in validation or async support), Django REST Framework (too heavy for a kata), Starlette directly (FastAPI is Starlette with batteries).

**Consequences:**
- Pydantic schemas live in the Interface layer; domain types must not import Pydantic.
- uvicorn is used as the ASGI server inside each container.

---

## ADR-003: React with TypeScript as the frontend

**Status:** Accepted

**Context:**
The system requires a browser-based grid UI that renders rover positions, accepts player input, and drives step-by-step replay. The frontend is a single-page application with no server-side rendering requirement.

**Decision:**
Use React 18 with TypeScript and Vite as the build tool.

**Rationale:**
- React's component model maps naturally to the UI structure (App, Grid View, Plateau Form, Command Form, Replay Controls).
- TypeScript catches type mismatches between the API contract and the UI state at compile time, reducing runtime errors.
- Vite provides fast hot-module replacement during development and a small production bundle.
- React Testing Library + Vitest allow components to be tested in isolation, satisfying the Testability goal.
- Alternatives considered: Vue 3 (viable, but React is more widely known in the target context), plain HTML/JS (no component model, harder to test), Angular (too heavyweight for a kata).

**Consequences:**
- The compiled bundle is served by nginx inside the `frontend` container.
- The frontend communicates with the backend only through the API Gateway; it has no direct dependency on any microservice URL.

---

## ADR-004: Docker Compose for local orchestration

**Status:** Accepted

**Context:**
The system consists of five containers that must start together and discover each other by name. The constraint is that the whole system starts with a single command on a developer machine at no infrastructure cost.

**Decision:**
Use Docker Compose (v2) to orchestrate all five containers on the developer machine.

**Rationale:**
- Docker Compose is the standard tool for multi-container local development; it is available wherever Docker Desktop or Docker Engine is installed.
- Compose service names provide built-in DNS on the bridge network, removing any need for a service registry.
- A single `docker compose up --build` satisfies the Player stakeholder's expectation of a one-command startup.
- Alternatives considered: Kubernetes / kind (far too heavy for a local kata), bare Docker run scripts (fragile, no network management), Podman Compose (compatible but less common; Docker Compose is the safer default).

**Consequences:**
- All port bindings, environment variables, and network configuration live in `docker-compose.yml`.
- Each microservice must have its own `Dockerfile`.
- State is lost when containers are stopped, which is acceptable given the in-memory constraint.

---

## ADR-005: In-process memory as the only state store

**Status:** Accepted

**Context:**
The kata explicitly excludes persistence across process restarts. The Mission Service must hold plateau configuration, rover states, and step history for the lifetime of one session.

**Decision:**
Store all session state in a process-scoped Python dictionary inside the Mission Service (`InMemorySessionRepository`). Command Service and Simulation Service are stateless.

**Rationale:**
- No database setup, schema migration, or connection management is needed, directly serving the Simplicity goal.
- A Python dict behind a port (ABC) keeps the domain and application layers free of infrastructure dependencies; a persistent adapter could be substituted later without touching those layers.
- The single-user, local-only constraint means concurrent write conflicts are not a concern.
- Alternatives considered: SQLite (adds schema design and migration overhead for a kata), Redis (requires an additional container with no benefit at this scale), file-based JSON (adds serialisation complexity and file I/O error handling).

**Consequences:**
- All session state is lost when the Mission Service container is stopped or restarted; this is an accepted limitation per Chapter 2.
- Only one session is active at a time; the session has no ID in the URL path.

---

## ADR-006: REST over HTTP/JSON as the API style

**Status:** Accepted

**Context:**
The frontend needs to communicate with the backend, and the three microservices need to communicate with each other. A common, well-understood protocol is preferred for a kata.

**Decision:**
Use REST over HTTP/JSON for all interfaces: frontend-to-gateway, gateway-to-service, and service-to-service.

**Rationale:**
- REST over HTTP/JSON has no client library dependency; `fetch` in the browser and `httpx` in Python are sufficient.
- JSON payloads are human-readable, which aids debugging during development.
- FastAPI generates OpenAPI docs from the route definitions, giving a machine-readable contract for free.
- The request-response model is the simplest fit for a synchronous, single-user kata; there is no need for streaming or bidirectional communication.
- Alternatives considered: GraphQL (adds schema and resolver complexity with no benefit for a fixed set of operations), gRPC (binary protocol, requires Protobuf tooling, overkill for a local kata), WebSockets (only beneficial if the backend needs to push unsolicited updates, which it does not).

**Consequences:**
- API versioning is prefixed in the URL path (`/api/v1/`).
- All payloads are UTF-8 JSON; no binary encoding is used.

---

## ADR-007: pytest, FastAPI TestClient, Vitest, and React Testing Library as the testing stack

**Status:** Accepted

**Context:**
The TDD constraint requires tests to be written before production code. Tests must run fast, be independent of Docker, and cover domain logic, API handlers, and UI components separately.

**Decision:**
Use `pytest` for all Python tests, FastAPI's `TestClient` for in-process API integration tests, `httpx` for inter-service contract tests against live containers, Vitest for all frontend tests, and React Testing Library for component tests.

**Rationale:**
- `pytest` requires minimal boilerplate and integrates with the Python ecosystem (fixtures, parametrize, coverage via `pytest-cov`).
- FastAPI `TestClient` exercises the full handler-to-domain path in-process without a network, making API tests fast and deterministic.
- Vitest is Vite-native and runs in the same module system as the application code, eliminating configuration overhead.
- React Testing Library encourages tests that reflect user behaviour (querying by role and label) rather than implementation details.
- Alternatives considered: `unittest` (verbose compared to pytest), Jest (requires additional Babel/ts-jest configuration when using Vite; Vitest is the natural choice), Cypress/Playwright (end-to-end tests are valuable but out of scope for the kata's TDD layer).

**Consequences:**
- Each service has its own `tests/` directory and `pytest` configuration.
- The domain layer of each service must have zero framework dependencies so it can be tested with `pytest` alone.
- Frontend tests run with `vitest run`; they do not require a browser or Docker.

---

## ADR-008: Microservices as the architectural style, one service per bounded context

**Status:** Accepted

**Context:**
The domain contains three clearly separable bounded contexts: Simulation (rover state and movement rules), Command Parsing (translating raw strings into operations), and Mission (orchestrating a full mission and tracking history). An architectural style must be chosen that reflects these boundaries.

**Decision:**
Decompose the backend into three independently deployable microservices, one per bounded context, each running in its own Docker container with its own in-memory store and FastAPI process.

**Rationale:**
- Microservices enforce the bounded context boundaries at the deployment level, preventing accidental coupling that a modular monolith would only enforce by convention.
- Each service can be built, tested, and restarted independently, which supports the Testability and Extensibility goals.
- The kata is small enough that the operational overhead of three services is manageable with Docker Compose; the developer gains hands-on experience with microservice patterns proportionate to the academic context.
- The costs are acknowledged: three network hops per command execution (Mission to Command, Mission to Simulation per operation), partial-failure surface (Command or Simulation Service unreachable), and three Dockerfiles to maintain. These are acceptable trade-offs given the academic and learning objectives.
- Alternatives considered: modular monolith (bounded contexts as Python packages inside one process, simpler operationally, but boundaries are only enforced by convention and the architecture assignment requires microservices); serverless functions (prohibited by constraint).

**Consequences:**
- Each service has its own `Dockerfile`, `requirements.txt`, and test suite.
- No Python types are shared between services; the HTTP contract is the integration point.
- The Mission Service must handle downstream unavailability gracefully (503/502 responses, as defined in Chapter 8).

---

## ADR-009: Synchronous REST for inter-service communication; no message broker

**Status:** Accepted

**Context:**
The Mission Service must coordinate with the Command Service and the Simulation Service for every command submitted. A communication style must be chosen.

**Decision:**
Use synchronous HTTP/JSON calls (via `httpx`) for all inter-service communication. No message broker, event bus, or asynchronous messaging is introduced.

**Rationale:**
- Command parsing and move simulation are fast, in-memory operations; there is no latency reason to decouple them asynchronously.
- Synchronous REST keeps the execution flow easy to trace: a single POST to Mission Service produces a deterministic, immediately available response with the new rover states.
- The replay feature relies on a complete, ordered step history. Synchronous, sequential execution guarantees ordering without additional coordination.
- Introducing a message broker (e.g. RabbitMQ, Kafka) would add a sixth container, a new failure mode, eventual-consistency concerns for the step history, and significant operational complexity, none of which are justified for a single-user, local kata.
- Alternatives considered: async messaging via RabbitMQ or Redis Streams (rejected, adds complexity with no benefit at this scale); server-sent events from Mission to Frontend (rejected, the Frontend polls on demand, which is simpler and sufficient).

**Consequences:**
- If the Command Service or Simulation Service is unavailable, the Mission Service returns an error immediately (503/502); there is no retry queue or dead-letter handling.
- All inter-service calls are synchronous and blocking within the request-response cycle.
- Adding asynchronous behaviour in the future would require introducing a broker and reworking the Mission Service's execution loop, which is an accepted future cost.
