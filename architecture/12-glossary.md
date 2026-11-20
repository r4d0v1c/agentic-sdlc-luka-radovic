# 12. Glossary

## Business Terms

| Term | Definition |
|------|-----------|
| **Plateau** | A rectangular grid on the Martian surface defined by its upper-right coordinates `(width, height)`; the lower-left corner is always `(0, 0)`. |
| **Rover** | An autonomous vehicle placed on the plateau at a given position and heading. Each rover is identified by its index in the session's rover list. |
| **Position** | A cell on the plateau identified by integer coordinates `(x, y)`. `x` increases eastward; `y` increases northward. |
| **Heading** | The cardinal direction a rover faces: `N` (north), `E` (east), `S` (south), or `W` (west). |
| **Command string** | A sequence of characters submitted by the player for one rover: `L` turns the rover 90° left, `R` turns it 90° right, `M` moves it one step forward in the current heading. |
| **Operation** | The domain representation of a single decoded command character: `TURN_LEFT`, `TURN_RIGHT`, or `MOVE_FORWARD`. Defined in the Simulation bounded context. |
| **Session** | The active runtime state: plateau dimensions, initial rover placements (snapshot at creation), current rover states, and full step history. Only one session exists at a time. |
| **Step** | One recorded attempt to apply an `Operation` to a rover. Carries the rover index, the operation, the resulting position and heading, and the rejection reason (or `null` if the move succeeded). |
| **Collision** | A rejected move where the target cell is already occupied by another rover. The moving rover stays in place; the step is recorded with `rejection: "COLLISION"`. |
| **Out of bounds** | A rejected move where the target cell falls outside the plateau boundary. The moving rover stays in place; the step is recorded with `rejection: "OUT_OF_BOUNDS"`. |
| **Replay** | The player-facing feature that steps through the full history one move at a time, showing the grid state at each step, including rejected moves. |

---

## Technical Terms

| Term | Definition |
|------|-----------|
| **Bounded context** | A DDD concept: a subsystem with its own domain model, ubiquitous language, and data store. This system has three: Simulation, Command Parsing, and Mission. |
| **Microservice** | An independently deployable service that owns one bounded context, runs in its own container, and communicates with other services only over HTTP/JSON. |
| **API Gateway** | The nginx container that is the single externally reachable entry point. It routes inbound requests to the correct backend microservice and is the only container with a published host port for the API. |
| **Mission Service** | The stateful orchestrator microservice. It holds the session, calls Command Service and Simulation Service for each operation, and records every step (including rejected moves) in the history. |
| **Command Service** | The stateless microservice that parses a raw command string into an ordered list of `Operation` values. Raises `UnknownCommandError` for unrecognised characters. |
| **Simulation Service** | The stateless microservice that applies a single `Operation` to a `Rover` given `Plateau` dimensions and a set of occupied positions. Returns the new `Rover` state or a `CommandRejection`. |
| **SessionRepository** | A Python ABC (port) in the Mission Service that defines `load()` and `save()` for the active session. `InMemorySessionRepository` is the only current adapter. |
| **Value object** | A DDD concept: an immutable object with no identity of its own, defined entirely by its attributes. All domain types in this system (`Plateau`, `Position`, `Rover`, `Heading`, `Operation`, `Step`, `CommandRejection`) are value objects implemented as `frozen=True` Python dataclasses. |
| **Aggregate root** | A DDD concept: the entry point for a cluster of related objects. `Session` is the only aggregate root; it is loaded and saved as a unit by `SessionRepository`. |
| **Port / Adapter** | A hexagonal architecture pattern. A port is an interface (Python ABC) that the application layer depends on; an adapter is the concrete implementation. `SessionRepository` is the port; `InMemorySessionRepository` is the adapter. |
| **Inward-dependency rule** | The architectural constraint that dependencies inside each service flow only inward: Interface layer depends on Application layer, Application layer depends on Domain layer, Domain layer depends on nothing outside itself. |
| **TDD** | Test-Driven Development: tests are written before the production code they cover. Red (failing test) then Green (minimal code to pass) then Refactor. |
| **Docker Compose** | The tool used to define and run the five-container system. A single `docker compose up --build` starts all containers and connects them on a shared bridge network. |
| **uvicorn** | The ASGI server used to run each FastAPI microservice inside its Docker container. |
| **httpx** | The async-capable Python HTTP client used by the Mission Service's HTTP Client component to call Command Service and Simulation Service. |
| **Vitest** | The Vite-native JavaScript test runner used for all frontend tests. |
| **React Testing Library** | A frontend testing utility that queries components by accessible roles and labels rather than implementation details. |
