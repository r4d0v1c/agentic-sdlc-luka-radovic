# Mission User Stories

## MISSION-STORY-001: Create a Session

**Priority**: Core (20%)
**Features**: F-1 (Plateau configuration), F-2 (Rover deployment), F-6 (Visual grid)
**Architecture references**:
* Chapter 6.1 (06-runtime-view.md): Create Session, happy path and error case; step 3 states the Mission Service validates all positions are within the plateau
* Chapter 5.1 (05-building-block-view.md): Mission Service responsibility, `POST /api/v1/session` endpoint, `Session` aggregate root
* Chapter 5.2 (05-building-block-view.md): Mission Service components (API Router, Mission Service app, InMemorySessionRepository); Frontend components (Plateau Form, Grid View, App)
* Chapter 8.2 (08-cross-cutting-concepts.md): Input validation, `422 Unprocessable Entity`, `OVERLAPPING_ROVERS` error code
* Chapter 8.3 (08-cross-cutting-concepts.md): Error handling table; `OverlappingRoversError` -> 422

AS A Player
I WANT to define a plateau and place one or more rovers on it
SO THAT I can see the grid with all rovers at their starting positions and begin issuing commands

---

### Scenarios

#### SCENARIO 1: Create a session with two rovers on a 5x5 plateau

**Scenario ID**: MISSION-STORY-001-S1

**GIVEN**
* No active session exists
* The player enters plateau upper-right coordinates `5 5`
* The player enters Rover 0 at position `1 2` heading `N`
* The player enters Rover 1 at position `3 3` heading `E`

**WHEN**
* The player submits the Plateau Form

**THEN**
* Assumption: The Frontend sends `POST /api/v1/session` with body `{ "plateau": { "width": 5, "height": 5 }, "rovers": [{ "x": 1, "y": 2, "heading": "N" }, { "x": 3, "y": 3, "heading": "E" }] }` to the API Gateway (Chapter 6.1 step 2 gives `{ plateau, rovers }` only; field names `width`, `height`, `x`, `y`, `heading` are not specified by the architecture)
* Assumption: The Mission Service responds HTTP 200 with the confirmed session containing `plateau`, `rovers`, and `history: []` (Chapter 6.1 step 5 confirms the frontend receives the confirmed session; response field names and HTTP 200 are not specified by the architecture)
* The Grid View renders a 5x5 grid with Rover 0 at `(1,2)` facing `N` and Rover 1 at `(3,3)` facing `E`

---

#### SCENARIO 2: Create a session replacing an existing session

**Scenario ID**: MISSION-STORY-001-S2

**GIVEN**
* An active session already exists (plateau `3 3`, one rover at `0 0 N`)

**WHEN**
* The player submits a new Plateau Form with plateau `5 5` and Rover 0 at `1 2 N`

**THEN**
* The Mission Service discards the previous session and saves the new one
* Assumption: The response contains the new session with `history: []` (response field name is not specified by the architecture)
* The Grid View shows only the new rover at `(1,2)` facing `N` on a 5x5 grid

---

#### SCENARIO 3: Reject session creation when two rovers share the same initial cell

**Scenario ID**: MISSION-STORY-001-S3

**GIVEN**
* The player enters plateau `5 5`
* The player enters Rover 0 at `2 2 N` and Rover 1 at `2 2 E` (same cell)

**WHEN**
* The player submits the Plateau Form

**THEN**
* The Mission Service returns HTTP 422
* Assumption: Response body is `{ "error": "OVERLAPPING_ROVERS", "detail": "Two or more rovers share the same initial cell" }` (the error code `OVERLAPPING_ROVERS` is from Chapter 8.3; the `detail` message text is not specified by the architecture)
* No session is created or overwritten
* The Frontend displays the `detail` string from the error body

---

#### SCENARIO 4: Reject session creation when a rover is placed outside the plateau

**Scenario ID**: MISSION-STORY-001-S4

**GIVEN**
* The player enters plateau `3 3`
* The player enters Rover 0 at `5 5 N` (outside the plateau boundary)

**WHEN**
* The player submits the Plateau Form

**THEN**
* The Mission Service returns HTTP 422
* Assumption: Response body is `{ "error": "ROVER_OUT_OF_BOUNDS", "detail": "Rover 0 position (5, 5) is outside the plateau (3, 3)" }` (Chapter 6.1 step 3 states this validation exists; Chapter 8.3 does not define an error code or message for this case - **Gap**: no named exception, error code, or `detail` message is specified in the architecture for a rover placed outside the plateau at session creation; an ADR or Chapter 8.3 update should define them)
* No session is created
* The Frontend displays the `detail` string from the error body

---

### Frontend Stories

#### MISSION-FE-001.1: Plateau Form collects and submits plateau and rover data

**Parent**: MISSION-STORY-001
**Component**: Plateau Form (05-building-block-view.md, Chapter 5.2)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): Plateau Form responsibility; `Plateau Form -> API Client -> POST /api/v1/session`
* Chapter 8.3 (08-cross-cutting-concepts.md): Frontend API Client surfaces `detail` field on non-2xx responses

AS A Player
I WANT a form that accepts plateau dimensions and one or more rover placements with headings
SO THAT I can submit all configuration in a single action and receive immediate feedback on errors

##### SCENARIO 1: Plateau Form submits valid data

**Scenario ID**: MISSION-FE-001.1-S1

**GIVEN**
* The Plateau Form is rendered and empty

**WHEN**
* The player enters `5 5` for the plateau, `1 2 N` for Rover 0, and `3 3 E` for Rover 1 and clicks Submit

**THEN**
* Assumption: The API Client is called with `POST /api/v1/session` and body `{ "plateau": { "width": 5, "height": 5 }, "rovers": [{ "x": 1, "y": 2, "heading": "N" }, { "x": 3, "y": 3, "heading": "E" }] }` (field names are not specified by the architecture; Chapter 6.1 step 2 gives `{ plateau, rovers }` only)
* The Grid View receives the confirmed rover states as props and renders two rover icons

##### SCENARIO 2: Plateau Form displays error when two rovers share the same cell

**Scenario ID**: MISSION-FE-001.1-S2

**GIVEN**
* The Plateau Form is rendered

**WHEN**
* The player submits two rovers at the same cell and the API Client returns a 422 response with `{ "error": "OVERLAPPING_ROVERS", "detail": "Two or more rovers share the same initial cell" }`

**THEN**
* The Plateau Form displays the text "Two or more rovers share the same initial cell"
* The form remains open and the player can correct the input

##### SCENARIO 3: Plateau Form displays error when a rover is placed outside the plateau

**Scenario ID**: MISSION-FE-001.1-S3

**GIVEN**
* The Plateau Form is rendered

**WHEN**
* The player submits Rover 0 at `5 5 N` with plateau `3 3` and the API Client returns a 422 response with Assumption: `{ "error": "ROVER_OUT_OF_BOUNDS", "detail": "Rover 0 position (5, 5) is outside the plateau (3, 3)" }` (error code and message are not defined by the architecture - Gap: see MISSION-STORY-001-S4)

**THEN**
* The Plateau Form displays the detail string from the error body
* The form remains open and the player can correct the input

---

#### MISSION-FE-001.2: Grid View renders the plateau grid with rover icons at initial positions

**Parent**: MISSION-STORY-001
**Component**: Grid View (05-building-block-view.md, Chapter 5.2)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): Grid View responsibility (purely presentational; renders from props passed by App)
* Chapter 6.1 (06-runtime-view.md): Frontend renders plateau grid with rover icons at step 0 after session creation

AS A Player
I WANT the plateau grid to show all rovers at their starting positions and headings after the session is created
SO THAT I can verify the placement is correct before issuing commands

##### SCENARIO 1: Grid View renders initial rover positions

**Scenario ID**: MISSION-FE-001.2-S1

**GIVEN**
* App state contains plateau `5 5`, Rover 0 at `(1,2)` heading `N`, Rover 1 at `(3,3)` heading `E`

**WHEN**
* Grid View renders with those props

**THEN**
* A 5x5 grid is visible
* Rover 0 icon appears in cell `(1,2)` oriented northward
* Rover 1 icon appears in cell `(3,3)` oriented eastward
* No other rover icons are present

##### SCENARIO 2: Grid View renders a single-rover session

**Scenario ID**: MISSION-FE-001.2-S2

**GIVEN**
* App state contains plateau `3 3`, one rover at `(0,0)` heading `S`

**WHEN**
* Grid View renders with those props

**THEN**
* A 3x3 grid is visible
* One rover icon appears in cell `(0,0)` oriented southward

---

### Backend Stories

#### MISSION-BE-001.1: Mission Service creates and stores a new session

**Parent**: MISSION-STORY-001
**Service**: Mission Service (`mission:8000`)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): Mission Service (app) orchestration; InMemorySessionRepository `save()`; `Session` aggregate root with `plateau`, `initial_rovers`, `rovers`, `history`
* Chapter 6.1 (06-runtime-view.md): Create Session walkthrough steps 3-5; step 3 states validation covers both overlap and out-of-bounds placement
* Chapter 8.2 (08-cross-cutting-concepts.md): Domain validation, `OverlappingRoversError`, `422`
* Chapter 8.3 (08-cross-cutting-concepts.md): Error handling table

AS A Developer
I WANT the Mission Service `POST /api/v1/session` endpoint to validate placement, create the Session aggregate, and store it via InMemorySessionRepository
SO THAT subsequent command and history requests operate on a consistent, correctly initialised session

##### SCENARIO 1: Endpoint creates session and returns confirmed state

**Scenario ID**: MISSION-BE-001.1-S1

**GIVEN**
* No active session in InMemorySessionRepository
* Assumption: Request body `{ "plateau": { "width": 5, "height": 5 }, "rovers": [{ "x": 1, "y": 2, "heading": "N" }, { "x": 3, "y": 3, "heading": "E" }] }` (field names are not specified by the architecture; Chapter 6.1 step 2 gives `{ plateau, rovers }` only)

**WHEN**
* `POST /api/v1/session` is called

**THEN**
* Assumption: HTTP 200 is returned (the architecture confirms the frontend receives a confirmed session in Chapter 6.1 step 5; the status code is not explicitly stated)
* Assumption: Response body contains `plateau`, `rovers` with two entries at the given positions and headings, and `history: []` (response field names are not specified by the architecture)
* InMemorySessionRepository stores a `Session` where `initial_rovers` equals `rovers` and `history` is empty

##### SCENARIO 2: Endpoint replaces existing session

**Scenario ID**: MISSION-BE-001.1-S2

**GIVEN**
* An active session exists in InMemorySessionRepository (plateau `3 3`, one rover at `0 0 N`)
* Assumption: Request body `{ "plateau": { "width": 5, "height": 5 }, "rovers": [{ "x": 1, "y": 2, "heading": "N" }] }` (field names are not specified by the architecture)

**WHEN**
* `POST /api/v1/session` is called

**THEN**
* Assumption: HTTP 200 is returned
* The new session replaces the previous one; InMemorySessionRepository holds only the new session data

##### SCENARIO 3: Endpoint rejects overlapping initial placements

**Scenario ID**: MISSION-BE-001.1-S3

**GIVEN**
* Assumption: Request body `{ "plateau": { "width": 5, "height": 5 }, "rovers": [{ "x": 2, "y": 2, "heading": "N" }, { "x": 2, "y": 2, "heading": "E" }] }` (field names are not specified by the architecture)

**WHEN**
* `POST /api/v1/session` is called

**THEN**
* HTTP 422 is returned
* Assumption: Response body is `{ "error": "OVERLAPPING_ROVERS", "detail": "Two or more rovers share the same initial cell" }` (error code from Chapter 8.3; `detail` message text is not specified by the architecture)
* InMemorySessionRepository is not modified

##### SCENARIO 4: Endpoint rejects a rover placed outside the plateau

**Scenario ID**: MISSION-BE-001.1-S4

**GIVEN**
* Assumption: Request body `{ "plateau": { "width": 3, "height": 3 }, "rovers": [{ "x": 5, "y": 5, "heading": "N" }] }` (field names are not specified by the architecture)

**WHEN**
* `POST /api/v1/session` is called

**THEN**
* HTTP 422 is returned
* Assumption: Response body is `{ "error": "ROVER_OUT_OF_BOUNDS", "detail": "Rover 0 position (5, 5) is outside the plateau (3, 3)" }` (Chapter 6.1 step 3 defines this validation; Chapter 8.3 does not define an error code, exception class, or message for this case - **Gap**: no named exception (`RoverOutOfBoundsError` or similar), error code, or `detail` message is specified for a rover placed outside the plateau at session creation; Chapter 8.3 should be extended or an ADR added)
* InMemorySessionRepository is not modified

---

### Infrastructure Stories

#### MISSION-INFRA-001.1: Deploy the Mission Service container

**Parent**: MISSION-STORY-001
**Service**: Mission Service (`mission`)
**Architecture references**:
* Chapter 7.1 (07-deployment-view.md): Containers and port mapping; `mission` Compose service, internal port 8000, not published to host; lists Dockerfile as `mission/Dockerfile`
* Chapter 7.3 (07-deployment-view.md): Microservice-to-container mapping; lists Dockerfile as `services/mission/Dockerfile`
* Chapter 8.5 (08-cross-cutting-concepts.md): Environment variables `LOG_LEVEL`, `COMMAND_SERVICE_URL`, `SIMULATION_SERVICE_URL`, `UVICORN_HOST`, `UVICORN_PORT`
* ADR-004 (09-architecture-decisions.md): Docker Compose for local orchestration; base image `python:3.12-slim`, uvicorn

**Gap**: Chapter 7.1 and Chapter 7.3 give different Dockerfile paths for the Mission Service (`mission/Dockerfile` vs `services/mission/Dockerfile`). The correct path must be confirmed and the architecture corrected to be consistent.

AS A Developer
I WANT the Mission Service to run as a Docker Compose service named `mission` on the internal network at `mission:8000`
SO THAT the API Gateway can route `/api/v1/session*` requests to it and no port is exposed directly to the host

##### SCENARIO 1: Mission Service starts and is reachable from the gateway

**Scenario ID**: MISSION-INFRA-001.1-S1

**GIVEN**
* `docker-compose.yml` defines the `mission` service with image built from the Dockerfile (path to be confirmed per Gap above), internal port 8000, and environment variables `LOG_LEVEL=INFO`, `COMMAND_SERVICE_URL=http://command:8001`, `SIMULATION_SERVICE_URL=http://simulation:8002`, `UVICORN_HOST=0.0.0.0`, `UVICORN_PORT=8000`
* Assumption: Request body `{ "plateau": { "width": 5, "height": 5 }, "rovers": [{ "x": 1, "y": 2, "heading": "N" }] }` is used for the probe call (field names are not specified by the architecture)

**WHEN**
* `docker compose up --build` is run

**THEN**
* The `mission` container starts without error
* `POST http://localhost:8080/api/v1/session` with the probe body returns HTTP 200, confirming the service is reachable on the internal network via the gateway

##### SCENARIO 2: Mission Service port is not exposed to the host

**Scenario ID**: MISSION-INFRA-001.1-S2

**GIVEN**
* Docker Compose is running with the `mission` service configured with no `ports` mapping

**WHEN**
* A request is made directly to `http://localhost:8000/api/v1/session` from the host machine

**THEN**
* The connection is refused, confirming no host port is published for the Mission Service

---

#### MISSION-INFRA-001.2: In-memory session data store (InMemorySessionRepository)

**Parent**: MISSION-STORY-001
**Service**: Mission Service (`mission`)
**Architecture references**:
* Chapter 5.2 (05-building-block-view.md): InMemorySessionRepository, process-scoped Python dict; SessionRepository port (ABC)
* ADR-005 (09-architecture-decisions.md): In-process memory as the only state store; state lost on container restart is accepted

AS A Developer
I WANT the Mission Service to store the active session in a process-scoped Python dict via InMemorySessionRepository
SO THAT session state is available within a process lifetime with no external dependency, and the port allows a future adapter substitution

##### SCENARIO 1: Session persists within a running container

**Scenario ID**: MISSION-INFRA-001.2-S1

**GIVEN**
* The `mission` container is running
* `POST /api/v1/session` has been called successfully with plateau `5 5` and one rover at `1 2 N`

**WHEN**
* `GET /api/v1/session/history` is called (routed through the gateway) on the same running container

**THEN**
* HTTP 200 is returned
* The response body contains a step history that is an empty list (`[]`), confirming the session was stored and the history is empty after creation with no commands submitted

##### SCENARIO 2: Session is lost after container restart

**Scenario ID**: MISSION-INFRA-001.2-S2

**GIVEN**
* A session exists in the running `mission` container

**WHEN**
* `docker compose restart mission` is run and the container comes back up

**THEN**
* `GET /api/v1/session/history` returns HTTP 404 with `{ "error": "SESSION_NOT_FOUND" }`, confirming in-memory state does not survive restarts (accepted per ADR-005)

---

#### MISSION-INFRA-001.3: No event bus (synchronous REST only)

**Parent**: MISSION-STORY-001
**Service**: Mission Service (`mission`)
**Architecture references**:
* ADR-009 (09-architecture-decisions.md): Synchronous REST for inter-service communication; no message broker

Not applicable. ADR-009 explicitly rejects a message broker for all inter-service communication. The Mission Service communicates with Command Service and Simulation Service via synchronous HTTP/JSON only. No event bus, queue, or broker container exists in the Docker Compose setup.

AS A Developer
I WANT to confirm that no message broker or event bus container is present in the Docker Compose stack
SO THAT the deployment stays within the five-container boundary defined by ADR-009 and no asynchronous messaging is introduced

##### SCENARIO 1: Session creation involves no asynchronous messaging

**Scenario ID**: MISSION-INFRA-001.3-S1

**GIVEN**
* The Docker Compose stack is running (five containers: `frontend`, `gateway`, `mission`, `command`, `simulation`)

**WHEN**
* `POST /api/v1/session` is called with valid data

**THEN**
* `docker compose ps` shows exactly five running containers with no broker container present
* The session creation response is returned synchronously within the same HTTP request-response cycle

---

#### MISSION-INFRA-001.4: Logging and health observability

**Parent**: MISSION-STORY-001
**Service**: Mission Service (`mission`)
**Architecture references**:
* Chapter 8.4 (08-cross-cutting-concepts.md): Logging policy; uvicorn access log to stdout; Mission Service logs "Session created/reset" at `INFO`; `LOG_LEVEL` env var; `docker compose logs`
* Chapter 10.2 (10-quality-requirements.md): QS-05 one-command startup; no health endpoint defined in the architecture (gap noted below)

AS A Developer
I WANT the Mission Service to emit structured log lines to stdout for each request and each session lifecycle event
SO THAT I can observe system behaviour using `docker compose logs mission` without any external tooling

**Gap**: The architecture (Chapters 5, 7, 8) does not define a `/health` endpoint for any service. No health endpoint is specified in this story. If one is required, an architecture change should be proposed and an ADR recorded.

##### SCENARIO 1: Session creation is logged at INFO level

**Scenario ID**: MISSION-INFRA-001.4-S1

**GIVEN**
* The `mission` container is running with `LOG_LEVEL=INFO`

**WHEN**
* `POST /api/v1/session` is called successfully

**THEN**
* `docker compose logs mission` shows a uvicorn access log line containing `POST /api/v1/session` and status `200`
* An application-level `INFO` log line contains the text "Session created" (Chapter 8.4 specifies "Session created/reset"; no additional fields such as plateau dimensions or rover count are defined by the architecture)

##### SCENARIO 2: Log level is controlled by environment variable

**Scenario ID**: MISSION-INFRA-001.4-S2

**GIVEN**
* `docker-compose.yml` sets `LOG_LEVEL=WARNING` for the `mission` service

**WHEN**
* `docker compose up` starts the container and `POST /api/v1/session` is called

**THEN**
* `docker compose logs mission` does not show `INFO`-level application log lines for the session creation event
* The uvicorn access log line is still present (uvicorn access log level is separate from the application log level)

---

### Implementation Order

1. MISSION-INFRA-001.1: Deploy Mission Service container (Docker Compose, ports, env vars; resolve Dockerfile path gap)
2. MISSION-INFRA-001.2: Implement InMemorySessionRepository and SessionRepository port
3. MISSION-INFRA-001.3: Confirm no event bus (verify Docker Compose service count)
4. MISSION-INFRA-001.4: Configure logging and confirm stdout output
5. MISSION-BE-001.1: Implement `POST /api/v1/session` endpoint with domain validation (overlap and out-of-bounds)
6. MISSION-FE-001.1: Implement Plateau Form with API Client call and error display (overlap, out-of-bounds)
7. MISSION-FE-001.2: Implement Grid View rendering initial rover positions
8. MISSION-STORY-001 end-to-end verification: Player submits Plateau Form, Mission Service creates session, Grid View renders initial positions (MISSION-STORY-001-S1)
