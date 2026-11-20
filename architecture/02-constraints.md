# 2. Constraints

## 2.1 Technical Constraints

| Constraint | Explanation |
|------------|-------------|
| Python 3.12+ for the backend | The domain model and API must be implemented in Python; no other backend language is permitted |
| FastAPI as the web framework | Chosen for async support, automatic OpenAPI docs, and Pydantic-based validation; the domain core must remain framework-independent |
| React (TypeScript) for the frontend | The UI is a single-page application; no server-side rendering |
| Docker Compose for local orchestration | The entire system (backend + frontend) must start with `docker compose up`; no Kubernetes or cloud infrastructure |
| No external database | State is held in memory for the lifetime of the backend process; persistence across restarts is out of scope for this kata |
| No authentication or authorisation | The system is local-only; there are no user accounts, tokens, or access control |

## 2.2 Organisational Constraints

| Constraint | Explanation |
|------------|-------------|
| Single developer | Developer is the sole implementer; architectural complexity must stay proportionate to this team size |
| Academic context | The project is assessed by Course Reviewer; documented decisions and testability are evaluation criteria |
| TDD discipline | Implementation must follow test-driven development; tests are written before the production code they cover |
| English documentation | All architecture documents, ADRs, code comments, and API contracts are written in English |

## 2.3 Conventions

| Convention | Explanation |
|------------|-------------|
| arc42 documentation structure | All architecture documentation follows the arc42 template, one file per chapter |
| C4 model for diagrams | Architecture diagrams use C4 notation (Context, Container, Component, Deployment) rendered as PlantUML |
| ADR format for decisions | Every hard-to-reverse technology or design decision is recorded as an ADR in Chapter 9 |
| REST over HTTP/JSON | All client-server communication uses REST with JSON payloads; no GraphQL or gRPC for this scope |
| API versioning in the URL path (`/api/v1/...`) | The API version is prefixed in the base path to allow future breaking changes without coupling |
