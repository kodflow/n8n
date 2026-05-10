.PHONY: install build compile docker run stop clean

IMAGE_NAME := ghcr.io/kodflow/n8n
IMAGE_TAG  := latest
SENTINEL   := node_modules/.install-done
COMPILED   := compiled/.build-done

# 1. Install JS dependencies
install: $(SENTINEL)

$(SENTINEL): pnpm-lock.yaml package.json
	CI=1 pnpm install
	@touch $(SENTINEL)

# 2. Build all packages (TypeScript compilation)
build: install
	pnpm build > build.log 2>&1
	@tail -n 20 build.log

# 3. Compile n8n into ./compiled/ (self-contained bundle)
compile: build
	CI=1 node scripts/build-n8n.mjs
	@touch $(COMPILED)

# 4. Build Docker image locally (with BuildKit cache)
docker: compile
	DOCKER_BUILDKIT=1 docker build \
		-f docker/images/n8n/Dockerfile.kodflow \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		.

# 5. Run n8n + postgres locally
run:
	docker compose -f compose.yml up -d
	@echo ""
	@echo "n8n running at http://localhost:5678"
	@echo "PostgreSQL at localhost:5432"

# Stop local services
stop:
	docker compose -f compose.yml down

# Dev mode (hot reload, no Docker)
dev: install
	pnpm dev

# Full local test: build image then run
all: docker run

# Clean everything
clean:
	docker compose -f compose.yml down -v 2>/dev/null || true
	rm -rf compiled build.log $(COMPILED)
	pnpm store prune
