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
# Docker CLI for Docker-outside-of-Docker (uses host Docker via socket mount)
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphicsmagick \
    postgresql-client \
    docker.io \
    && rm -rf /var/lib/apt/lists/* \
    && usermod -aG docker vscode

USER vscode
