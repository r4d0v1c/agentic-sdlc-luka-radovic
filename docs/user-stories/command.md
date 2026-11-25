# Command User Stories

## COMMAND-STORY-001: Submit a Command String

**Priority**: Core (20%)
**Features**: F-3 (Command execution)
**Architecture references**:
* Chapter 6.2 (06-runtime-view.md): Execute Commands, Happy Path, steps 1-4
* Chapter 5.1 (05-building-block-view.md): Command Service responsibility; `POST /api/v1/commands/parse` endpoint (internal, called by Mission Service); stateless
* Chapter 5.2 (05-building-block-view.md): Command Service components (API Router, Command Parser); Command Form and API Client frontend components; `Command Form -> API Client -> POST /api/v1/session/commands`
* Chapter 8.2 (08-cross-cutting-concepts.md): Schema validation at the API Router; domain validation in Command Parser
* Chapter 8.3 (08-cross-cutting-concepts.md): `UnknownCommandError` -> HTTP 422, error code `UNKNOWN_COMMAND`

AS A Player
I WANT to type a command string of `L`, `R`, and `M` characters for a rover and submit it
SO THAT each valid command is accepted and parsed without error

---

### Scenarios

#### SCENARIO 1: Submit a valid multi-character command string for one rover

**Scenario ID**: COMMAND-STORY-001-S1

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `1 2 N`, Rover 1 at `3 3 E`
* The player types command string `LMLMLMLMM` for Rover 0

**WHEN**
* The player submits the Command Form

**THEN**
* Assumption: The Frontend sends `POST /api/v1/session/commands` with body `{ "rover_index": 0, "commands": "LMLMLMLMM" }` (Chapter 6.2 step 2 gives `{ rover_index: 0, commands: "LMLM" }` as an example; field names `rover_index` and `commands` are taken from that example but are not formally specified in the architecture)
* The Mission Service calls `POST /api/v1/commands/parse` on the Command Service with the raw string `"LMLMLMLMM"`
* Assumption: The Command Service responds HTTP 200 with `{ "operations": ["TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD"] }` (response field name `operations` and envelope are not specified by the architecture)
* The Command Form shows no error message

---

#### SCENARIO 2: Submit a valid single-character command

**Scenario ID**: COMMAND-STORY-001-S2

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `1 2 N`
* The player types command string `M` for Rover 0

**WHEN**
* The player submits the Command Form

**THEN**
* Assumption: The Frontend sends `POST /api/v1/session/commands` with body `{ "rover_index": 0, "commands": "M" }`
* The Mission Service calls `POST /api/v1/commands/parse` with `"M"`
* Assumption: The Command Service responds HTTP 200 with `{ "operations": ["MOVE_FORWARD"] }`
* The Command Form shows no error message

---

#### SCENARIO 3: Submit a command string containing only turn commands

**Scenario ID**: COMMAND-STORY-001-S3

**GIVEN**
* An active session exists with plateau `5 5`, Rover 0 at `0 0 N`
* The player types command string `LR` for Rover 0

**WHEN**
* The player submits the Command Form

**THEN**
* Assumption: The Frontend sends `POST /api/v1/session/commands` with body `{ "rover_index": 0, "commands": "LR" }`
* The Mission Service calls `POST /api/v1/commands/parse` with `"LR"`
* Assumption: The Command Service responds HTTP 200 with `{ "operations": ["TURN_LEFT", "TURN_RIGHT"] }`
* The Command Form shows no error message

---

#### SCENARIO 4: Submit a command string with no active session

**Scenario ID**: COMMAND-STORY-001-S4

**GIVEN**
* No active session exists

**WHEN**
* Assumption: `POST /api/v1/session/commands` is called with body `{ "rover_index": 0, "commands": "M" }`

**THEN**
* The Mission Service returns HTTP 404 with `{ "error": "SESSION_NOT_FOUND" }` (Chapter 8.3 defines `SessionNotFoundError` -> 404)
* The Frontend displays the error to the player
* No call is made to the Command Service

---

### Frontend Stories

#### COMMAND-FE-001.1: Command Form collects a command string per rover and submits it

**Parent**: COMMAND-STORY-001
**Component**: Command Form (05-building-block-view.md, Chapter 5.2)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): Command Form responsibility; `Command Form -> API Client -> POST /api/v1/session/commands`
* Chapter 6.2 (06-runtime-view.md): Execute Commands, Happy Path, step 1 (player types command string and submits via Command Form)
* Chapter 8.3 (08-cross-cutting-concepts.md): Frontend API Client surfaces `detail` field on non-2xx responses

AS A Player
I WANT a form that lets me select a rover and enter a command string
SO THAT I can submit commands one rover at a time and see errors clearly if the submission fails

##### SCENARIO 1: Command Form submits a valid command string

**Scenario ID**: COMMAND-FE-001.1-S1

**GIVEN**
* An active session exists with two rovers
* The Command Form is rendered with Rover 0 selected and command string `LMLMLMLMM` entered

**WHEN**
* The player clicks Submit

**THEN**
* Assumption: The API Client is called with `POST /api/v1/session/commands` and body `{ "rover_index": 0, "commands": "LMLMLMLMM" }` (field names are not formally specified by the architecture)
* The API Client receives a non-error response from the backend
* The Command Form shows no error message

##### SCENARIO 2: Command Form displays error on session not found

**Scenario ID**: COMMAND-FE-001.1-S2

**GIVEN**
* No active session exists
* The Command Form is rendered

**WHEN**
* The player submits a command string and the API Client returns HTTP 404 with `{ "error": "SESSION_NOT_FOUND", "detail": "No active session" }`

**THEN**
* The Command Form displays the detail string from the error body (Chapter 8.3 defines `SessionNotFoundError` -> 404 and `SESSION_NOT_FOUND`; Assumption: the `detail` text is "No active session" - the architecture does not specify the exact message)
* The form remains open and the player can retry after creating a session

---

### Backend Stories

#### COMMAND-BE-001.1: Command Parser translates a valid command string into an Operation list

**Parent**: COMMAND-STORY-001
**Service**: Command Service (`command:8001`)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): Command Parser domain component; `POST /api/v1/commands/parse`; translates raw string into ordered `Operation` list; `Operation` enum values `TURN_LEFT`, `TURN_RIGHT`, `MOVE_FORWARD`
* Chapter 6.2 (06-runtime-view.md): Execute Commands, Happy Path, steps 3-4
* Chapter 8.2 (08-cross-cutting-concepts.md): Domain validation in Command Parser

AS A Developer
I WANT the Command Service `POST /api/v1/commands/parse` endpoint to translate every `L`, `R`, and `M` character into the corresponding `Operation` value and return the ordered list
SO THAT the Mission Service receives a typed, ordered sequence it can pass to the Simulation Service one operation at a time

##### SCENARIO 1: Parse a multi-character command string

**Scenario ID**: COMMAND-BE-001.1-S1

**GIVEN**
* Assumption: Request body `{ "commands": "LMLMLMLMM" }` (the endpoint accepts a raw command string; field name `commands` is not formally specified by the architecture)

**WHEN**
* `POST /api/v1/commands/parse` is called on the Command Service directly (internal call from Mission Service)

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "operations": ["TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD"] }` (Chapter 6.2 step 4 confirms the ordered `Operation` list is returned; field name `operations` and the exact response envelope are not specified by the architecture)

##### SCENARIO 2: Parse the `L` character

**Scenario ID**: COMMAND-BE-001.1-S2

**GIVEN**
* Assumption: Request body `{ "commands": "L" }` (field name `commands` is not formally specified by the architecture)

**WHEN**
* `POST /api/v1/commands/parse` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "operations": ["TURN_LEFT"] }` (field name `operations` and envelope are not specified by the architecture)

##### SCENARIO 3: Parse the `R` character

**Scenario ID**: COMMAND-BE-001.1-S3

**GIVEN**
* Assumption: Request body `{ "commands": "R" }`

**WHEN**
* `POST /api/v1/commands/parse` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "operations": ["TURN_RIGHT"] }`

##### SCENARIO 4: Parse the `M` character

**Scenario ID**: COMMAND-BE-001.1-S4

**GIVEN**
* Assumption: Request body `{ "commands": "M" }`

**WHEN**
* `POST /api/v1/commands/parse` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "operations": ["MOVE_FORWARD"] }`

##### SCENARIO 5: Preserves the order of operations exactly

**Scenario ID**: COMMAND-BE-001.1-S5

**GIVEN**
* Assumption: Request body `{ "commands": "RML" }`

**WHEN**
* `POST /api/v1/commands/parse` is called

**THEN**
* HTTP 200 is returned
* Assumption: Response body is `{ "operations": ["TURN_RIGHT", "MOVE_FORWARD", "TURN_LEFT"] }` in that exact order

---

#### COMMAND-BE-001.2: Mission Service loads the session and calls the Command Service parse endpoint

**Parent**: COMMAND-STORY-001
**Service**: Mission Service (`mission:8000`)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): `POST /api/v1/session/commands`; Mission Service (app) loads session via SessionRepository; HTTP Client calls `POST /api/v1/commands/parse`; returns ordered `Operation` list (Chapter 6.2 steps 3-4)
* Chapter 6.2 (06-runtime-view.md): Execute Commands, Happy Path, steps 1-4 (parse phase only; simulation loop and step recording covered in SIMULATION-STORY-001)
* Chapter 8.3 (08-cross-cutting-concepts.md): `SessionNotFoundError` -> HTTP 404, error code `SESSION_NOT_FOUND`

AS A Developer
I WANT the Mission Service `POST /api/v1/session/commands` endpoint to load the active session and call `POST /api/v1/commands/parse` on the Command Service, receiving the ordered `Operation` list in return
SO THAT the parse phase is verified independently before the simulation loop (covered in SIMULATION-STORY-001) is added

##### SCENARIO 1: Mission Service loads session and receives Operation list from Command Service

**Scenario ID**: COMMAND-BE-001.2-S1

**GIVEN**
* An active session exists in InMemorySessionRepository with plateau `5 5`, Rover 0 at `1 2 N`
* Assumption: Request body `{ "rover_index": 0, "commands": "LMLMLMLMM" }` (field names are not formally specified by the architecture)

**WHEN**
* `POST /api/v1/session/commands` is called on the Mission Service (via gateway)

**THEN**
* The Mission Service loads the session from InMemorySessionRepository
* The Mission Service calls `POST /api/v1/commands/parse` on the Command Service with the raw string `"LMLMLMLMM"`
* Assumption: The Command Service returns HTTP 200 with `{ "operations": ["TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD"] }`
* The Mission Service holds the 9-element `Operation` list ready for the simulation loop (simulation loop, step recording, and response with rover states are covered in SIMULATION-STORY-001)

##### SCENARIO 2: Returns 404 when no session exists

**Scenario ID**: COMMAND-BE-001.2-S2

**GIVEN**
* No active session in InMemorySessionRepository
* Assumption: Request body `{ "rover_index": 0, "commands": "M" }`

**WHEN**
* `POST /api/v1/session/commands` is called

**THEN**
* HTTP 404 is returned with `{ "error": "SESSION_NOT_FOUND" }` (Chapter 8.3)
* No call is made to the Command Service

---

### Infrastructure Stories

#### COMMAND-INFRA-001.1: Deploy the Command Service container

**Parent**: COMMAND-STORY-001
**Service**: Command Service (`command`)
**Architecture references**:
* Chapter 7.1 (07-deployment-view.md): `command` Compose service, internal port 8001, not published to host; lists Dockerfile as `command/Dockerfile`
* Chapter 7.3 (07-deployment-view.md): Dockerfile listed as `services/command/Dockerfile`; base image `python:3.12-slim`; runs `uvicorn` on the declared port
* Chapter 8.5 (08-cross-cutting-concepts.md): Environment variables `LOG_LEVEL`, `UVICORN_HOST`, `UVICORN_PORT=8001`
* ADR-004 (09-architecture-decisions.md): Docker Compose for local orchestration

**Gap**: Chapter 7.1 lists `command/Dockerfile`; Chapter 7.3 lists `services/command/Dockerfile`. The same inconsistency noted in MISSION-INFRA-001.1 applies here. The correct path must be confirmed and both chapters corrected together.

AS A Developer
I WANT the Command Service to run as a Docker Compose service named `command` on the internal network at `command:8001`
SO THAT the Mission Service can call `POST /api/v1/commands/parse` on it and no port is exposed directly to the host

##### SCENARIO 1: Command Service starts and is reachable from the Mission Service

**Scenario ID**: COMMAND-INFRA-001.1-S1

**GIVEN**
* `docker-compose.yml` defines the `command` service with image built from the Dockerfile (path to be confirmed per Gap above), internal port 8001, and environment variables `LOG_LEVEL=INFO`, `UVICORN_HOST=0.0.0.0`, `UVICORN_PORT=8001`

**WHEN**
* `docker compose up --build` is run

**THEN**
* The `command` container starts without error
* Assumption: `POST http://command:8001/api/v1/commands/parse` with body `{ "commands": "M" }` from the Mission Service container returns HTTP 200, confirming the service is reachable on the internal Docker Compose network

##### SCENARIO 2: Command Service port is not exposed to the host

**Scenario ID**: COMMAND-INFRA-001.1-S2

**GIVEN**
* Docker Compose is running with the `command` service configured with no `ports` mapping

**WHEN**
* A request is made directly to `http://localhost:8001/api/v1/commands/parse` from the host machine

**THEN**
* The connection is refused, confirming no host port is published for the Command Service

---

#### COMMAND-INFRA-001.2: Command Service is stateless (no data store)

**Parent**: COMMAND-STORY-001
**Service**: Command Service (`command`)
**Architecture references**:
* Chapter 5.1 (05-building-block-view.md): Command Service, "None (stateless)" under Data owned
* Chapter 5.2 (05-building-block-view.md): Command Service components contain no repository or storage component
* ADR-005 (09-architecture-decisions.md): In-process memory as the only state store; Command Service and Simulation Service are stateless

Not applicable for a persistent data store. The Command Service owns no state: it receives a command string, translates it, and returns the result. No repository, dict, or file is written.

AS A Developer
I WANT to confirm that the Command Service holds no state between requests
SO THAT it can be restarted or scaled without data-loss concerns and its statelessness is verifiable by test

##### SCENARIO 1: Command Service retains no state between requests

**Scenario ID**: COMMAND-INFRA-001.2-S1

**GIVEN**
* The `command` container is running
* Assumption: `POST /api/v1/commands/parse` has been called with `{ "commands": "LMR" }` and returned `[TURN_LEFT, MOVE_FORWARD, TURN_RIGHT]`

**WHEN**
* The `command` container is restarted with `docker compose restart command`
* Assumption: `POST /api/v1/commands/parse` is called again with `{ "commands": "M" }`

**THEN**
* HTTP 200 is returned with `[MOVE_FORWARD]`, confirming the service has no memory of the previous request and behaves identically after restart

---

#### COMMAND-INFRA-001.3: No event bus (synchronous REST only)

**Parent**: COMMAND-STORY-001
**Service**: Command Service (`command`)
**Architecture references**:
* ADR-009 (09-architecture-decisions.md): Synchronous REST for inter-service communication; no message broker

Not applicable. ADR-009 explicitly rejects a message broker. The Command Service receives synchronous HTTP calls from the Mission Service only and returns a response within the same request-response cycle. See MISSION-INFRA-001.3 for the full rationale; this sub-story adds no new INFRA beyond what is already established there.

AS A Developer
I WANT to confirm that the Command Service participates in no asynchronous messaging and responds only within the synchronous request-response cycle
SO THAT the absence of a broker is verified for this service and the five-container boundary of ADR-009 is preserved

##### SCENARIO 1: Command parsing involves no asynchronous messaging

**Scenario ID**: COMMAND-INFRA-001.3-S1

**GIVEN**
* The Docker Compose stack is running (five containers: `frontend`, `gateway`, `mission`, `command`, `simulation`)

**WHEN**
* Assumption: `POST /api/v1/commands/parse` is called with `{ "commands": "LMR" }`

**THEN**
* `docker compose ps` shows exactly five running containers with no broker container present
* The parse response is returned synchronously within the same HTTP request-response cycle

---

#### COMMAND-INFRA-001.4: Logging observability for the Command Service

**Parent**: COMMAND-STORY-001
**Service**: Command Service (`command`)
**Architecture references**:
* Chapter 8.4 (08-cross-cutting-concepts.md): All FastAPI services log incoming request method and path, response status, and latency via uvicorn access log to stdout; `LOG_LEVEL` env var; `docker compose logs`

AS A Developer
I WANT the Command Service to emit uvicorn access log lines to stdout for each request
SO THAT I can observe parse requests and their outcomes using `docker compose logs command`

**Note**: Chapter 8.4 defines application-level `INFO` logging only for the Mission Service ("Session created/reset; command string received; each step result"). The Command Service is covered only by the uvicorn access log. No `/health` endpoint is defined for any service (gap noted in MISSION-INFRA-001.4).

##### SCENARIO 1: Command parse request is logged

**Scenario ID**: COMMAND-INFRA-001.4-S1

**GIVEN**
* The `command` container is running with `LOG_LEVEL=INFO`

**WHEN**
* Assumption: `POST /api/v1/commands/parse` is called with `{ "commands": "LMR" }` and returns HTTP 200

**THEN**
* `docker compose logs command` shows a uvicorn access log line containing `POST /api/v1/commands/parse` and status `200`

---

### Implementation Order

1. COMMAND-INFRA-001.1: Deploy the Command Service container (Docker Compose, ports, env vars; resolve Dockerfile path gap)
2. COMMAND-INFRA-001.2: Confirm Command Service is stateless (no repository, restart test)
3. COMMAND-INFRA-001.3: Confirm no event bus (verify Docker Compose service count)
4. COMMAND-INFRA-001.4: Confirm uvicorn access log output
5. COMMAND-BE-001.1: Implement `POST /api/v1/commands/parse` with Command Parser domain logic
6. COMMAND-BE-001.2: Implement `POST /api/v1/session/commands` on the Mission Service (load the session and call the Command Service parse endpoint; simulation loop is in SIMULATION-STORY-001)
7. COMMAND-FE-001.1: Implement Command Form with API Client call and error display
8. COMMAND-STORY-001 end-to-end verification: Player submits `LMLMLMLMM` for Rover 0 on plateau `5 5` from `1 2 N`, the Command Service parses the string and returns 9 operations, the Command Form shows no error (COMMAND-STORY-001-S1)

---
