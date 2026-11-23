.PHONY: up down seed seed-local test eval eval-local api-types lint format migrate logs clean test-backend test-frontend test-e2e lint-backend lint-frontend logs-backend health demo

up:
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v

migrate:
	docker compose exec backend alembic upgrade head

seed:
	docker compose exec backend python -m app.mock_business.seed

seed-local:
	cd backend && python -m app.mock_business.seed

demo: up migrate seed
	@echo "Demo ready at http://localhost:3000"

test: test-backend test-frontend

test-backend:
	cd backend && uv run pytest tests/ -v --tb=short

test-frontend:
	cd frontend && pnpm test

test-e2e:
	cd frontend && pnpm exec playwright test

api-types:
	cd frontend && pnpm exec openapi-typescript http://localhost:8000/openapi.json -o src/types/api.d.ts

eval:
	cd backend && uv run python eval/run_eval.py

lint-backend:
	cd backend && uv run ruff check app/ tests/
	cd backend && uv run mypy app/

lint-frontend:
	cd frontend && pnpm lint
	cd frontend && pnpm type-check

lint: lint-backend lint-frontend

format:
	cd backend && uv run ruff format app/ tests/

logs:
	docker compose logs -f

logs-backend:
	docker compose logs -f backend

health:
	curl -s http://localhost:8000/healthz

