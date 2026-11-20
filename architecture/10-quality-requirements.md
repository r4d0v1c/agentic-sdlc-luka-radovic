# 10. Quality Requirements

## 10.1 Quality Requirements Overview

The five quality goals from Chapter 1, ordered by priority, with the architectural approach and the measurable threshold for each:

| Priority | Quality Goal | Architectural Approach | Measurable Threshold |
|----------|-------------|----------------------|----------------------|
| 1 | **Correctness** | Pure domain value objects; TDD; no business rules in HTTP handlers | All kata examples produce the specified output; domain unit test suite passes with 0 failures; collision and OOB rules enforced on every move |
| 2 | **Usability** | React SPA with live grid; step-by-step replay driven from local history; structured error messages surfaced to the player | Player can complete a full session (configure, command, replay) without reading documentation; error messages identify the invalid input by field and reason |
| 3 | **Testability** | Domain layer has zero framework dependencies; each service tested in isolation; TDD discipline enforced | Domain layer covered by unit tests runnable with `pytest` alone (no Docker, no network); API layer covered by in-process integration tests; overall line coverage >= 80% per service |
| 4 | **Simplicity** | In-memory state; Docker Compose one-command startup; no auth, no broker, no cloud | System starts with `docker compose up --build` in under 2 minutes on a developer machine with a warm Docker cache; no manual configuration steps required |
| 5 | **Extensibility** | Command-dispatch pattern; inward-dependency rule; no shared types between services | Adding a new command type (e.g. `B` for reverse) requires changes only to the Command Service domain and the Simulation Service domain; no changes to Mission Service, gateway, or frontend API Client |

---

## 10.2 Quality Scenarios

### QS-01: Correctness: Kata example produces exact output

| Attribute | Value |
|-----------|-------|
| **Quality goal** | Correctness |
| **Stimulus** | Player submits the two rovers from the kata: Rover 1 at `1 2 N` with commands `LMLMLMLMM`; Rover 2 at `3 3 E` with commands `MMRMMRMRRM`; plateau `5 5` |
| **Response** | System returns Rover 1 at `1 3 N` and Rover 2 at `5 1 E` |
| **Measure** | Output matches the kata specification exactly; verified by a domain unit test and an API integration test |

---

### QS-02: Correctness: Collision is detected and recorded

| Attribute | Value |
|-----------|-------|
| **Quality goal** | Correctness |
| **Stimulus** | Rover 0 is at `2 2 N`; Rover 1 is at `2 3 N`; player submits command `M` for Rover 0 |
| **Response** | Rover 0 stays at `2 2 N`; the step is recorded with `rejection: "COLLISION"`; HTTP 200 is returned |
| **Measure** | Rover position in the response is unchanged; `new_steps[0].rejection` equals `"COLLISION"`; verified by a domain unit test and an API integration test |

---

### QS-03: Correctness: Out-of-bounds is detected and recorded

| Attribute | Value |
|-----------|-------|
| **Quality goal** | Correctness |
| **Stimulus** | Plateau is `5 5`; Rover 0 is at `0 0 S`; player submits command `M` |
| **Response** | Rover 0 stays at `0 0 S`; the step is recorded with `rejection: "OUT_OF_BOUNDS"`; HTTP 200 is returned |
| **Measure** | Rover position in the response is unchanged; `new_steps[0].rejection` equals `"OUT_OF_BOUNDS"`; verified by a domain unit test and an API integration test |

---

### QS-04: Testability: Domain tests run without infrastructure

| Attribute | Value |
|-----------|-------|
| **Quality goal** | Testability |
| **Stimulus** | Developer runs `pytest services/simulation/tests/unit/` on a machine with Python 3.12 and no Docker daemon running |
| **Response** | All domain unit tests pass |
| **Measure** | Test suite completes in under 5 seconds; zero imports of `fastapi`, `httpx`, or `docker` in the domain test modules |

---

### QS-05: Simplicity: One-command startup

| Attribute | Value |
|-----------|-------|
| **Quality goal** | Simplicity |
| **Stimulus** | Developer clones the repository on a machine with Docker Compose installed and runs `docker compose up --build` |
| **Response** | All five containers start; the UI is reachable at `http://localhost:3000`; the API is reachable at `http://localhost:8080/api/v1/` |
| **Measure** | Full startup completes in under 2 minutes on a machine with a warm Docker layer cache; no manual steps (no database migration, no seed script, no config file editing) are required |

---

### QS-06: Extensibility: New command type requires localised changes

| Attribute | Value |
|-----------|-------|
| **Quality goal** | Extensibility |
| **Stimulus** | A new command character `B` (move backward) is to be added |
| **Response** | Developer adds `MOVE_BACKWARD` to the `Operation` enum in the Simulation Service, implements the movement rule in the Simulation domain, and adds `B -> MOVE_BACKWARD` to the Command Service parser |
| **Measure** | No files outside `services/simulation/` and `services/command/` are modified; Mission Service, API Gateway configuration, and Frontend API Client require no changes |

---

### QS-07: Usability: Invalid command string produces a clear error

| Attribute | Value |
|-----------|-------|
| **Quality goal** | Usability |
| **Stimulus** | Player submits command string `"LMX"` containing an unrecognised character |
| **Response** | The Frontend displays an error message identifying the invalid character and its position |
| **Measure** | HTTP 422 is returned with `{ "error": "UNKNOWN_COMMAND", "detail": "Unrecognised character 'X' at position 2" }`; the Frontend renders the `detail` string; the session state is unchanged |
