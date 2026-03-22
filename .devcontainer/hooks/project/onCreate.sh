#!/bin/bash
# =============================================================================
# n8n project hook: onCreate
# =============================================================================
# Called by lifecycle/onCreate.sh after the image-embedded hook (if any).
# Handles n8n-specific setup: pnpm install, turbo cache, etc.
# =============================================================================

set -e

echo "[n8n] Setting up development environment..."

cd /workspace

# Activate pnpm via corepack
corepack prepare --activate 2>/dev/null || true

# Install dependencies
if [ -f "pnpm-lock.yaml" ]; then
    echo "[n8n] Installing dependencies with pnpm..."
    pnpm install --frozen-lockfile 2>&1 | tail -5
    echo "[n8n] Dependencies installed."
else
    echo "[n8n] No pnpm-lock.yaml found, skipping install."
fi

echo "[n8n] Dev environment ready. Run 'pnpm build' then 'pnpm dev' to start."
