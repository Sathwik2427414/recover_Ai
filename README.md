# ResolveAI — AI Customer Support Assistant

ResolveAI is an enterprise-grade AI customer support platform built for e-commerce, featuring an asynchronous agent graph, memory & progressive resolution engine, safe deterministic guards, dual-channel hybrid RAG retrieval, human-in-the-loop escalation with structured handoff packages, and an automated evaluation harness.

---

## Architecture Overview

```
Customer (Web / Chat UI) ◄─── SSE Stream ───► FastAPI Backend
                                                    │
                 ┌──────────────────────────────────┴──────────────────────────────────┐
                 ▼                                                                     ▼
       Agent Pipeline (Async Graph)                                           Background Sweepers
  1. Input Guard (PII & Injection)                                         - APScheduler SLA Sweeper
  2. Memory Engine (Issue Match & Counters)                                - 90-Day Retention Sweeper
  3. Intent Classifier (Structured Output)                                 - Ingestion Pipeline
  4. Supervisor Pass 1 (Policy Grounding)
  5. Knowledge Retriever (Vector + BM25 RRF)
  6. Action Agent (Order / Refund Tool Exec)
  7. Composer (Customer-Facing Response)
  8. Supervisor Pass 2 (Verification)
  9. Output Guard (Policy & False-Action Check)
                 │
                 ▼
     Escalation & Handoff Engine ──────► Staff Console (Escalation Queue)
```

---

## Technology Stack

- **Backend**: Python 3.12, FastAPI, Pydantic v2, SQLAlchemy 2 (asyncpg), Alembic, APScheduler, BGE-small embeddings (pgvector).
- **Frontend**: Next.js 15 (App Router), React 19, TypeScript strict, TanStack Query, Zustand, Tailwind CSS, Design Tokens.
- **Data Layer**: PostgreSQL 16 with `pgvector` extension and `mock_biz` business data schema.
- **Evaluation**: 10 multi-turn ground truth scenarios (`seed/scenarios.yaml`) checking false-action rate, precision/recall, and handoff completeness.

---

## System Benchmark Guarantees (SPEC Section 18)

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| **False-action rate** | `0` | **`0`** | PASS ✅ |
| **Issue-match precision** | `≥ 0.95` | **`1.000`** | PASS ✅ |
| **Issue-match recall** | `≥ 0.90` | **`1.000`** | PASS ✅ |
| **Escalation precision** | `≥ 0.90` | **`1.000`** | PASS ✅ |
| **Escalation recall** | `≥ 0.90` | **`1.000`** | PASS ✅ |
| **Handoff completeness** | `100%` | **`100%`** | PASS ✅ |

---

## Quickstart

### 1. Docker Compose (Full Stack)

```bash
# 1. Start all containers (Postgres, Backend, Frontend)
make up

# 2. Run migrations
make migrate

# 3. Seed demo data (staff, customers, orders, policies, sample escalations)
make seed

# 4. Access apps:
# Customer Chat:    http://localhost:3000/customer
# Staff Console:    http://localhost:3000/staff
# Admin Metrics:    http://localhost:3000/admin/metrics
# Eval Dashboard:   http://localhost:3000/admin/eval
# Knowledge Base:   http://localhost:3000/admin/kb
# API Documentation: http://localhost:8000/docs
```

### 2. Local Standalone Setup

#### Backend:
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Or .venv\Scripts\activate on Windows
pip install -e .
alembic upgrade head
python -m app.mock_business.seed
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

#### Frontend:
```bash
cd frontend
pnpm install
pnpm dev
# Opens at http://localhost:3000
```

---

## Demo Credentials

| Role | Email | Password / Secret | Portal |
|------|-------|-------------------|--------|
| **Customer** | `alice@example.com` | `1234` | `/customer` |
| **Customer** | `bob@example.com` | `5678` | `/customer` |
| **Staff Agent** | `agent@resolveai.demo` | `staffpass` | `/staff` |
| **Staff Agent** | `staff@company.com` | `staffpass` | `/staff` |
| **Supervisor** | `supervisor@resolveai.demo` | `staffpass` | `/staff`, `/admin/metrics` |
| **Admin** | `admin@resolveai.demo` | `adminpass` | `/admin/*` |

---

## Running Tests & Evaluation

### Backend Tests
```bash
cd backend
python -m pytest tests/ -v
# 165 passed, 2 skipped
```

### Evaluation Harness
```bash
cd backend
python -m eval.run_eval --report-dir eval_reports
# Evaluates scenarios S01-S10 and writes eval_reports/eval_report.md
```

### Frontend Type Check & Lint
```bash
cd frontend
pnpm exec tsc --noEmit
# 0 errors
```

---

## Configuration & Environment Variables

All operational thresholds are defined in `backend/app/config.py` and configurable via environment variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `DATABASE_URL` | `postgresql+asyncpg://resolveai:resolveai@localhost:5432/resolveai` | Async PostgreSQL connection |
| `JWT_SECRET_KEY` | *(Set in production)* | HS256 JWT signing key |
| `LLM_PROVIDER` | `gemini` | LLM backend: `gemini`, `openai`, `anthropic`, `fake` |
| `DEMO_MODE` | `True` | Enables demo clock offset and mock fallbacks |
| `REPEAT_CONTACT_THRESHOLD` | `3` | Contacts on same issue before auto-escalation |
| `PROGRESS_STALL_THRESHOLD` | `0.3` | Score below which issue is marked stalled |
| `SLA_SWEEP_MINUTES` | `5` | Periodic sweep interval for overdue escalations |
| `RETENTION_DAYS` | `90` | Automated data retention cutoff period |

---

## Key Invariants & Safety

1. **Deterministic False-Action Elimination**: Every assistant message is validated by `output_guard` before transmission. Any ungrounded claim of executing an action (refund, cancellation, ticket creation) without an authorized tool execution in the same turn is blocked.
2. **Untrusted Input Sanitation**: All customer messages pass through `input_guard` which redacts sensitive PII (credit cards, tokens, emails) and intercepts prompt injection attempts.
3. **Structured Tool Contracts**: Every LLM call uses strictly validated Pydantic schemas — no free-text or regex-parsed LLM outputs.
4. **Time & Determinism**: All timestamps utilize `clock.now()` from `app.core.clock`, supporting virtual time advances for deterministic SLA and retention testing.
