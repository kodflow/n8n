# =============================================================================
# n8n Development Container
# =============================================================================
# Based on kodflow devcontainer-template (Zsh, P10k, Claude Code, grepai, rtk)
# Node.js added via devcontainer feature (see devcontainer.json)
# Adds n8n-specific system dependencies (graphicsmagick, postgresql-client)
# =============================================================================

FROM ghcr.io/kodflow/devcontainer-template:latest

USER root

# n8n-specific system dependencies (build-essential + python3 already in base)
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphicsmagick \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

USER vscode
