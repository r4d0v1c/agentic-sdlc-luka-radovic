# Simulation User Stories

## SIMULATION-STORY-001: Rover Turns and Moves, Final Position Reported

**Priority**: Core (20%)
**Features**: F-3 (Command execution), F-5 (State reporting), F-6 (Visual grid)
**Architecture references**:
* Chapter 6.2 (06-runtime-view.md): Execute Commands, Happy Path, full walkthrough steps 1-8
* Chapter 5.1 (05-building-block-view.md): Simulation Service responsibility; `POST /api/v1/simulation/move` endpoint (internal, called by Mission Service); stateless
* Chapter 5.2 (05-building-block-view.md): Simulation Service components (API Router, Simulation domain); Mission Service components (Mission Service app, HTTP Client, InMemorySessionRepository); Frontend components (App, Grid View, API Client); `Step` value object; `Rover`, `Plateau`, `Operation`, `Heading`, `Position` domain types
* Chapter 1.1 (01-introduction-and-goals.md): Kata example, Rover 1 at `1 2 N` + `LMLMLMLMM` = `1 3 N`; Rover 2 at `3 3 E` + `MMRMMRMRRM` = `5 1 E`
* Chapter 8.3 (08-cross-cutting-concepts.md): `SessionNotFoundError` -> HTTP 404

AS A Player
I WANT to submit a command string for a rover and see its updated position and heading on the grid after each command is applied
SO THAT I can confirm the rover moved correctly and use the result as the starting point for further commands

---

### Scenarios

#### SCENARIO 1: Kata example - Rover 0 completes LMLMLMLMM from 1 2 N

**Scenario ID**: SIMULATION-STORY-001-S1

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `1 2 N`, Rover 1 at `3 3 E`
* The player has entered command string `LMLMLMLMM` for Rover 0

**WHEN**
* The player submits the Command Form for Rover 0 with command string `LMLMLMLMM`

**THEN**
* Assumption: The Mission Service responds HTTP 200 with Rover 0 at `1 3 N` and 9 new `Step` records (Chapter 6.2 step 7 confirms updated states and new steps are returned; response field names and status code are not specified by the architecture)
* The Grid View renders Rover 0 at cell `(1,3)` facing `N` (kata specification, Chapter 1.1)

---

#### SCENARIO 2: Kata example - Rover 1 completes MMRMMRMRRM from 3 3 E

**Scenario ID**: SIMULATION-STORY-001-S2

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `1 2 N`, Rover 1 at `3 3 E`
* The player has entered command string `MMRMMRMRRM` for Rover 1

**WHEN**
* The player submits the Command Form for Rover 1 with command string `MMRMMRMRRM`

**THEN**
* Assumption: The Mission Service responds HTTP 200 with Rover 1 at `5 1 E` and 10 new `Step` records
* The Grid View renders Rover 1 at cell `(5,1)` facing `E` (kata specification, Chapter 1.1)

---

#### SCENARIO 3: Single MOVE_FORWARD increments y-coordinate when heading is N

**Scenario ID**: SIMULATION-STORY-001-S3

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `2 2 N`

**WHEN**
* The player submits the Command Form for Rover 0 with command string `M`

**THEN**
* Assumption: The Mission Service responds HTTP 200 with Rover 0 at `2 3 N` and 1 new `Step` with `rejection: null`
* The Grid View renders Rover 0 at cell `(2,3)` facing `N`

---

#### SCENARIO 4: TURN_LEFT rotates heading counter-clockwise

**Scenario ID**: SIMULATION-STORY-001-S4

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `2 2 N`

**WHEN**
* The player submits the Command Form for Rover 0 with command string `L`

**THEN**
* Assumption: The Mission Service responds HTTP 200 with Rover 0 at `2 2 W` and 1 new `Step` with `rejection: null`
* The Grid View renders Rover 0 at cell `(2,2)` facing `W`

---

#### SCENARIO 5: TURN_RIGHT rotates heading clockwise

**Scenario ID**: SIMULATION-STORY-001-S5

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `2 2 N`

**WHEN**
* The player submits the Command Form for Rover 0 with command string `R`

**THEN**
* Assumption: The Mission Service responds HTTP 200 with Rover 0 at `2 2 E` and 1 new `Step` with `rejection: null`
* The Grid View renders Rover 0 at cell `(2,2)` facing `E`

---

### Frontend Stories

#### SIMULATION-FE-001.1: Grid View re-renders with updated rover positions after command submission

**Parent**: SIMULATION-STORY-001
**Component**: Grid View, App (05-building-block-view.md, Chapter 5.2)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): Grid View is purely presentational; App manages rover states and passes them as props; `App -> Grid View` renders with current rover states; API Client receives updated states from `POST /api/v1/session/commands`
* Chapter 6.2 (06-runtime-view.md): Execute Commands, Happy Path, step 8 (Frontend appends new steps to local history and re-renders the grid)

AS A Player
I WANT the grid to update and show the rover at its new position and heading after I submit a command string
SO THAT I can see where the rover ended up without any additional action

##### SCENARIO 1: Grid View shows Rover 0 at final position after kata example commands

**Scenario ID**: SIMULATION-FE-001.1-S1

**GIVEN**
* App state contains plateau `5 5`, Rover 0 at `1 2 N`, Rover 1 at `3 3 E`
* Assumption: The API Client returns a successful response with Rover 0 updated to `1 3 N` and 9 new `Step` records after `POST /api/v1/session/commands`

**WHEN**
* App updates its rover state from the API response and passes the new state to Grid View

**THEN**
* Grid View renders Rover 0 at cell `(1,3)` facing `N`
* Rover 1 icon remains at `(3,3)` facing `E` (unchanged, only Rover 0 was commanded)
* No error message is displayed

##### SCENARIO 2: Grid View shows updated heading after a turn command

**Scenario ID**: SIMULATION-FE-001.1-S2

**GIVEN**
* App state contains plateau `5 5`, Rover 0 at `2 2 N`
* Assumption: The API Client returns a successful response with Rover 0 updated to `2 2 W` after command `L`

**WHEN**
* App updates its rover state and passes it to Grid View

**THEN**
* Grid View renders Rover 0 at cell `(2,2)` facing `W`

---

### Backend Stories

#### SIMULATION-BE-001.1: Simulation Service applies a single Operation to a Rover

**Parent**: SIMULATION-STORY-001
**Service**: Simulation Service (`simulation:8002`)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): Simulation Service components (API Router, Simulation domain); `POST /api/v1/simulation/move`; inputs are `Rover`, `Operation`, `Plateau`, `frozenset[Position]` of occupied positions excluding the moving rover; returns new immutable `Rover` or `CommandRejection`
* Chapter 5, Key Domain Types (05-building-block-view.md): `Rover`, `Plateau`, `Position`, `Heading`, `Operation` value objects and enums
* Chapter 6.2 (06-runtime-view.md): Execute Commands, Happy Path, steps 5-6 (Mission Service calls `POST /api/v1/simulation/move` per operation; Simulation Service returns new `Rover` state with `rejection: null`)
* Chapter 8.2 (08-cross-cutting-concepts.md): Schema validation at the API Router

AS A Developer
I WANT the Simulation Service `POST /api/v1/simulation/move` endpoint to apply one `Operation` to a `Rover` on a `Plateau` with a given set of occupied positions and return the new immutable `Rover` state
SO THAT the Mission Service can call it once per operation in a loop and collect the resulting states for recording and reporting

##### SCENARIO 1: MOVE_FORWARD from 1 2 N moves rover to 1 3 N

**Scenario ID**: SIMULATION-BE-001.1-S1

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 1, "y": 2, "heading": "N" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }` (field names are not specified by the architecture; `Operation` values `MOVE_FORWARD`, `TURN_LEFT`, `TURN_RIGHT` are defined in Chapter 5, Key Domain Types (05-building-block-view.md))

**WHEN**
* `POST /api/v1/simulation/move` is called on the Simulation Service

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 1, "y": 3, "heading": "N" }, "rejection": null }` (field names and envelope are not specified by the architecture)

##### SCENARIO 2: TURN_LEFT from N rotates rover to face W, position unchanged

**Scenario ID**: SIMULATION-BE-001.1-S2

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 2, "y": 2, "heading": "N" }, "operation": "TURN_LEFT", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 2, "y": 2, "heading": "W" }, "rejection": null }`

##### SCENARIO 3: TURN_RIGHT from N rotates rover to face E, position unchanged

**Scenario ID**: SIMULATION-BE-001.1-S3

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 2, "y": 2, "heading": "N" }, "operation": "TURN_RIGHT", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 2, "y": 2, "heading": "E" }, "rejection": null }`

##### SCENARIO 4: Full heading cycle - four TURN_LEFT calls return rover to original heading

**Scenario ID**: SIMULATION-BE-001.1-S4

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 0, "y": 0, "heading": "N" }, "operation": "TURN_LEFT", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }` called four times in sequence, each time using the heading returned by the previous call

**WHEN**
* `POST /api/v1/simulation/move` is called four times

**THEN**
* After 4 calls the rover heading is `N` again: N -> W -> S -> E -> N
* Position `(0,0)` is unchanged throughout

##### SCENARIO 5: MOVE_FORWARD heading N increments y by 1

**Scenario ID**: SIMULATION-BE-001.1-S5

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 2, "y": 2, "heading": "N" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 2, "y": 3, "heading": "N" }, "rejection": null }`

##### SCENARIO 6: MOVE_FORWARD heading E increments x by 1

**Scenario ID**: SIMULATION-BE-001.1-S6

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 2, "y": 2, "heading": "E" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 3, "y": 2, "heading": "E" }, "rejection": null }`

##### SCENARIO 7: MOVE_FORWARD heading S decrements y by 1

**Scenario ID**: SIMULATION-BE-001.1-S7

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 2, "y": 2, "heading": "S" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 2, "y": 1, "heading": "S" }, "rejection": null }`

##### SCENARIO 8: MOVE_FORWARD heading W decrements x by 1

**Scenario ID**: SIMULATION-BE-001.1-S8

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 2, "y": 2, "heading": "W" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 1, "y": 2, "heading": "W" }, "rejection": null }`

---

#### SIMULATION-BE-001.2: Mission Service simulation loop records Steps and returns updated rover states

**Parent**: SIMULATION-STORY-001
**Service**: Mission Service (`mission:8000`)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): Mission Service (app) orchestration; HTTP Client calls `POST /api/v1/simulation/move` per operation; `InMemorySessionRepository` `save()`; `Session.rovers` and `Session.history` updated after each step
* Chapter 5, Key Domain Types (05-building-block-view.md): `Step` value object fields: `rover_index`, `operation`, `resulting_position`, `resulting_heading`, `rejection`
* Chapter 5, Step History Contract (05-building-block-view.md): each `Step` carries full resulting state; `rejection: null` for successful moves
* Chapter 6.2 (06-runtime-view.md): Execute Commands, Happy Path, steps 5-8 (simulation loop, step recording, session save, response with updated rover states and new steps)

**Depends on**: COMMAND-BE-001.2 (parse phase: session load and Command Service call)

AS A Developer
I WANT the Mission Service to iterate over the `Operation` list from the parse phase, call `POST /api/v1/simulation/move` once per operation, record each result as a `Step` in the session history, save the updated session, and return all updated rover states plus the new steps
SO THAT the full command execution cycle is complete and the step history is a correct, ordered record of every move

##### SCENARIO 1: Simulation loop for kata example produces correct final state and 9 steps

**Scenario ID**: SIMULATION-BE-001.2-S1

**GIVEN**
* An active session in InMemorySessionRepository with plateau `5 5`, Rover 0 at `1 2 N`, Rover 1 at `3 3 E`
* The parse phase (COMMAND-BE-001.2) has returned the 9-operation list for `LMLMLMLMM`

**WHEN**
* The Mission Service executes the simulation loop: for each of the 9 operations, it collects occupied positions of all rovers except Rover 0 and calls `POST /api/v1/simulation/move`

**THEN**
* `POST /api/v1/simulation/move` is called exactly 9 times
* After the loop, Rover 0 state in the session is `1 3 N`
* The session history has 9 new `Step` records, each with `rover_index: 0`, the corresponding `operation`, `resulting_position`, `resulting_heading`, and `rejection: null`
* Assumption: HTTP 200 is returned with updated rover states (Rover 0 at `1 3 N`, Rover 1 unchanged at `3 3 E`) and the 9 new steps (response field names and status code are not specified by the architecture)
* InMemorySessionRepository holds the updated session with Rover 0 at `1 3 N` and 9 appended steps

##### SCENARIO 2: Occupied positions exclude the moving rover on each call

**Scenario ID**: SIMULATION-BE-001.2-S2

**GIVEN**
* An active session with plateau `5 5`, Rover 0 at `1 2 N`, Rover 1 at `3 3 E`
* The parse phase has returned `[MOVE_FORWARD]` for Rover 0

**WHEN**
* The Mission Service calls `POST /api/v1/simulation/move` for Rover 0

**THEN**
* The `occupied_positions` passed to the Simulation Service contains the position of Rover 1 (`3 3`) but not the current position of Rover 0 (`1 2`), as defined in Chapter 5.2, Simulation Service components (the moving rover is excluded)

##### SCENARIO 3: Each step in history carries the full resulting state

**Scenario ID**: SIMULATION-BE-001.2-S3

**GIVEN**
* The simulation loop for `LMLMLMLMM` on Rover 0 starting at `1 2 N` has completed

**WHEN**
* The session history is inspected

**THEN**
* Every `Step` record contains non-null values for `rover_index`, `operation`, `resulting_position`, and `resulting_heading`
* Every `Step` has `rejection: null` (no rejections occur in the kata example happy path)
* The final `Step` shows `resulting_position: { x: 1, y: 3 }` and `resulting_heading: "N"`

---

### Infrastructure Stories

The Simulation Service container, its statelessness, the absence of an event bus, and logging observability follow the same patterns established in COMMAND-INFRA-001.1 through COMMAND-INFRA-001.4. Full INFRA definitions for the Simulation Service are provided below as new stories; they reference the patterns from MISSION-INFRA-001 and COMMAND-INFRA-001 where applicable.

#### SIMULATION-INFRA-001.1: Deploy the Simulation Service container

**Parent**: SIMULATION-STORY-001
**Service**: Simulation Service (`simulation`)
**Architecture references**:
* Chapter 7.1 (07-deployment-view.md): `simulation` Compose service, internal port 8002, not published to host; lists Dockerfile as `simulation/Dockerfile`
* Chapter 7.3 (07-deployment-view.md): Dockerfile listed as `services/simulation/Dockerfile`; base image `python:3.12-slim`; runs `uvicorn` on the declared port
* Chapter 8.5 (08-cross-cutting-concepts.md): Environment variables `LOG_LEVEL`, `UVICORN_HOST`, `UVICORN_PORT=8002`
* ADR-004 (09-architecture-decisions.md): Docker Compose for local orchestration

**Gap**: The same Dockerfile path inconsistency noted in MISSION-INFRA-001.1 applies here (`simulation/Dockerfile` in Chapter 7.1 vs `services/simulation/Dockerfile` in Chapter 7.3) and must be resolved consistently across all three services.

AS A Developer
I WANT the Simulation Service to run as a Docker Compose service named `simulation` on the internal network at `simulation:8002`
SO THAT the Mission Service can call `POST /api/v1/simulation/move` on it and no port is exposed directly to the host

##### SCENARIO 1: Simulation Service starts and is reachable from the Mission Service

**Scenario ID**: SIMULATION-INFRA-001.1-S1

**GIVEN**
* `docker-compose.yml` defines the `simulation` service with image built from the Dockerfile (path to be confirmed per Gap above), internal port 8002, and environment variables `LOG_LEVEL=INFO`, `UVICORN_HOST=0.0.0.0`, `UVICORN_PORT=8002`
* Assumption: Request body `{ "rover": { "x": 1, "y": 2, "heading": "N" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }` is used for the probe call

**WHEN**
* `docker compose up --build` is run

**THEN**
* The `simulation` container starts without error
* `POST http://simulation:8002/api/v1/simulation/move` with the probe body from the Mission Service container returns HTTP 200, confirming the service is reachable on the internal Docker Compose network

##### SCENARIO 2: Simulation Service port is not exposed to the host

**Scenario ID**: SIMULATION-INFRA-001.1-S2

**GIVEN**
* Docker Compose is running with the `simulation` service configured with no `ports` mapping

**WHEN**
* A request is made directly to `http://localhost:8002/api/v1/simulation/move` from the host machine

**THEN**
* The connection is refused, confirming no host port is published for the Simulation Service

---

#### SIMULATION-INFRA-001.2: Simulation Service is stateless (no data store)

**Parent**: SIMULATION-STORY-001
**Service**: Simulation Service (`simulation`)
**Architecture references**:
* Chapter 5.1 (05-building-block-view.md): Simulation Service, "None (stateless)" under Data owned
* Chapter 5.2 (05-building-block-view.md): Simulation Service components contain no repository or storage component
* ADR-005 (09-architecture-decisions.md): In-process memory as the only state store; Command Service and Simulation Service are stateless

Not applicable for a persistent data store. The Simulation Service owns no state: it receives a move request, computes the result, and returns it. No repository, dict, or file is written. Same pattern as COMMAND-INFRA-001.2.

AS A Developer
I WANT to confirm that the Simulation Service holds no state between requests
SO THAT it can be restarted or scaled without data-loss concerns and its statelessness is verifiable by test

##### SCENARIO 1: Simulation Service retains no state between requests

**Scenario ID**: SIMULATION-INFRA-001.2-S1

**GIVEN**
* The `simulation` container is running
* Assumption: `POST /api/v1/simulation/move` has been called with rover at `1 2 N`, operation `MOVE_FORWARD`, and returned rover at `1 3 N`

**WHEN**
* The `simulation` container is restarted with `docker compose restart simulation`
* Assumption: `POST /api/v1/simulation/move` is called again with rover at `2 2 N`, operation `TURN_LEFT`

**THEN**
* HTTP 200 is returned with rover at `2 2 W`, confirming the service has no memory of the previous request and behaves identically after restart

---

#### SIMULATION-INFRA-001.3: No event bus (synchronous REST only)

**Parent**: SIMULATION-STORY-001
**Service**: Simulation Service (`simulation`)
**Architecture references**:
* ADR-009 (09-architecture-decisions.md): Synchronous REST for inter-service communication; no message broker

Not applicable. See MISSION-INFRA-001.3 (ADR-009).

---

#### SIMULATION-INFRA-001.4: Logging observability for the Simulation Service

**Parent**: SIMULATION-STORY-001
**Service**: Simulation Service (`simulation`)
**Architecture references**:
* Chapter 8.4 (08-cross-cutting-concepts.md): All FastAPI services log incoming request method and path, response status, and latency via uvicorn access log to stdout; `LOG_LEVEL` env var; `docker compose logs`

AS A Developer
I WANT the Simulation Service to emit uvicorn access log lines to stdout for each request
SO THAT I can observe move requests and their outcomes using `docker compose logs simulation`

**Note**: Chapter 8.4 defines application-level `INFO` logging only for the Mission Service. The Simulation Service is covered only by the uvicorn access log. Same pattern as COMMAND-INFRA-001.4. No `/health` endpoint is defined (gap noted in MISSION-INFRA-001.4).

##### SCENARIO 1: Move request is logged

**Scenario ID**: SIMULATION-INFRA-001.4-S1

**GIVEN**
* The `simulation` container is running with `LOG_LEVEL=INFO`

**WHEN**
* Assumption: `POST /api/v1/simulation/move` is called with rover at `1 2 N`, operation `MOVE_FORWARD`, and returns HTTP 200

**THEN**
* `docker compose logs simulation` shows a uvicorn access log line containing `POST /api/v1/simulation/move` and status `200`

---

### Implementation Order

1. SIMULATION-INFRA-001.1: Deploy the Simulation Service container (Docker Compose, ports, env vars; resolve Dockerfile path gap consistent with MISSION-INFRA-001.1 and COMMAND-INFRA-001.1)
2. SIMULATION-INFRA-001.2: Confirm Simulation Service is stateless (no repository, restart test)
3. SIMULATION-INFRA-001.3: Confirm no event bus (see MISSION-INFRA-001.3, ADR-009)
4. SIMULATION-INFRA-001.4: Confirm uvicorn access log output
5. SIMULATION-BE-001.1: Implement `POST /api/v1/simulation/move` with Simulation domain logic (turn and move rules, all four headings)
6. SIMULATION-BE-001.2: Extend Mission Service `POST /api/v1/session/commands` with the simulation loop (builds on COMMAND-BE-001.2 parse phase: iterate operations, call Simulation Service, record Steps, save session, return updated states)
7. SIMULATION-FE-001.1: Implement Grid View re-render with updated rover positions after command submission
8. SIMULATION-STORY-001 end-to-end verification: Player submits `LMLMLMLMM` for Rover 0 on plateau `5 5` from `1 2 N`, Mission Service completes the full loop, Grid View renders Rover 0 at `1 3 N` (SIMULATION-STORY-001-S1)

---

## SIMULATION-STORY-002: Reject Out-of-Bounds Moves

**Priority**: Supporting (80%)
**Features**: F-4 (Collision detection)
**Architecture references**:
* Chapter 6.4 (06-runtime-view.md): Command Rejected: Out of Bounds, full walkthrough steps 1-5
* Chapter 5, Rejected-Move Behaviour (05-building-block-view.md): when the Simulation Service returns `OUT_OF_BOUNDS`, the Mission Service keeps the rover at its current position and appends a `Step` with `rejection` set
* Chapter 5.2 (05-building-block-view.md): Simulation domain component; `POST /api/v1/simulation/move` inputs and `CommandRejection` return
* Chapter 5, Key Domain Types (05-building-block-view.md): `CommandRejection` value object (`OUT_OF_BOUNDS` or `COLLISION`); `Step` with `rejection` field
* Chapter 5, Step History Contract (05-building-block-view.md): step history records rejected moves; `rejection` field is non-null for refused moves
* Chapter 10.2 (10-quality-requirements.md): QS-03 - Rover stays at `0 0 S` on plateau `5 5` after `M`; `rejection: "OUT_OF_BOUNDS"`; HTTP 200

AS A Player
I WANT a move that would take a rover off the plateau to be rejected and the rover to stay in place
SO THAT I know immediately when a command would go out of bounds and can see the failed attempt in the history

---

### Scenarios

#### SCENARIO 1: MOVE_FORWARD rejected at south edge facing S (QS-03)

**Scenario ID**: SIMULATION-STORY-002-S1

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `0 0 S`

**WHEN**
* The player submits the Command Form for Rover 0 with command string `M`

**THEN**
* Rover 0 remains at `0 0 S` in the response (position and heading unchanged)
* Assumption: HTTP 200 is returned (Chapter 6.4 step 4 confirms HTTP 200; response field names are not specified by the architecture)
* Assumption: The response contains a step with `rejection: "OUT_OF_BOUNDS"` (Chapter 6.4 step 4; `OUT_OF_BOUNDS` value from Chapter 5, Key Domain Types)
* The Grid View renders Rover 0 at `(0,0)` facing `S` with an out-of-bounds indicator on that step (Chapter 6.4 step 5)

---

#### SCENARIO 2: MOVE_FORWARD rejected at north edge facing N

**Scenario ID**: SIMULATION-STORY-002-S2

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `2 5 N`

**WHEN**
* The player submits the Command Form for Rover 0 with command string `M`

**THEN**
* Rover 0 remains at `2 5 N`
* Assumption: HTTP 200 is returned with `rejection: "OUT_OF_BOUNDS"` for that step
* The Grid View renders Rover 0 at `(2,5)` facing `N` with an out-of-bounds indicator

---

#### SCENARIO 3: MOVE_FORWARD rejected at east edge facing E

**Scenario ID**: SIMULATION-STORY-002-S3

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `5 2 E`

**WHEN**
* The player submits the Command Form for Rover 0 with command string `M`

**THEN**
* Rover 0 remains at `5 2 E`
* Assumption: HTTP 200 is returned with `rejection: "OUT_OF_BOUNDS"` for that step
* The Grid View renders Rover 0 at `(5,2)` facing `E` with an out-of-bounds indicator

---

#### SCENARIO 4: Rejected move is recorded in history; subsequent valid move succeeds

**Scenario ID**: SIMULATION-STORY-002-S4

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `0 0 S`

**WHEN**
* The player submits the Command Form for Rover 0 with command string `MR`

**THEN**
* The first operation (`MOVE_FORWARD`) is rejected with `OUT_OF_BOUNDS`; Rover 0 stays at `0 0 S`
* The second operation (`TURN_RIGHT`) succeeds; Rover 0 is now at `0 0 W`
* Assumption: The response contains 2 `Step` records: the first with `rejection: "OUT_OF_BOUNDS"`, the second with `rejection: null`
* The Grid View renders Rover 0 at `(0,0)` facing `W`

---

### Frontend Stories

#### SIMULATION-FE-002.1: Grid View marks out-of-bounds steps with a visual indicator

**Parent**: SIMULATION-STORY-002
**Component**: Grid View, App (05-building-block-view.md, Chapter 5.2)
**Architecture references**:
* Chapter 6.4 (06-runtime-view.md): step 5 - Frontend renders rover in original position and marks step with out-of-bounds indicator
* Chapter 5.2 (05-building-block-view.md): Grid View is purely presentational; App passes rover states and step history as props
* Chapter 5, Step History Contract (05-building-block-view.md): `rejection` field is `"OUT_OF_BOUNDS"` or `null` per step

AS A Player
I WANT the grid to show the rover unmoved and mark the failed step with a visible out-of-bounds indicator
SO THAT I can see at a glance that the move was refused and why

##### SCENARIO 1: Grid View renders rover unmoved with out-of-bounds indicator

**Scenario ID**: SIMULATION-FE-002.1-S1

**GIVEN**
* App state contains plateau `5 5`, Rover 0 at `0 0 S`
* Assumption: The API Client returns a response with Rover 0 still at `0 0 S` and 1 new `Step` with `rejection: "OUT_OF_BOUNDS"`

**WHEN**
* App updates its state from the API response and passes it to Grid View

**THEN**
* Grid View renders Rover 0 at cell `(0,0)` facing `S` (position unchanged)
* The step is marked with an out-of-bounds indicator (Chapter 6.4 step 5; exact visual form is not specified by the architecture)
* No error dialog or blocking message is shown (HTTP 200 is returned, not an error)

---

### Backend Stories

#### SIMULATION-BE-002.1: Simulation Service returns OUT_OF_BOUNDS rejection for a move outside the plateau

**Parent**: SIMULATION-STORY-002
**Service**: Simulation Service (`simulation:8002`)
**Architecture references**:
* Chapter 6.4 (06-runtime-view.md): steps 2-3 - Simulation Service computes target cell, finds it outside `(0,0)-(width,height)`, returns `{ rover: unchanged, rejection: "OUT_OF_BOUNDS" }`
* Chapter 5.2 (05-building-block-view.md): Simulation domain component; `POST /api/v1/simulation/move`
* Chapter 5, Key Domain Types (05-building-block-view.md): `CommandRejection` value object; `OUT_OF_BOUNDS`
* Chapter 10.2 (10-quality-requirements.md): QS-03

AS A Developer
I WANT the Simulation Service to return `rejection: "OUT_OF_BOUNDS"` with the rover unchanged when a `MOVE_FORWARD` would take the rover outside the plateau boundary
SO THAT the Mission Service can record the rejected step without altering the rover's position

##### SCENARIO 1: MOVE_FORWARD south from (0,0) on plateau 5 5 is rejected (QS-03)

**Scenario ID**: SIMULATION-BE-002.1-S1

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 0, "y": 0, "heading": "S" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 0, "y": 0, "heading": "S" }, "rejection": "OUT_OF_BOUNDS" }` (rover unchanged; `OUT_OF_BOUNDS` from Chapter 5, Key Domain Types; field names not specified by the architecture)

##### SCENARIO 2: MOVE_FORWARD north from (2,5) on plateau 5 5 is rejected

**Scenario ID**: SIMULATION-BE-002.1-S2

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 2, "y": 5, "heading": "N" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 2, "y": 5, "heading": "N" }, "rejection": "OUT_OF_BOUNDS" }`

##### SCENARIO 3: MOVE_FORWARD east from (5,2) on plateau 5 5 is rejected

**Scenario ID**: SIMULATION-BE-002.1-S3

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 5, "y": 2, "heading": "E" }, "operation": "MOVE_FORWARD", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 5, "y": 2, "heading": "E" }, "rejection": "OUT_OF_BOUNDS" }`

##### SCENARIO 4: Turn commands at the boundary are never rejected (only MOVE_FORWARD can go out of bounds)

**Scenario ID**: SIMULATION-BE-002.1-S4

**GIVEN**
* Assumption: Request body `{ "rover": { "x": 0, "y": 0, "heading": "S" }, "operation": "TURN_LEFT", "plateau": { "width": 5, "height": 5 }, "occupied_positions": [] }`

**WHEN**
* `POST /api/v1/simulation/move` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "rover": { "x": 0, "y": 0, "heading": "E" }, "rejection": null }` (turn commands do not change position; no boundary violation possible)

---

#### SIMULATION-BE-002.2: Mission Service records OUT_OF_BOUNDS step and keeps rover position

**Parent**: SIMULATION-STORY-002
**Service**: Mission Service (`mission:8000`)
**Architecture references**:
* Chapter 6.4 (06-runtime-view.md): steps 3-5 - Mission Service keeps rover position, appends `Step` with `rejection: "OUT_OF_BOUNDS"`, saves session, responds HTTP 200
* Chapter 5, Rejected-Move Behaviour (05-building-block-view.md): Mission Service leaves rover at current position and records `Step` with `rejection` set; step history is a complete log of all attempted moves including rejected ones

AS A Developer
I WANT the Mission Service to leave the rover at its current position and append a `Step` with `rejection: "OUT_OF_BOUNDS"` when the Simulation Service returns that rejection
SO THAT the history is a complete record of all attempted moves and the rover state is correct for subsequent commands

##### SCENARIO 1: Rejected move is recorded; rover state unchanged in session

**Scenario ID**: SIMULATION-BE-002.2-S1

**GIVEN**
* An active session in InMemorySessionRepository with plateau `5 5`, Rover 0 at `0 0 S`
* Assumption: Request body `{ "rover_index": 0, "commands": "M" }`

**WHEN**
* `POST /api/v1/session/commands` is called (via gateway)

**THEN**
* The Mission Service calls `POST /api/v1/simulation/move` once and receives `rejection: "OUT_OF_BOUNDS"`
* Rover 0 position in InMemorySessionRepository remains `0 0 S`
* The session history gains 1 new `Step` with `rover_index: 0`, `operation: "MOVE_FORWARD"`, `resulting_position: { x: 0, y: 0 }`, `resulting_heading: "S"`, `rejection: "OUT_OF_BOUNDS"`
* Assumption: HTTP 200 is returned (Chapter 6.4 step 4; status code not formally specified)
* Assumption: The response includes Rover 0 still at `0 0 S` and the 1 new step with `rejection: "OUT_OF_BOUNDS"`

##### SCENARIO 2: Rejected step followed by a valid step - both recorded correctly

**Scenario ID**: SIMULATION-BE-002.2-S2

**GIVEN**
* An active session in InMemorySessionRepository with plateau `5 5`, Rover 0 at `0 0 S`
* Assumption: Request body `{ "rover_index": 0, "commands": "MR" }`

**WHEN**
* `POST /api/v1/session/commands` is called

**THEN**
* The Mission Service calls `POST /api/v1/simulation/move` twice
* First call returns `rejection: "OUT_OF_BOUNDS"`; Rover 0 stays at `0 0 S`
* Second call (`TURN_RIGHT`) returns `rejection: null`; Rover 0 moves to `0 0 W`
* The session history gains 2 `Step` records in order: first with `rejection: "OUT_OF_BOUNDS"`, second with `rejection: null`
* InMemorySessionRepository holds Rover 0 at `0 0 W` with 2 appended steps

---

### Infrastructure Stories

SIMULATION-STORY-002 uses the same Simulation Service and Mission Service containers defined in SIMULATION-INFRA-001.1 and MISSION-INFRA-001.1. The statelessness (SIMULATION-INFRA-001.2), event bus absence (SIMULATION-INFRA-001.3), and Simulation Service logging (SIMULATION-INFRA-001.4) sub-stories apply unchanged. The new sub-story below covers the Mission Service application-level logging that Chapter 8.4 defines specifically for that service.

#### SIMULATION-INFRA-002.1: Mission Service logs each step result including rejection reason

**Parent**: SIMULATION-STORY-002
**Service**: Mission Service (`mission:8000`)
**Architecture references**:
* Chapter 8.4 (08-cross-cutting-concepts.md): Mission Service logs "each step result (operation, rover index, rejection if any)" to stdout at `INFO` level using Python `logging`; log level controlled by `LOG_LEVEL` env var; observable via `docker compose logs`

AS A Developer
I WANT the Mission Service to emit an `INFO` log line for each step result, including the operation, the rover index, and the rejection reason when present
SO THAT I can confirm rejected moves are recorded correctly by inspecting `docker compose logs mission`

##### SCENARIO 1: Rejected move produces an INFO log line with operation, rover index, and OUT_OF_BOUNDS

**Scenario ID**: SIMULATION-INFRA-002.1-S1

**GIVEN**
* The `mission` container is running with `LOG_LEVEL=INFO`
* An active session exists with plateau `5 5`, Rover 0 at `0 0 S`

**WHEN**
* `POST /api/v1/session/commands` is called with `{ "rover_index": 0, "commands": "M" }` and the Simulation Service returns `rejection: "OUT_OF_BOUNDS"`

**THEN**
* `docker compose logs mission` shows an `INFO` log line containing the operation (`MOVE_FORWARD`), the rover index (`0`), and the rejection reason (`OUT_OF_BOUNDS`)

---

### Implementation Order

1. SIMULATION-BE-002.1: Extend Simulation domain in Simulation Service to return `OUT_OF_BOUNDS` rejection when target cell is outside plateau boundary (builds on SIMULATION-BE-001.1; no new container work)
2. SIMULATION-BE-002.2: Extend Mission Service simulation loop to handle `OUT_OF_BOUNDS` rejection: keep rover position, record `Step` with `rejection` set (builds on SIMULATION-BE-001.2)
3. SIMULATION-INFRA-002.1: Add `INFO` log statement in Mission Service for each step result, including operation, rover index, and rejection if any (Chapter 8.4)
4. SIMULATION-FE-002.1: Extend Grid View and App to render out-of-bounds indicator on rejected steps
5. SIMULATION-STORY-002 end-to-end verification: Player submits `M` for Rover 0 at `0 0 S` on plateau `5 5`; rover stays at `0 0 S`; step shows `rejection: "OUT_OF_BOUNDS"`; Grid View renders indicator; `docker compose logs mission` shows the INFO log line (SIMULATION-STORY-002-S1, SIMULATION-INFRA-002.1-S1)
