# 11. Risks and Technical Debts

## Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|-----------|
| R-01 | **Mission Service becomes a distributed monolith.** Because Mission Service orchestrates the other two services synchronously, it accumulates knowledge of their internals over time (e.g. interpreting downstream error bodies, duplicating domain types). | Medium | Medium | Enforce the HTTP contract as the only integration point; no Python types shared between services (ADR-008). Review service boundaries if Mission Service starts importing Command or Simulation domain types. |
| R-02 | **In-memory state lost on container restart.** A crash or `docker compose restart` wipes the active session, including the full step history. | High (certainty for any restart) | Low for a kata; High if used beyond local play | Acceptable per constraint (Chapter 2). If persistence is ever needed, the `SessionRepository` port (ADR-005) allows an adapter swap without touching domain or application logic. |
| R-03 | **Downstream service unavailability blocks a command.** If Command Service or Simulation Service is unreachable, Mission Service returns 503/502 and the player cannot submit commands. There is no retry or circuit-breaker mechanism. | Low (all containers on the same host) | Medium | Docker Compose `depends_on` with `condition: service_healthy` ensures services start in order. For a production scenario, a circuit-breaker (e.g. `tenacity` for retries) would be added to the HTTP Client. |
| R-04 | **nginx routing misconfiguration silently drops requests.** A wrong location block in `nginx.conf` returns 404 without an obvious error, which is hard to distinguish from a missing API endpoint. | Low | Medium | Cover gateway routing with at least one smoke test per upstream service in the inter-service contract test suite. |
| R-05 | **React state diverges from backend session state.** If the Frontend holds a stale copy of rover positions (e.g. after a failed request that was not surfaced to the player), the grid shows incorrect data. | Low | Medium | The API Client must treat every non-2xx response as an error and surface it; the Frontend must not update local state until the backend confirms success. Covered by Frontend integration tests with mocked error responses. |

---

## Technical Debts

| # | Debt | Impact | Condition for paying it down |
|---|------|--------|------------------------------|
| D-01 | **No persistent storage.** Session state is lost on restart. The `SessionRepository` port exists but only an in-memory adapter is implemented. | Low for a kata; blocks any real-world use | Implement a file-based or SQLite adapter for `SessionRepository` when persistence is required. |
| D-02 | **No inter-service retries or circuit breaker.** The HTTP Client in Mission Service makes a single attempt and propagates failures immediately. | Low on a single host; becomes a reliability risk in any networked deployment | Add `tenacity`-based retry logic and a circuit-breaker pattern to the HTTP Client if the system moves beyond localhost. |
| D-03 | **Single active session, no session ID.** The API has no session identifier in the URL path; only one session can exist at a time. | Blocks multi-user or multi-tab use | Add a `session_id` to the URL path and change `InMemorySessionRepository` to a dict keyed by ID. No domain changes are required. |
| D-04 | **No end-to-end tests.** The test pyramid covers domain unit, API integration, and inter-service contract layers, but no browser-level (Playwright/Cypress) tests exist. | Low for a kata; means UI regressions are caught later | Add a minimal Playwright smoke test (create session, submit commands, verify grid) once the implementation is stable. |
| D-05 | **Frontend has no loading or error state design.** The UI specification covers the happy path; error and loading states are handled generically ("Cannot reach server"). | Low for local use; degrades usability under slow startup or partial failure | Define explicit loading spinners and per-field error displays once the happy-path UI is implemented. |
