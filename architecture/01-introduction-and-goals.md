# 1. Introduction and Goals

## 1.1 Requirements Overview

The Mars Rover system allows users to deploy and command one or more rovers on a rectangular Martian plateau via a web interface.

**Core problem:** Given a plateau grid and a set of rovers with initial positions and orientations, the system must accept movement command sequences and report each rover's final position and heading, without rovers colliding or falling off the plateau edge.

**Key features:**

| # | Feature | Description |
|---|---------|-------------|
| F-1 | Plateau configuration | Define a rectangular plateau by its upper-right coordinates (lower-left is always 0,0) |
| F-2 | Rover deployment | Place one or more rovers on the plateau with an initial position (x, y) and heading (N, E, S, W) |
| F-3 | Command execution | Send a command string per rover (`L` = turn left 90°, `R` = turn right 90°, `M` = move one step forward) |
| F-4 | Collision detection | Reject any move that would take a rover out of bounds or onto another rover's position |
| F-5 | State reporting | Return each rover's current position and heading after commands are applied |
| F-6 | Visual grid | Display the plateau and all rovers in real time on a browser-based grid UI |
| F-7 | Step-by-step replay | Allow the user to replay commands one step at a time to observe movement |

**Example (from the kata):**

```
Plateau: 5 5
Rover 1: 1 2 N  →  commands LMLMLMLMM  →  result 1 3 N
Rover 2: 3 3 E  →  commands MMRMMRMRRM →  result 5 1 E
```

## 1.2 Quality Goals

Ordered by priority for this system:

| Priority | Quality Goal | Motivation |
|----------|-------------|------------|
| 1 | **Correctness** | Rover movement logic must exactly match the kata rules; wrong output defeats the purpose |
| 2 | **Usability** | The grid UI must make it immediately obvious what a rover is doing and where it ends up |
| 3 | **Testability** | The domain logic must be unit-testable in isolation, with no framework dependencies |
| 4 | **Simplicity** | Local-only deployment; no cloud, no auth, no over-engineering |
| 5 | **Extensibility** | The domain model should allow adding new command types or multiple rovers without structural changes |

## 1.3 Stakeholders

| Role | Group / Audience | Expectations |
|------|-----------------|--------------|
| **Developer** | Development team | Clean domain model that is easy to extend; architecture decisions are explicit and traceable; the domain core can be tested without starting a server or a browser |
| **Evaluator / Reviewer** | Course reviewers | Bounded contexts are clearly separated; every hard-to-reverse decision has a written rationale (ADR); test coverage covers at least the domain and API layers; the codebase follows TDD principles |
| **Player** | Local users | The app starts with a single `docker compose up`; the UI makes it obvious where each rover is and what it did; invalid input produces a clear error message rather than a silent failure |
