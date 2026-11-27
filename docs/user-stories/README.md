# User Stories: Mars Rover Kata

## Bounded Contexts

| Domain | Service | Responsibility | Architecture reference |
|--------|---------|----------------|------------------------|
| MISSION | Mission Service | Orchestrates end-to-end mission execution; holds the in-memory session (plateau, rovers, step history); calls Command Service and Simulation Service | Chapter 5.1, 5.2 (05-building-block-view.md) |
| COMMAND | Command Service | Parses raw command strings into ordered `Operation` lists; rejects unknown characters with `UnknownCommandError` | Chapter 5.1, 5.2 (05-building-block-view.md) |
| SIMULATION | Simulation Service | Applies a single `Operation` to a `Rover` given `Plateau` dimensions and occupied positions; returns new rover state or `CommandRejection` | Chapter 5.1, 5.2 (05-building-block-view.md) |

## Supporting Containers

| Container | Technology | Ports (host:internal) | Responsibility |
|-----------|------------|----------------------|----------------|
| Frontend | React 18, TypeScript, Vite, nginx | 3000:80 | Renders plateau grid and rover icons; collects player input; drives step-by-step replay |
| API Gateway | nginx | 8080:80 | Single entry point; routes `/api/v1/session*` to `mission:8000`, `/api/v1/commands*` to `command:8001`, `/api/v1/simulation*` to `simulation:8002` |

---

## Story Inventory

| ID | Title | Domain | Features | Priority | Status | File |
|----|-------|--------|----------|----------|--------|------|
| MISSION-STORY-001 | Create a session | MISSION | F-1, F-2, F-6 | Core | Approved | [mission.md](mission.md) |
| COMMAND-STORY-001 | Submit a command string | COMMAND | F-3 | Supporting | Approved | [command.md](command.md) |
| SIMULATION-STORY-001 | Rover turns and moves, final position reported | SIMULATION | F-3, F-5, F-6 | Core | Approved | [simulation.md](simulation.md) |
| COMMAND-STORY-002 | Reject unknown command characters | COMMAND | F-3 | Supporting | Approved | [command.md](command.md) |
| SIMULATION-STORY-002 | Reject out-of-bounds moves | SIMULATION | F-4 | Supporting | Approved | [simulation.md](simulation.md) |
| SIMULATION-STORY-003 | Reject collision moves | SIMULATION | F-4 | Supporting | Not started | [simulation.md](simulation.md) |
| MISSION-STORY-002 | Reject overlapping initial rover placement | MISSION | F-2 | Supporting | Not started | [mission.md](mission.md) |
| MISSION-STORY-003 | Step-by-step replay | MISSION | F-7 | Supporting | Not started | [mission.md](mission.md) |
| MISSION-STORY-004 | Reset the session | MISSION | F-1 | Supporting | Not started | [mission.md](mission.md) |

---

## Pareto Progress

```
Pareto Progress: 2/2 core stories (2 of 9 stories are Core, 22%)
Core functionality coverage: ~80% of 80% target
Supporting stories approved: 3/7 (COMMAND-STORY-001, COMMAND-STORY-002, SIMULATION-STORY-002)
```

---

## Core path prerequisites

SIMULATION-STORY-001 is Core but depends on COMMAND-STORY-001, which is now Supporting. This dependency is not hidden: SIMULATION-STORY-001 relies on COMMAND-BE-001.1 (parse endpoint) and COMMAND-BE-001.2 (Mission Service parse phase), so those two sub-stories must be implemented together with the core stories. The Pareto split counts stories, not sub-stories.

---

## Implementation Order

### Core stories (dependency order)
1. MISSION-STORY-001: Create a session (no dependencies)
2. SIMULATION-STORY-001: Rover turns and moves (depends on MISSION-STORY-001; requires COMMAND-BE-001.1 and COMMAND-BE-001.2, see Core path prerequisites)

### Supporting stories (by value)
3. COMMAND-STORY-001: Submit a command string (COMMAND-BE-001.1 and COMMAND-BE-001.2 are core path prerequisites)
4. COMMAND-STORY-002: Reject unknown command characters
5. SIMULATION-STORY-002: Reject out-of-bounds moves
6. SIMULATION-STORY-003: Reject collision moves
7. MISSION-STORY-002: Reject overlapping initial rover placement
8. MISSION-STORY-003: Step-by-step replay
9. MISSION-STORY-004: Reset the session
