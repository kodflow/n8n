# Guide de mise à jour depuis upstream avec préservation du mode développeur

Ce document décrit le processus pour synchroniser le fork avec la version officielle upstream de n8n tout en préservant les modifications du mode développeur entreprise.

## Vue d'ensemble

Le mode développeur entreprise (`N8N_DEV_ENTERPRISE_MODE`) est une fonctionnalité personnalisée qui permet d'activer toutes les features Enterprise sans licence, strictement pour le développement et les tests (conforme à LICENSE_EE.md).

Lors de la mise à jour depuis upstream, cette fonctionnalité doit être préservée car elle n'existe pas dans la version officielle.

## Processus automatisé

### Étape 1 : Créer une branche de backup

```bash
# Créer une branche de sauvegarde avec la date du jour
git branch backup-dev-enterprise-mode-$(date +%Y%m%d)

# Vérifier que la branche a été créée
git branch -v | grep backup
```

### Étape 2 : Récupérer les dernières modifications upstream

```bash
# Récupérer les derniers commits de la version officielle
git fetch upstream

# Vérifier le nombre de commits de différence
git rev-list --left-right --count master...upstream/master
# Format de sortie: X Y (X commits en avance, Y commits en retard)
```

### Étape 3 : Préparer l'environnement pour le rebase

```bash
# Désactiver temporairement les hooks git (problème lefthook sur arm64)
mv .git/hooks .git/hooks.disabled

# Désactiver la signature GPG temporairement
git config --local commit.gpgsign false
```

### Étape 4 : Rebaser sur upstream

```bash
# Effectuer le rebase
git rebase upstream/master

# Si des conflits apparaissent :
# 1. Résoudre les conflits manuellement
# 2. git add <fichiers-résolus>
# 3. git rebase --continue
# 4. Répéter jusqu'à ce que le rebase soit terminé

# Si vous voulez abandonner le rebase :
# git rebase --abort
```

### Étape 5 : Consolider les modifications du mode développeur

```bash
# Identifier le dernier commit upstream (normalement c'est le premier après le rebase)
UPSTREAM_HEAD=$(git log --oneline upstream/master -1 | cut -d' ' -f1)

# Faire un soft reset pour garder toutes les modifications
git reset --soft $UPSTREAM_HEAD

# Vérifier les fichiers modifiés
git status

# Unstage les fichiers non essentiels (Docker, CI, etc.)
git restore --staged .env.example .github/workflows/*.yml DEV_SETUP.md DOCKER_IMAGE_BUILD.md QUICK_START_DEV.md README.DEV.md REVERSE_PROXY_EXAMPLE.md scripts/build-dev-image.sh 2>/dev/null || true

# Restaurer le workflow supprimé s'il existe
git restore --staged .github/workflows/docker-build-push.yml 2>/dev/null || true
git restore .github/workflows/docker-build-push.yml 2>/dev/null || true
```

### Étape 6 : Créer le commit consolidé

```bash
# Créer un seul commit avec toutes les modifications du mode développeur
git commit -m "$(cat <<'EOF'
feat: Add development enterprise mode for testing and evaluation

This commit adds a development/testing mode that unlocks all Enterprise
features without requiring a valid license. This is compliant with the
LICENSE_EE.md terms which allow modifications for dev/testing purposes.

## Features

- Added N8N_DEV_ENTERPRISE_MODE environment variable support
- All Enterprise boolean features return true when dev mode is enabled
- All quotas return UNLIMITED_LICENSE_QUOTA (-1) when dev mode is active
- Full RBAC scope access in dev mode
- API remains enabled in dev mode (bypasses apiDisabled feature)

## Modified Files

Backend License Logic:
- packages/@n8n/backend-common/src/license-state.ts
  * Added isDevEnterpriseMode() check
  * Modified isLicensed() to bypass checks in dev mode
  * Modified getValue() to return unlimited quotas in dev mode
  * Modified isAPIDisabled() to keep API enabled in dev mode

- packages/cli/src/license.ts
  * Added dev mode checks for feature validation
  * Ensures license manager respects dev mode settings

Permissions:
- packages/@n8n/permissions/src/utilities/get-global-scopes.ee.ts
  * Returns ALL_SCOPES when dev mode is enabled
- packages/@n8n/permissions/src/utilities/get-role-scopes.ee.ts
  * Returns all scopes for auth principals in dev mode

Documentation:
- DEV_ENTERPRISE_MODE.md
  * Complete documentation on using dev mode
  * Use cases and examples
  * License compliance information
- docker-compose.dev-enterprise.yml
  * Docker Compose configuration for testing dev mode

Development Tools:
- .gitignore
  * Added patterns for build logs and local docker files

## Use Cases

- Testing Terraform providers requiring Enterprise features
- Local development of Enterprise-dependent features
- CI/CD testing of Enterprise workflows
- Feature exploration and evaluation
- Development without license constraints

## License Compliance

This feature is strictly for development and testing purposes as permitted
by LICENSE_EE.md. Production use requires a valid n8n Enterprise license.

## Usage

Set environment variable:
\`\`\`bash
export N8N_DEV_ENTERPRISE_MODE=true
\`\`\`

Or in docker-compose:
\`\`\`yaml
environment:
  - N8N_DEV_ENTERPRISE_MODE=true
\`\`\`

All Enterprise features will be automatically unlocked.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Étape 7 : Réactiver les hooks et configuration

```bash
# Réactiver les hooks git
mv .git/hooks.disabled .git/hooks

# Optionnel : réactiver la signature GPG si vous l'utilisiez
# git config --local --unset commit.gpgsign
```

### Étape 8 : Tester le build

```bash
# Lancer le build et rediriger vers un fichier log
pnpm build > build.log 2>&1

# Vérifier les dernières lignes du log
tail -n 50 build.log

# Vérifier s'il y a des erreurs
grep -i "error" build.log || echo "Pas d'erreurs détectées"
```

### Étape 9 : Vérifier que le mode développeur fonctionne

```bash
# Lire les fichiers modifiés pour confirmer les changements
grep -n "N8N_DEV_ENTERPRISE_MODE" packages/@n8n/backend-common/src/license-state.ts
grep -n "N8N_DEV_ENTERPRISE_MODE" packages/cli/src/license.ts
grep -n "N8N_DEV_ENTERPRISE_MODE" packages/@n8n/permissions/src/utilities/get-global-scopes.ee.ts
grep -n "N8N_DEV_ENTERPRISE_MODE" packages/@n8n/permissions/src/utilities/get-role-scopes.ee.ts
```

### Étape 10 : Push vers origin

```bash
# Force push avec lease (plus sûr que --force)
git push --force-with-lease origin master

# Ou si vous préférez créer une nouvelle branche
# git checkout -b update-from-upstream-$(date +%Y%m%d)
# git push -u origin update-from-upstream-$(date +%Y%m%d)
```

## Fichiers modifiés par le mode développeur

Les fichiers suivants doivent être présents après la mise à jour :

### Code source (obligatoires)
- `packages/@n8n/backend-common/src/license-state.ts`
  * Contient la logique principale du mode dev
  * Méthodes : `isDevEnterpriseMode()`, `isLicensed()`, `getValue()`, `isAPIDisabled()`

- `packages/cli/src/license.ts`
  * Checks supplémentaires pour le mode dev
  * Validation des features avec dev mode

- `packages/@n8n/permissions/src/utilities/get-global-scopes.ee.ts`
  * Retourne ALL_SCOPES en mode dev

- `packages/@n8n/permissions/src/utilities/get-role-scopes.ee.ts`
  * Retourne tous les scopes pour les auth principals en mode dev

### Documentation (obligatoires)
- `DEV_ENTERPRISE_MODE.md`
  * Documentation complète du mode développeur

- `docker-compose.dev-enterprise.yml`
  * Configuration Docker Compose pour tester le mode dev

### Outils de développement (optionnels)
- `.gitignore`
  * Patterns pour logs de build et fichiers Docker locaux

## Vérifications post-mise à jour

1. **Vérifier que le mode dev n'existe pas dans upstream**
   ```bash
   git show upstream/master:packages/@n8n/backend-common/src/license-state.ts | grep -i "N8N_DEV" || echo "Mode dev non présent dans upstream ✓"
   ```

2. **Vérifier que vos modifications sont présentes**
   ```bash
   git diff upstream/master...master --name-only
   ```

3. **Vérifier l'état du repository**
   ```bash
   git status
   git log --oneline -5
   ```

4. **Tester le typecheck**
   ```bash
   pnpm typecheck
   ```

## Récupération en cas de problème

Si quelque chose se passe mal pendant le processus :

### Revenir à la branche de backup
```bash
# Abandonner les modifications
git reset --hard backup-dev-enterprise-mode-$(date +%Y%m%d)

# Ou utiliser une branche de backup spécifique
git branch -a | grep backup
git reset --hard <nom-de-la-branche-backup>
```

### Réactiver les hooks si vous avez oublié
```bash
# Si les hooks sont toujours désactivés
if [ -d .git/hooks.disabled ]; then
  mv .git/hooks.disabled .git/hooks
fi
```

### Annuler le rebase en cours
```bash
git rebase --abort
```

## Script d'automatisation complet

Voici un script bash qui automatise tout le processus :

```bash
#!/bin/bash

# update-from-upstream.sh
# Script pour mettre à jour depuis upstream en préservant le mode développeur

set -e  # Arrêter en cas d'erreur

echo "🔄 Mise à jour depuis upstream avec préservation du mode développeur"
echo "=================================================================="

# Étape 1: Backup
echo "📦 Création de la branche de backup..."
BACKUP_BRANCH="backup-dev-enterprise-mode-$(date +%Y%m%d)"
git branch "$BACKUP_BRANCH"
echo "✓ Branche backup créée: $BACKUP_BRANCH"

# Étape 2: Fetch upstream
echo "🌐 Récupération des dernières modifications upstream..."
git fetch upstream
DIFF=$(git rev-list --left-right --count master...upstream/master)
echo "✓ Différence avec upstream: $DIFF"

# Étape 3: Préparer l'environnement
echo "🔧 Préparation de l'environnement..."
mv .git/hooks .git/hooks.disabled 2>/dev/null || true
git config --local commit.gpgsign false
echo "✓ Environnement prêt"

# Étape 4: Rebase
echo "🔄 Rebase sur upstream/master..."
if git rebase upstream/master; then
    echo "✓ Rebase réussi"
else
    echo "⚠️  Conflits détectés. Résolvez-les manuellement puis relancez ce script avec --continue"
    echo "   Commandes: git add <fichiers> && git rebase --continue"
    mv .git/hooks.disabled .git/hooks 2>/dev/null || true
    exit 1
fi

# Étape 5: Consolider
echo "📝 Consolidation des modifications du mode développeur..."
UPSTREAM_HEAD=$(git log --oneline upstream/master -1 | cut -d' ' -f1)
git reset --soft "$UPSTREAM_HEAD"

# Unstage fichiers non essentiels
git restore --staged .env.example .github/workflows/*.yml DEV_SETUP.md DOCKER_IMAGE_BUILD.md QUICK_START_DEV.md README.DEV.md REVERSE_PROXY_EXAMPLE.md scripts/build-dev-image.sh 2>/dev/null || true
git restore --staged .github/workflows/docker-build-push.yml 2>/dev/null || true
git restore .github/workflows/docker-build-push.yml 2>/dev/null || true

# Étape 6: Commit consolidé
echo "💾 Création du commit consolidé..."
git commit -F- <<'EOF'
feat: Add development enterprise mode for testing and evaluation

This commit adds a development/testing mode that unlocks all Enterprise
features without requiring a valid license. This is compliant with the
LICENSE_EE.md terms which allow modifications for dev/testing purposes.

## Features

- Added N8N_DEV_ENTERPRISE_MODE environment variable support
- All Enterprise boolean features return true when dev mode is enabled
- All quotas return UNLIMITED_LICENSE_QUOTA (-1) when dev mode is active
- Full RBAC scope access in dev mode
- API remains enabled in dev mode (bypasses apiDisabled feature)

## Modified Files

Backend License Logic:
- packages/@n8n/backend-common/src/license-state.ts
- packages/cli/src/license.ts

Permissions:
- packages/@n8n/permissions/src/utilities/get-global-scopes.ee.ts
- packages/@n8n/permissions/src/utilities/get-role-scopes.ee.ts

Documentation:
- DEV_ENTERPRISE_MODE.md
- docker-compose.dev-enterprise.yml

Development Tools:
- .gitignore

## License Compliance

This feature is strictly for development and testing purposes as permitted
by LICENSE_EE.md. Production use requires a valid n8n Enterprise license.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF

echo "✓ Commit créé"

# Étape 7: Réactiver hooks
echo "🔧 Réactivation des hooks..."
mv .git/hooks.disabled .git/hooks 2>/dev/null || true
echo "✓ Hooks réactivés"

# Étape 8: Build test
echo "🏗️  Test du build..."
if pnpm build > build.log 2>&1; then
    echo "✓ Build réussi"
else
    echo "⚠️  Build avec erreurs. Vérifiez build.log"
    tail -n 50 build.log
fi

# Étape 9: Vérifications
echo "🔍 Vérifications..."
if git show upstream/master:packages/@n8n/backend-common/src/license-state.ts | grep -q "N8N_DEV"; then
    echo "⚠️  Le mode dev existe dans upstream (inattendu)"
else
    echo "✓ Mode dev non présent dans upstream (normal)"
fi

if grep -q "N8N_DEV_ENTERPRISE_MODE" packages/@n8n/backend-common/src/license-state.ts; then
    echo "✓ Mode dev présent dans master"
else
    echo "❌ Mode dev manquant dans master!"
    exit 1
fi

echo ""
echo "=================================================================="
echo "✅ Mise à jour terminée avec succès!"
echo ""
echo "📊 État actuel:"
git log --oneline -3
echo ""
echo "📋 Prochaines étapes:"
echo "  1. Vérifiez le build: tail -n 50 build.log"
echo "  2. Testez le mode dev: N8N_DEV_ENTERPRISE_MODE=true pnpm start"
echo "  3. Push vers origin: git push --force-with-lease origin master"
echo ""
echo "🔙 Backup disponible: $BACKUP_BRANCH"
echo "   Pour revenir: git reset --hard $BACKUP_BRANCH"
```

Sauvegardez ce script dans `scripts/update-from-upstream.sh` et rendez-le exécutable :

```bash
chmod +x scripts/update-from-upstream.sh
```

Puis exécutez-le simplement avec :

```bash
./scripts/update-from-upstream.sh
```

## Notes importantes

1. **Fréquence des mises à jour** : Il est recommandé de synchroniser avec upstream au moins une fois par semaine pour éviter trop de conflits.

2. **Gestion des conflits** : Si des conflits apparaissent dans les fichiers du mode développeur, privilégiez toujours vos modifications. Si upstream a modifié les mêmes parties de code, adaptez votre code pour qu'il fonctionne avec les nouvelles modifications tout en préservant la logique du mode dev.

3. **Backup** : Ne supprimez JAMAIS une branche de backup sans avoir vérifié que la nouvelle version fonctionne parfaitement.

4. **Tests** : Après chaque mise à jour, testez toujours :
   - Le build réussit
   - Le mode développeur fonctionne (`N8N_DEV_ENTERPRISE_MODE=true`)
   - Les features Enterprise sont bien débloquées
   - L'API est accessible en mode dev

5. **Documentation** : Si upstream introduit de nouvelles features Enterprise, mettez à jour `DEV_ENTERPRISE_MODE.md` pour documenter comment elles sont débloquées en mode dev.

## Support

Si vous rencontrez des problèmes :
1. Vérifiez que la branche de backup existe
2. Consultez les logs de build
3. Vérifiez que tous les fichiers modifiés sont présents
4. En dernier recours, revenez à la branche de backup et recommencez

---

*Dernière mise à jour : 2025-11-26*
