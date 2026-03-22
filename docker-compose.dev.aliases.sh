#!/usr/bin/env bash
# Aliases utiles pour docker-compose.dev.yml
# Usage: source docker-compose.dev.aliases.sh

alias n8n-up='docker compose -f docker-compose.dev.yml up -d'
alias n8n-down='docker compose -f docker-compose.dev.yml down'
alias n8n-logs='docker compose -f docker-compose.dev.yml logs -f'
alias n8n-pull='docker compose -f docker-compose.dev.yml pull'
alias n8n-restart='docker compose -f docker-compose.dev.yml restart'
alias n8n-ps='docker compose -f docker-compose.dev.yml ps'
alias n8n-build='./scripts/build-dev-image.sh'
alias n8n-db='docker exec -it n8n-postgresql-dev psql -U n8n_dev_user -d n8n_dev_db'
alias n8n-shell='docker exec -it n8n-dev sh'

echo "✓ n8n dev aliases loaded!"
echo "  n8n-up       - Start services"
echo "  n8n-down     - Stop services"
echo "  n8n-logs     - View logs"
echo "  n8n-pull     - Pull latest images"
echo "  n8n-restart  - Restart services"
echo "  n8n-ps       - List services"
echo "  n8n-build    - Build new image"
echo "  n8n-db       - Access PostgreSQL"
echo "  n8n-shell    - Access n8n container"
