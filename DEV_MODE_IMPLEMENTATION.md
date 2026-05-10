# Guide Complet d'Implémentation du Mode Développeur Enterprise n8n

**Date de création :** 2025-11-26
**Version n8n :** 1.122.0+
**Objectif :** Documentation complète pour reproduction automatisée par IA

---

## Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Objectif et Justification](#objectif-et-justification)
3. [Architecture de la Solution](#architecture-de-la-solution)
4. [Fichiers Modifiés](#fichiers-modifiés)
5. [Implémentation Détaillée](#implémentation-détaillée)
6. [Vérification et Tests](#vérification-et-tests)
7. [Utilisation](#utilisation)

---

## Vue d'Ensemble

### Contexte

n8n est une plateforme d'automatisation de workflows qui propose deux éditions :
- **Community Edition** : Version gratuite avec fonctionnalités de base
- **Enterprise Edition** : Version payante avec fonctionnalités avancées

Les fonctionnalités Enterprise sont protégées par un système de licences qui vérifie la validité de la souscription.

### Problématique

Pour le développement, les tests et l'évaluation, il est nécessaire d'accéder aux fonctionnalités Enterprise sans disposer d'une licence valide. Cela est notamment requis pour :
- Tester un provider Terraform qui gère des ressources Enterprise
- Développer des intégrations utilisant des fonctionnalités Enterprise
- Exécuter des tests automatisés en CI/CD
- Évaluer les fonctionnalités avant l'achat

### Solution Implémentée

Un **mode développeur** activable via une variable d'environnement `N8N_DEV_ENTERPRISE_MODE=true` qui :
- Déverrouille toutes les fonctionnalités Enterprise
- Définit tous les quotas à "illimité"
- Accorde tous les scopes RBAC
- Maintient l'API activée

### Conformité Légale

Cette implémentation est **conforme à la licence Enterprise** (`LICENSE_EE.md`) qui stipule :

> "You may copy and modify the Software for development and testing purposes, without requiring a subscription."

**IMPORTANT :** Ce mode est strictement réservé au développement et aux tests. L'utilisation en production nécessite une licence Enterprise valide.

---

## Objectif et Justification

### Objectifs Principaux

1. **Développement sans contraintes** : Permettre aux développeurs de tester toutes les fonctionnalités localement
2. **Tests automatisés** : Exécuter des tests CI/CD sur des fonctionnalités Enterprise
3. **Provider Terraform** : Tester la gestion de ressources Enterprise (projets, utilisateurs, etc.)
4. **Évaluation technique** : Tester les fonctionnalités avant décision d'achat

### Pourquoi Cette Approche

**Alternatives considérées et rejetées :**

1. ❌ **Licence de développement gratuite** : Nécessite un compte, processus bureaucratique
2. ❌ **Mock des fonctionnalités** : Trop complexe, ne teste pas le vrai comportement
3. ❌ **Modification de chaque feature** : Trop invasif, difficile à maintenir

**Avantages de cette approche :**

1. ✅ **Simple** : Une seule variable d'environnement
2. ✅ **Non invasif** : Modifications minimales, ciblées
3. ✅ **Maintenable** : Facile à mettre à jour lors des montées de version
4. ✅ **Sécurisé** : Nécessite une activation explicite
5. ✅ **Conforme** : Respect de la licence Enterprise

---

## Architecture de la Solution

### Principe de Fonctionnement

Le système de licences n8n fonctionne selon cette architecture :

```
┌─────────────────────────────────────────────────────────────┐
│                     Application n8n                          │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           Composants métier (Features)               │   │
│  │  - Workflows  - Projects  - Users  - Variables       │   │
│  └────────────────────┬─────────────────────────────────┘   │
│                       │ Appelle                              │
│                       ▼                                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              LicenseState (Backend)                   │   │
│  │  - isLicensed(feature)                               │   │
│  │  - getValue(quota)                                   │   │
│  │  - isAPIDisabled()                                   │   │
│  └────────────────────┬─────────────────────────────────┘   │
│                       │                                      │
│                       │ Délègue à                           │
│                       ▼                                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              License (CLI)                            │   │
│  │  - LicenseManager                                    │   │
│  │  - Validation de licence                             │   │
│  └────────────────────┬─────────────────────────────────┘   │
│                       │                                      │
│                       │ Appelle                              │
│                       ▼                                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          Permissions (RBAC)                           │   │
│  │  - getGlobalScopes()                                 │   │
│  │  - getAuthPrincipalScopes()                          │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Points d'Interception

Notre solution intercepte à **3 niveaux** :

1. **LicenseState** (`packages/@n8n/backend-common/src/license-state.ts`)
   - Point central : Vérifie les features et quotas
   - **Pourquoi ici ?** C'est la première couche, utilisée partout

2. **License** (`packages/cli/src/license.ts`)
   - Gère le LicenseManager
   - **Pourquoi ici ?** Renfort pour certaines vérifications directes

3. **Permissions** (`packages/@n8n/permissions/src/utilities/`)
   - Gère les scopes RBAC
   - **Pourquoi ici ?** Les permissions sont vérifiées séparément

### Flux de Décision

```
Variable d'environnement
    ↓
N8N_DEV_ENTERPRISE_MODE=true ?
    ├─ OUI → Retourner true/unlimited/all scopes
    └─ NON → Vérification licence normale
```

---

## Fichiers Modifiés

### Résumé des Modifications

| Fichier | Type | Lignes Ajoutées | Raison |
|---------|------|----------------|--------|
| `packages/@n8n/backend-common/src/license-state.ts` | Code | +27 | Logique principale |
| `packages/cli/src/license.ts` | Code | +21 | Renfort validation |
| `packages/@n8n/permissions/src/utilities/get-global-scopes.ee.ts` | Code | +10 | RBAC global |
| `packages/@n8n/permissions/src/utilities/get-role-scopes.ee.ts` | Code | +10 | RBAC utilisateur |
| `.gitignore` | Config | +21 | Fichiers dev |
| `DEV_ENTERPRISE_MODE.md` | Doc | +200 | Documentation |
| `docker-compose.dev-enterprise.yml` | Config | +100 | Config Docker |

**Total : 7 fichiers modifiés, 389 lignes ajoutées**

---

## Implémentation Détaillée

### 1. Fichier : `packages/@n8n/backend-common/src/license-state.ts`

**Rôle :** Point central de vérification des licences pour tout le backend.

#### Modification 1.1 : Ajout de la méthode `isDevEnterpriseMode()`

**Localisation :** Après la méthode `assertProvider()`, ligne ~26

**Code à ajouter :**

```typescript
/**
 * Check if development enterprise mode is enabled via environment variable
 */
private isDevEnterpriseMode(): boolean {
	return process.env.N8N_DEV_ENTERPRISE_MODE === 'true';
}
```

**POURQUOI :**
- **Centralisation** : Une seule méthode pour vérifier le mode dev
- **Private** : Méthode interne, pas exposée à l'extérieur
- **Explicit** : Vérifie strictement la valeur `'true'` (string)
- **Performance** : Vérification simple, pas de parsing complexe

**Points Importants :**
- Le `process.env` retourne toujours des strings, d'où `=== 'true'`
- Méthode `private` car usage interne uniquement
- Pas de cache car l'env var ne change pas pendant l'exécution

---

#### Modification 1.2 : Modification de `isLicensed()`

**Localisation :** Méthode `isLicensed()`, ligne ~40

**Code à ajouter AU DÉBUT de la méthode :**

```typescript
// DEV MODE: Bypass license check if development enterprise mode is enabled
if (this.isDevEnterpriseMode()) {
	return true;
}
```

**POURQUOI :**
- **Court-circuit** : Si mode dev, retourne `true` immédiatement
- **Pas de vérification du provider** : Évite erreurs si pas de licence configurée
- **Universel** : Fonctionne pour toutes les features (LDAP, SAML, etc.)

**Fonctionnalités débloquées :**
- Sharing (partage de workflows)
- LDAP, SAML, OIDC (authentification SSO)
- MFA Enforcement
- Log Streaming
- Variables
- Source Control
- Workflows Diffs
- AI Assistant
- Et 20+ autres features

**Comportement Normal (sans mode dev) :**
```typescript
isLicensed('feat:ldap') → false (si pas de licence)
```

**Comportement en Mode Dev :**
```typescript
N8N_DEV_ENTERPRISE_MODE=true
isLicensed('feat:ldap') → true (toujours)
```

---

#### Modification 1.3 : Modification de `getValue()`

**Localisation :** Méthode `getValue()`, ligne ~59

**Code à ajouter AU DÉBUT de la méthode :**

```typescript
// DEV MODE: Return unlimited quota for all numeric features if development mode is enabled
if (this.isDevEnterpriseMode()) {
	// For quota features, return unlimited (-1)
	// For AI credits specifically, return a large number instead of -1
	if (feature === 'quota:aiCredits') {
		return 1000000 as FeatureReturnType[T];
	}
	return UNLIMITED_LICENSE_QUOTA as FeatureReturnType[T];
}
```

**POURQUOI :**

**Quotas dans n8n :**
- `-1` = UNLIMITED (convention n8n)
- Quotas : nombre max d'utilisateurs, workflows actifs, variables, etc.

**Cas particulier AI Credits :**
- Les AI credits ne supportent PAS `-1`
- Nécessite un nombre positif
- `1000000` = assez pour tous les tests

**Quotas débloqués :**
- `quota:users` → -1 (utilisateurs illimités)
- `quota:activeWorkflows` → -1 (workflows illimités)
- `quota:maxVariables` → -1 (variables illimitées)
- `quota:aiCredits` → 1000000 (1 million de crédits)
- `quota:maxTeamProjects` → -1 (projets illimités)
- `quota:evaluations:maxWorkflows` → -1 (évaluations illimitées)

**Comportement Normal :**
```typescript
getValue('quota:users') → 5 (exemple)
getValue('quota:aiCredits') → 0 (pas de crédits)
```

**Comportement en Mode Dev :**
```typescript
N8N_DEV_ENTERPRISE_MODE=true
getValue('quota:users') → -1 (illimité)
getValue('quota:aiCredits') → 1000000
```

---

#### Modification 1.4 : Modification de `isAPIDisabled()`

**Localisation :** Méthode `isAPIDisabled()`, ligne ~155

**Code à ajouter AU DÉBUT de la méthode :**

```typescript
// DEV MODE: In dev mode, we want the API to be enabled
// API_DISABLED is a negative feature, so return false in dev mode
if (this.isDevEnterpriseMode()) {
	return false;
}
```

**POURQUOI :**

**Feature particulière `feat:apiDisabled` :**
- C'est une **feature négative** (inverse de la logique normale)
- Quand activée (`true`) → API est **désactivée**
- Quand désactivée (`false`) → API est **activée**

**Logique inverse :**
```
isAPIDisabled() = true  → API est DÉSACTIVÉE
isAPIDisabled() = false → API est ACTIVÉE
```

**En mode dev, on veut l'API activée :**
- Pour tester le provider Terraform (utilise l'API)
- Pour le développement local
- Pour les tests automatisés

**Sans ce code :**
```typescript
N8N_DEV_ENTERPRISE_MODE=true
isLicensed('feat:apiDisabled') → true (car tout est true)
→ L'API serait DÉSACTIVÉE (comportement inverse)
```

**Avec ce code :**
```typescript
N8N_DEV_ENTERPRISE_MODE=true
isAPIDisabled() → false
→ L'API est ACTIVÉE (comportement voulu)
```

---

### 2. Fichier : `packages/cli/src/license.ts`

**Rôle :** Gère le LicenseManager, point d'entrée pour certaines vérifications.

#### Modification 2.1 : Modification de `isLicensed()`

**Localisation :** Méthode `isLicensed()`, ligne ~221

**Code à ajouter AU DÉBUT de la méthode :**

```typescript
// DEV MODE: Bypass license check if development enterprise mode is enabled
if (process.env.N8N_DEV_ENTERPRISE_MODE === 'true') {
	// Special case: API_DISABLED is a negative feature - when enabled, it disables the API
	// In dev mode, we want the API to be enabled, so return false for this feature
	if (feature === LICENSE_FEATURES.API_DISABLED) {
		return false;
	}
	return true;
}
```

**POURQUOI :**

**Pourquoi dupliquer la vérification ?**
- Certains composants appellent directement `License.isLicensed()` au lieu de `LicenseState.isLicensed()`
- Renfort de sécurité : double vérification
- Évite les cas edge où `LicenseState` n'est pas initialisé

**Gestion de `API_DISABLED` :**
- Même logique que dans `LicenseState`
- Nécessaire car certains composants vérifient directement ici

**Cas d'usage :**
- Initialisation de l'application (avant `LicenseState`)
- Certains middlewares Express
- Composants legacy qui n'utilisent pas `LicenseState`

---

#### Modification 2.2 : Modification de `getValue()`

**Localisation :** Méthode `getValue()`, ligne ~353

**Code à ajouter AU DÉBUT de la méthode :**

```typescript
// DEV MODE: Return unlimited quota for all numeric features if development mode is enabled
if (process.env.N8N_DEV_ENTERPRISE_MODE === 'true') {
	// For quota features, return unlimited (-1)
	const featureStr = String(feature);
	if (featureStr.startsWith('quota:')) {
		// For AI credits specifically, return a large number instead of -1
		if (feature === 'quota:aiCredits') {
			return 1000000 as FeatureReturnType[T];
		}
		return UNLIMITED_LICENSE_QUOTA as FeatureReturnType[T];
	}
}
```

**POURQUOI :**

**Pourquoi dupliquer cette logique aussi ?**
- Même raison : certains composants appellent directement `License.getValue()`
- Cohérence : même comportement partout

**Différence avec `LicenseState` :**
- On vérifie explicitement si c'est un quota (`featureStr.startsWith('quota:')`)
- Plus défensif car cette méthode peut être appelée avec n'importe quelle feature
- Le type `FeatureReturnType[T]` peut être string ou number

**Sécurité du typage :**
```typescript
const featureStr = String(feature);
```
- Convertit explicitement en string pour le test `startsWith()`
- Évite erreurs TypeScript

---

### 3. Fichier : `packages/@n8n/permissions/src/utilities/get-global-scopes.ee.ts`

**Rôle :** Retourne les scopes (permissions) globaux d'un utilisateur selon son rôle.

#### Modification 3.1 : Import de `ALL_SCOPES`

**Localisation :** Début du fichier, ligne 1

**Code à ajouter :**

```typescript
import { ALL_SCOPES } from '../scope-information';
```

**POURQUOI :**
- `ALL_SCOPES` : Tableau contenant TOUS les scopes possibles dans n8n
- Défini dans `scope-information.ts` : liste exhaustive des permissions
- En mode dev, on veut accorder TOUS les scopes

---

#### Modification 3.2 : Modification de `getGlobalScopes()`

**Localisation :** Fonction `getGlobalScopes()`, ligne ~9

**Code AVANT :**

```typescript
export const getGlobalScopes = (principal: AuthPrincipal) =>
	principal.role.scopes.map((scope) => scope.slug) ?? [];
```

**Code APRÈS :**

```typescript
export const getGlobalScopes = (principal: AuthPrincipal) => {
	// DEV MODE: Return all scopes if development enterprise mode is enabled
	if (process.env.N8N_DEV_ENTERPRISE_MODE === 'true') {
		return ALL_SCOPES;
	}
	return principal.role.scopes.map((scope) => scope.slug) ?? [];
};
```

**POURQUOI :**

**Contexte RBAC (Role-Based Access Control) :**
- Chaque utilisateur a un rôle (`global:admin`, `global:member`, etc.)
- Chaque rôle a des scopes (permissions) : `workflow:read`, `user:create`, etc.
- Les scopes définissent ce que l'utilisateur peut faire

**Scopes dans n8n :**
```
workflow:read, workflow:create, workflow:update, workflow:delete
user:read, user:create, user:update, user:delete
credential:read, credential:create, ...
project:read, project:create, ...
variable:read, variable:create, ...
```

**Comportement Normal :**
```typescript
user = { role: 'global:member' }
getGlobalScopes(user) → ['workflow:read', 'workflow:execute']
```

**Comportement en Mode Dev :**
```typescript
N8N_DEV_ENTERPRISE_MODE=true
user = { role: 'global:member' }
getGlobalScopes(user) → ALL_SCOPES (300+ permissions)
```

**Conséquence :**
- L'utilisateur peut TOUT faire (admin complet)
- Accès à toutes les fonctionnalités Enterprise
- Parfait pour le développement

---

### 4. Fichier : `packages/@n8n/permissions/src/utilities/get-role-scopes.ee.ts`

**Rôle :** Retourne les scopes d'un `AuthPrincipal` (utilisateur authentifié) avec filtres optionnels.

#### Modification 4.1 : Import de `ALL_SCOPES`

**Localisation :** Début du fichier

**Code à ajouter :**

```typescript
import { ALL_SCOPES } from '../scope-information';
```

**POURQUOI :** Même raison que pour `get-global-scopes.ee.ts`

---

#### Modification 4.2 : Modification de `getAuthPrincipalScopes()`

**Localisation :** Fonction `getAuthPrincipalScopes()`, ligne ~32

**Code à ajouter AU DÉBUT de la fonction :**

```typescript
// DEV MODE: Return all scopes if development enterprise mode is enabled
if (process.env.N8N_DEV_ENTERPRISE_MODE === 'true') {
	let scopes = ALL_SCOPES;
	if (filters) {
		scopes = scopes.filter((s) => filters.includes(s.split(':')[0] as Resource));
	}
	return scopes;
}
```

**POURQUOI :**

**Différence avec `getGlobalScopes()` :**
- Cette fonction supporte des **filtres par ressource**
- `filters` peut être `['workflow', 'user']` → retourne uniquement les scopes de ces ressources

**Filtrage des scopes :**
```typescript
s.split(':')[0]
```
- Scope = `'workflow:read'` → split → `['workflow', 'read']` → `[0]` → `'workflow'`
- Compare avec le filtre

**Exemple sans filtre :**
```typescript
N8N_DEV_ENTERPRISE_MODE=true
getAuthPrincipalScopes(user) → ALL_SCOPES
```

**Exemple avec filtre :**
```typescript
N8N_DEV_ENTERPRISE_MODE=true
getAuthPrincipalScopes(user, ['workflow']) → ['workflow:read', 'workflow:create', 'workflow:update', ...]
```

**Pourquoi respecter les filtres ?**
- Certains composants filtrent volontairement pour des raisons de performance
- On veut débloquer les features, pas casser le fonctionnement

---

### 5. Fichier : `.gitignore`

**Rôle :** Exclure les fichiers de développement du versioning Git.

#### Modifications

**Code à ajouter à la fin du fichier :**

```gitignore
compose.yml

#Ignore vscode AI rules
.github/instructions/codacy.instructions.md

# Build logs
build*.log
docker-build*.log

# Local docker-compose files
docker-compose.local.yml
docker-compose.temp.yml

# Docker development files
docker-compose.dev.yml
docker-compose.dev.aliases.sh
volumes/
.env
!.env.example
```

**POURQUOI pour chaque ligne :**

1. `compose.yml`
   - Fichier Docker Compose généré automatiquement
   - Peut contenir des configs locales

2. `.github/instructions/codacy.instructions.md`
   - Instructions pour l'IA de développement
   - Spécifique à chaque développeur

3. `build*.log`, `docker-build*.log`
   - Logs de compilation
   - Trop volumineux pour Git
   - Utiles uniquement localement

4. `docker-compose.local.yml`, `docker-compose.temp.yml`
   - Fichiers de test temporaires
   - Configurations personnelles

5. `docker-compose.dev.yml`
   - Override local du docker-compose
   - Chaque dev peut avoir sa config

6. `docker-compose.dev.aliases.sh`
   - Scripts personnels
   - Peuvent contenir des chemins absolus

7. `volumes/`
   - Données persistantes de Docker
   - Bases de données, fichiers uploadés
   - **TRÈS IMPORTANT** : Ne jamais commit les données

8. `.env`
   - **CRITIQUE** : Peut contenir des secrets (API keys, passwords)
   - Chaque environnement a ses propres valeurs

9. `!.env.example`
   - Exception : On VEUT commit l'exemple
   - Sert de template pour les nouveaux dev

---

### 6. Fichier : `DEV_ENTERPRISE_MODE.md`

**Rôle :** Documentation complète du mode développeur.

**Contenu :** 200 lignes de documentation couvrant :

#### Sections Principales

1. **Overview**
   - Explication du concept
   - Différence Community vs Enterprise

2. **License Compliance**
   - Citation de la licence `LICENSE_EE.md`
   - Avertissement usage dev/test uniquement

3. **How to Enable**
   - Instructions Docker Compose
   - Instructions direct run
   - Exemples concrets

4. **What Gets Unlocked**
   - Liste exhaustive des 30+ features
   - Liste des quotas
   - Organisé par catégorie

5. **Use Cases**
   - 4 cas d'usage principaux
   - Exemples concrets

6. **Implementation Details**
   - Description technique simple
   - Référence aux fichiers modifiés

7. **Example Docker Compose**
   - Configuration complète
   - Prête à copier-coller

**POURQUOI ce fichier :**
- **Documentation** : Utilisateur doit comprendre comment l'activer
- **Transparence** : Liste exacte de ce qui est débloqué
- **Conformité** : Rappel constant de la limitation dev/test
- **Onboarding** : Nouveau contributeur comprend vite

---

### 7. Fichier : `docker-compose.dev-enterprise.yml`

**Rôle :** Configuration Docker Compose prête à l'emploi avec mode dev activé.

#### Structure

**Services :**

1. **postgres**
   ```yaml
   image: postgres:17-alpine
   volumes:
     - ./volumes/postgresql:/var/lib/postgresql/data
   ```

   **POURQUOI :**
   - PostgreSQL pour persistance
   - Alpine = image légère
   - Volume local pour persistance des données

2. **n8n**
   ```yaml
   build:
     context: .
     dockerfile: docker/images/n8n/Dockerfile
   environment:
     N8N_DEV_ENTERPRISE_MODE: "true"
   ```

   **POURQUOI :**
   - Build depuis le code source local (avec nos modifications)
   - Variable `N8N_DEV_ENTERPRISE_MODE: "true"` activée
   - Configuration complète production-ready

**Variables d'Environnement Importantes :**

```yaml
N8N_DEV_ENTERPRISE_MODE: "true"  # ← LA VARIABLE CLÉ
DB_TYPE: postgresdb
N8N_DIAGNOSTICS_ENABLED: "false"  # Pas de télémétrie
N8N_METRICS: "true"              # Métriques pour debug
EXECUTIONS_DATA_PRUNE: "true"    # Nettoyage auto
```

**POURQUOI ce fichier :**
- **Quick start** : Un seul `docker-compose up` et ça marche
- **Exemple complet** : Montre toutes les bonnes pratiques
- **Template** : Peut être copié et adapté

---

## Vérification et Tests

### Vérifier que le Mode Dev Fonctionne

#### Test 1 : Vérifier les Variables d'Environnement

```bash
# Lancer n8n
N8N_DEV_ENTERPRISE_MODE=true pnpm start

# Vérifier dans les logs
# Devrait montrer toutes les features actives
```

#### Test 2 : Vérifier une Feature Enterprise (via API)

```bash
# Créer un projet (feature Enterprise)
curl -X POST http://localhost:5678/api/v1/projects \
  -H "X-N8N-API-KEY: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Project"}'

# SANS mode dev → Erreur 403 "License required"
# AVEC mode dev → Succès 201 Created
```

#### Test 3 : Vérifier les Quotas

```bash
# Créer 100 workflows
# SANS mode dev → Bloqué à 20 (quota Community)
# AVEC mode dev → Pas de limite
```

#### Test 4 : Vérifier les Scopes RBAC

```javascript
// Dans le code n8n, ajouter un log :
console.log('User scopes:', getGlobalScopes(user));

// SANS mode dev → ['workflow:read', 'workflow:execute'] (exemple)
// AVEC mode dev → [... 300+ scopes]
```

### Tests Automatisés

```bash
# Lancer les tests n8n
pnpm test

# Les tests doivent passer avec ou sans mode dev
# Le mode dev ne doit PAS casser les tests existants
```

### Vérification de la Compilation

```bash
# TypeScript doit compiler sans erreur
pnpm typecheck

# Tous les packages doivent compiler
cd packages/@n8n/backend-common && pnpm typecheck
cd packages/cli && pnpm typecheck
cd packages/@n8n/permissions && pnpm typecheck
```

---

## Utilisation

### Activation en Local (Development)

```bash
# Option 1 : Variable d'environnement
export N8N_DEV_ENTERPRISE_MODE=true
pnpm start

# Option 2 : Inline
N8N_DEV_ENTERPRISE_MODE=true pnpm start
```

### Activation avec Docker

```bash
# Utiliser le docker-compose fourni
docker-compose -f docker-compose.dev-enterprise.yml up -d

# Ou ajouter la variable dans votre docker-compose.yml
environment:
  N8N_DEV_ENTERPRISE_MODE: "true"
```

### Activation en CI/CD

```yaml
# GitHub Actions
env:
  N8N_DEV_ENTERPRISE_MODE: true

# GitLab CI
variables:
  N8N_DEV_ENTERPRISE_MODE: "true"
```

### Vérifier que le Mode est Actif

```bash
# Méthode 1 : Logs au démarrage
# Chercher dans les logs : features actives

# Méthode 2 : Via l'API
curl http://localhost:5678/api/v1/license
# Devrait montrer planName: "development"

# Méthode 3 : Créer une ressource Enterprise
curl -X POST http://localhost:5678/api/v1/projects \
  -H "X-N8N-API-KEY: key" \
  -d '{"name":"test"}'
# Doit fonctionner sans erreur
```

---

## Maintenance et Évolution

### Lors des Mises à Jour n8n

**Processus recommandé :**

1. **Fetch upstream**
   ```bash
   git fetch upstream
   git diff upstream/master...master
   ```

2. **Vérifier les conflits potentiels**
   - Fichiers modifiés : `license-state.ts`, `license.ts`, permissions
   - Si conflits → adapter les modifications

3. **Rebase**
   ```bash
   git rebase upstream/master
   ```

4. **Vérifier que le mode dev fonctionne**
   ```bash
   N8N_DEV_ENTERPRISE_MODE=true pnpm start
   # Tester une feature Enterprise
   ```

5. **Mettre à jour la documentation**
   - Si nouvelles features → Ajouter à `DEV_ENTERPRISE_MODE.md`
   - Si nouveaux quotas → Documenter

### Nouvelles Features Enterprise

Si n8n ajoute une nouvelle feature Enterprise :

1. **Aucune modification nécessaire** dans `isLicensed()` car notre code retourne `true` pour TOUT
2. **Possible modification** dans `getValue()` si nouveau quota spécial (comme AI credits)
3. **Mettre à jour** `DEV_ENTERPRISE_MODE.md` pour documenter

### Nouveaux Scopes RBAC

Si n8n ajoute de nouveaux scopes :

1. **Aucune modification nécessaire** car on retourne `ALL_SCOPES`
2. `ALL_SCOPES` est maintenu par n8n automatiquement

---

## Annexes

### Annexe A : Liste Complète des Features Débloquées

```typescript
// Boolean Features (retournent true)
'feat:sharing'
'feat:ldap'
'feat:saml'
'feat:oidc'
'feat:mfaEnforcement'
'feat:logStreaming'
'feat:advancedExecutionFilters'
'feat:variables'
'feat:sourceControl'
'feat:externalSecrets'
'feat:debugInEditor'
'feat:binaryDataS3'
'feat:multipleMainInstances'
'feat:workerView'
'feat:advancedPermissions'
'feat:projectRole:admin'
'feat:projectRole:editor'
'feat:projectRole:viewer'
'feat:aiAssistant'
'feat:askAi'
'feat:aiCredits'
'feat:folders'
'feat:insights:viewSummary'
'feat:insights:viewDashboard'
'feat:insights:viewHourlyData'
'feat:apiKeyScopes'
'feat:workflowDiffs'
'feat:customRoles'
'feat:communityNodes:customRegistry'
'feat:aiBuilder'
```

### Annexe B : Liste Complète des Quotas

```typescript
// Quotas (retournent -1 ou 1000000)
'quota:users'                → -1 (illimité)
'quota:activeWorkflows'      → -1 (illimité)
'quota:maxVariables'         → -1 (illimité)
'quota:aiCredits'            → 1000000
'quota:workflowHistoryPrune' → -1 (illimité)
'quota:insights:maxHistoryDays' → -1 (illimité)
'quota:insights:retention:maxAgeDays' → -1 (illimité)
'quota:insights:retention:pruneIntervalDays' → -1 (illimité)
'quota:maxTeamProjects'      → -1 (illimité)
'quota:evaluations:maxWorkflows' → -1 (illimité)
```

### Annexe C : Architecture des Fichiers n8n (Contexte)

```
n8n/
├── packages/
│   ├── @n8n/
│   │   ├── backend-common/
│   │   │   └── src/
│   │   │       └── license-state.ts  ← MODIFIÉ (logique principale)
│   │   ├── permissions/
│   │   │   └── src/
│   │   │       └── utilities/
│   │   │           ├── get-global-scopes.ee.ts  ← MODIFIÉ (RBAC global)
│   │   │           └── get-role-scopes.ee.ts    ← MODIFIÉ (RBAC user)
│   ├── cli/
│   │   └── src/
│   │       └── license.ts  ← MODIFIÉ (renfort validation)
├── .gitignore              ← MODIFIÉ (fichiers dev)
├── DEV_ENTERPRISE_MODE.md  ← NOUVEAU (documentation)
└── docker-compose.dev-enterprise.yml  ← NOUVEAU (config Docker)
```

### Annexe D : Commandes de Diagnostic

```bash
# Vérifier que les modifications sont présentes
grep -r "N8N_DEV_ENTERPRISE_MODE" packages/

# Devrait retourner 5 fichiers :
# - license-state.ts (3 occurrences)
# - license.ts (2 occurrences)
# - get-global-scopes.ee.ts (1 occurrence)
# - get-role-scopes.ee.ts (1 occurrence)

# Vérifier la variable d'environnement
echo $N8N_DEV_ENTERPRISE_MODE

# Lister les scopes disponibles
cat packages/@n8n/permissions/src/scope-information.ts | grep "export const ALL_SCOPES"
```

---

## Checklist de Reproduction pour IA

Pour reproduire cette implémentation automatiquement, suivre cette checklist :

- [ ] 1. Cloner le repo n8n officiel
- [ ] 2. Modifier `packages/@n8n/backend-common/src/license-state.ts`
  - [ ] 2.1. Ajouter méthode `isDevEnterpriseMode()`
  - [ ] 2.2. Modifier `isLicensed()` - ajouter check au début
  - [ ] 2.3. Modifier `getValue()` - ajouter check au début
  - [ ] 2.4. Modifier `isAPIDisabled()` - ajouter check au début
- [ ] 3. Modifier `packages/cli/src/license.ts`
  - [ ] 3.1. Modifier `isLicensed()` - ajouter check + gestion API_DISABLED
  - [ ] 3.2. Modifier `getValue()` - ajouter check + gestion quotas
- [ ] 4. Modifier `packages/@n8n/permissions/src/utilities/get-global-scopes.ee.ts`
  - [ ] 4.1. Ajouter import `ALL_SCOPES`
  - [ ] 4.2. Modifier fonction - transformer en bloc + ajouter check
- [ ] 5. Modifier `packages/@n8n/permissions/src/utilities/get-role-scopes.ee.ts`
  - [ ] 5.1. Ajouter import `ALL_SCOPES`
  - [ ] 5.2. Modifier fonction - ajouter check avec gestion filters
- [ ] 6. Modifier `.gitignore`
  - [ ] 6.1. Ajouter patterns pour fichiers dev
- [ ] 7. Créer `DEV_ENTERPRISE_MODE.md`
  - [ ] 7.1. Documentation complète (voir contenu dans ce guide)
- [ ] 8. Créer `docker-compose.dev-enterprise.yml`
  - [ ] 8.1. Configuration PostgreSQL
  - [ ] 8.2. Configuration n8n avec variable activée
- [ ] 9. Vérifications
  - [ ] 9.1. TypeScript compile (`pnpm typecheck`)
  - [ ] 9.2. Tests passent (`pnpm test`)
  - [ ] 9.3. Mode dev fonctionne (créer un projet via API)
- [ ] 10. Commit
  - [ ] 10.1. Message descriptif
  - [ ] 10.2. Co-authoring si applicable

---

**FIN DU GUIDE D'IMPLÉMENTATION**

*Ce document contient TOUTES les informations nécessaires pour reproduire exactement l'implémentation du mode développeur Enterprise n8n.*

*Créé le : 2025-11-26*
*Auteur : Florent (Kodflow)*
*Version n8n : 1.122.0+*
