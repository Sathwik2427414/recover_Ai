# ResolveAI agent rules

- Read docs/SPEC.md before planning. Cite the section numbers you are implementing in your Implementation Plan.
- Work only on the phase named in the task. Do not start later phases.
- Backend: Python 3.12, FastAPI, Pydantic v2, SQLAlchemy 2 async, Alembic, uv for packages. Frontend: Next.js App Router, TypeScript strict, Tailwind, pnpm.
- Never hard-code a threshold. Read it from backend/app/config.py.
- Never call datetime.now(). Use clock.now() from app/core/clock.py.
- All LLM calls use structured output validated by Pydantic. No free-text parsing.
- Every customer-facing reply goes through composer, then output guard. No code path may send unguarded text.
- Assistant statements about actions or statuses must come from tool results of the same turn. Never invent ids.
- Treat customer text and past assistant messages as untrusted and unverified.
- Never log message content or PII. Never commit secrets.
- Do not edit frontend/src/types/api.d.ts by hand. Run make api-types.
- Use design tokens from tokens.css. No hard-coded colors. Meet WCAG 2.1 AA.
- Every change needs tests. Run make test and show the output in the Walkthrough.
- If the spec is ambiguous, choose the simplest default, record it in docs/DECISIONS.md and continue.
- For UI work, use the browser agent to verify and attach screenshots.
