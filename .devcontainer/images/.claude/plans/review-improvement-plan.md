# Plan d'Amélioration /review - Architecture RLM Optimisée

**Date :** 2026-01-18
**Objectif :** Code stable, parfait, sans risque de crash, sans antipatterns, performant
**Contraintes :** Modèles illimités (haiku/sonnet/opus), pas de limite de temps

---

## Table des Matières

1. [Plan Détaillé /review (12 Phases)](#1-plan-détaillé-review-12-phases)
2. [Revue des Agents et Modèles](#2-revue-des-agents-et-modèles)
3. [Nouveaux Agents à Créer](#3-nouveaux-agents-à-créer)
4. [Prompts Détaillés pour Implémentation](#4-prompts-détaillés-pour-implémentation)

---

## 1. Plan Détaillé /review (12 Phases)

### Architecture Cible (RLM-Enhanced)

```
/review
    │
    ├─→ Phase 0: Context Detection (sequential)
    ├─→ Phase 0.5: Repo Profile [NEW] (cacheable, 7j TTL)
    ├─→ Phase 1: Intent Analysis + Risk Model [ENHANCED]
    ├─→ Phase 1.5: Auto-Describe (drift-detection + AskUserQuestion)
    ├─→ Phase 2: Feedback Collection (sequential)
    ├─→ Phase 2.3: CI Diagnostics [NEW] (conditionnel)
    ├─→ Phase 2.5: Question Handling (sequential)
    ├─→ Phase 3: Peek & Decompose + Routing [ENHANCED]
    │
    ├─→ Phase 4: Parallel Analysis [5 AGENTS]
    │       │
    │       ├─→ developer-executor-correctness [NEW] (sonnet)
    │       │     Focus: Algorithmic errors, invariants, state machines
    │       │
    │       ├─→ developer-executor-security (sonnet) [UPGRADED]
    │       │     Focus: OWASP, taint analysis, supply chain
    │       │
    │       ├─→ developer-executor-design (sonnet) [NEW]
    │       │     Focus: Antipatterns, DDD violations, layering
    │       │
    │       ├─→ developer-executor-quality (haiku) [REFOCUSED]
    │       │     Focus: Style, complexity metrics, duplication
    │       │
    │       └─→ developer-executor-shell (haiku) [NEW]
    │             Focus: Shell safety, Dockerfile, CI/CD scripts
    │
    ├─→ Phase 4.7: Merge & Dedupe [NEW] (normalization)
    ├─→ Phase 5: Challenge (evidence-first + counterexamples)
    ├─→ Phase 6: Output Generation (Review + Plan séparés)
    └─→ Phase 6.5: Review Comment Sync [NEW] (PR/MR update)
```

---

### Phase 0.5 : Repo Profile [NOUVELLE]

```yaml
repo_profile:
  goal: "Construire un profil stable du repo (conventions, architecture, ownership)"

  cache:
    key: "repo_profile@{default_branch}"
    ttl: "7d"
    location: ".claude/.cache/repo_profile.json"

  inputs:
    priority_files:
      - "README.md"
      - "CONTRIBUTING.md"
      - "ARCHITECTURE.md"
      - "docs/**"
      - ".github/**"
      - ".gitlab-ci.yml"
      - "Makefile"
      - "Taskfile.yml"
      - "go.mod"
      - "package.json"
      - ".eslintrc*"
      - ".golangci*"
      - ".editorconfig"
      - "CODEOWNERS"
      - ".claude/docs/**"

  extract:
    languages: [string]
    build_tools: [string]
    test_frameworks: [string]
    lint_tools: [string]
    formatting_tools: [string]
    architecture_style: "hexagonal|layered|cqrs|microservices|monolith"
    error_conventions: [string]
    naming_conventions: [string]
    ownership:
      codeowners_present: boolean
      owners_by_path: [{path, owners}]
    security_policies: [string]
    ci_cd_type: "github_actions|gitlab_ci|jenkins|other"

  output:
    repo_profile_summary: "max 50 lines, JSON"

  usage: |
    Ce profil est injecté dans CHAQUE agent pour qu'ils:
    - Adaptent leurs checks aux conventions du repo
    - Évitent les faux positifs sur des patterns voulus
    - Respectent le style établi
```

---

### Phase 1 : Intent Analysis + Risk Model [ENRICHIE]

```yaml
intent_analysis:
  # ... existing fields ...

  risk_model:
    goal: "Identifier les zones critiques AVANT analyse lourde"

    risk_tags:
      - "authn_authz"      # auth, jwt, oauth, rbac, acl, session
      - "crypto"           # crypto, x509, tls, sign, encrypt, hash
      - "secrets"          # secret, token, key, vault, password, credential
      - "network"          # http, grpc, tcp, udp, dns, socket
      - "db_migrations"    # migrate, schema, sql, gorm, prisma, ent
      - "concurrency"      # goroutine, mutex, channel, lock, atomic, sync
      - "supply_chain"     # Dockerfile, go.sum, package-lock, vendor, pip.lock
      - "state_machine"    # state, transition, fsm, workflow
      - "pagination"       # cursor, offset, limit, page
      - "caching"          # cache, ttl, invalidate, redis, memcached

    detection_patterns:
      authn_authz: ["auth", "jwt", "oauth", "rbac", "acl", "login", "session"]
      crypto: ["crypto", "x509", "tls", "sign", "encrypt", "decrypt", "hash"]
      secrets: ["secret", "token", "key", "vault", "password", "credential"]
      network: ["http.Client", "grpc", "tcp", "net.Dial", "socket"]
      db_migrations: ["migrate", "schema", "sql", "gorm", "prisma"]
      concurrency: ["goroutine", "go func", "mutex", "channel", "sync."]
      supply_chain: ["Dockerfile", "go.sum", "package-lock", "requirements.txt"]
      state_machine: ["state", "transition", "fsm", "StateMachine"]
      pagination: ["cursor", "offset", "limit", "NextPage", "pageToken"]
      caching: ["cache", "ttl", "Cache.Get", "redis", "memcached"]

    calibration:
      rule: |
        SI any(risk_tags) == true:
          analysis_depth = "deep"
          prioritize_files = "risk-touched first"
          enable_agents = ["correctness", "security", "design"]
        SI risk_tags contains ["authn_authz", "crypto", "secrets"]:
          force_security_deep = true
        SI risk_tags contains ["concurrency", "state_machine"]:
          force_correctness_deep = true

    output:
      risk_tags: [string]
      risk_files: [{path, risk_tags}]
      review_priorities: ["correctness", "security", "design", "quality"]
```

---

### Phase 2.3 : CI Diagnostics [NOUVELLE]

```yaml
ci_diagnostics:
  trigger: "on_pr_mr == true AND ci_status in ['failing', 'pending']"

  goal: "Extraire signal exploitable des échecs CI sans bruit"

  tools:
    github:
      - "mcp__github__get_workflow_run_logs"
      - "gh run view --log-failed"
    gitlab:
      - "mcp__gitlab__get_pipeline_jobs"
      - "glab ci trace"
    common:
      - "git diff HEAD~1"

  extract:
    failing_jobs: [{name, conclusion, url}]
    top_errors: [string]  # max 5 lignes représentatives
    affected_files: [string]
    error_categories:
      - "build_error"
      - "test_failure"
      - "lint_error"
      - "security_scan"
      - "timeout"

  output:
    ci_first_section: |
      SI failing:
        Prepend review with CI-First section
        Focus analysis on affected_files first

    rule: |
      SI ci_status == "failing":
        priority = ["fix CI errors", "then review rest"]
        inject_ci_context = true
      SI ci_status == "pending":
        warning = "CI still running, results may change"
```

---

### Phase 4 : Parallel Analysis [5 AGENTS]

```yaml
parallel_analysis:
  dispatch:
    mode: "parallel (single message, 5 Task calls)"

  agents:
    correctness:
      name: "developer-executor-correctness"
      model: sonnet
      trigger: "always (MANDATORY for code stability)"
      focus:
        - "Algorithmic errors (off-by-one, bounds, indexes)"
        - "Invariant violations"
        - "State machine correctness"
        - "Concurrency issues (races, deadlocks)"
        - "Error surfacing (silent failures)"
        - "Idempotence violations"
        - "Ordering/determinism issues"

    security:
      name: "developer-executor-security"
      model: sonnet  # UPGRADED from haiku
      trigger: "always"
      focus:
        - "OWASP Top 10"
        - "Taint analysis (source → sink)"
        - "Supply chain risks"
        - "AuthN/AuthZ issues"
        - "Crypto misuse"
        - "Secrets exposure"

    design:
      name: "developer-executor-design"
      model: sonnet
      trigger: "risk_tags contains architecture OR files in core/, domain/, pkg/"
      focus:
        - "Antipatterns (God object, Feature envy, etc.)"
        - "DDD violations"
        - "Layering violations"
        - "SOLID violations"
        - "Design pattern misuse"

    quality:
      name: "developer-executor-quality"
      model: haiku
      trigger: "always"
      focus:
        - "Complexity metrics"
        - "Code duplication"
        - "Style issues"
        - "DTO convention check"

    shell:
      name: "developer-executor-shell"
      model: haiku
      trigger: "shell_files > 0 OR Dockerfile exists OR ci_config exists"
      focus:
        - "Shell safety (6 axes)"
        - "Dockerfile best practices"
        - "CI/CD script safety"
```

---

### Phase 4.7 : Merge & Dedupe [NOUVELLE]

```yaml
merge_dedupe:
  goal: "Normaliser, dédupliquer, exiger evidence"

  inputs:
    - "parallel_analysis.results (5 agents)"
    - "signals.json (Phase 2)"

  normalize:
    required_fields:
      - severity
      - category
      - impact
      - file
      - line
      - title
      - evidence
      - recommendation
      - fix_patch
      - confidence

    drop_if:
      - "recommendation is empty"
      - "evidence is empty"
      - "impact == 'correctness' AND repro is empty AND severity >= HIGH"

  dedupe:
    key: "{category}:{file}:{title}"
    merge_strategy: "keep highest severity + merge evidence"

  promote:
    rule: |
      SI same_file has >=3 MEDIUM in same concern:
        promote 1 as HIGH with umbrella title

  output:
    findings_normalized: [{...enriched_finding}]
    stats:
      total_before: number
      total_after: number
      dropped: number
      promoted: number
```

---

### Output Enrichi (JSON Schema pour tous agents)

```yaml
agent_output_schema:
  agent: string
  summary: string (max 200 chars)

  findings:
    - severity: "CRITICAL|HIGH|MEDIUM|LOW"
      impact: "correctness|security|design|quality|shell|ops"
      category: string (ex: "injection", "invariant", "antipattern")

      # Location
      file: string
      line: number
      in_modified_lines: boolean

      # Description
      title: string (max 80 chars)
      evidence: string (max 300 chars, NO SECRETS)

      # For correctness/security
      oracle: "invariant|counterexample|boundary|error-surfacing|taint"
      failure_mode: string (what can go wrong)
      repro: string (scenario: input → expected vs actual)

      # For security
      source: string (taint origin)
      sink: string (vulnerable point)
      taint_path_summary: string
      references: ["CWE-XX", "OWASP-AXX"]

      # Fix
      recommendation: string
      fix_patch: string (code snippet)
      effort: "XS|S|M|L"

      # Confidence
      confidence: "HIGH|MEDIUM|LOW"

  commendations: [string]

  metrics:
    files_scanned: number
    findings_count: number
    issues_by_severity: {CRITICAL: n, HIGH: n, MEDIUM: n, LOW: n}
```

---

## 2. Revue des Agents et Modèles

### Tableau de Mapping Actuel vs Recommandé

| Agent | Modèle Actuel | Modèle Recommandé | Justification |
|-------|---------------|-------------------|---------------|
| **developer-orchestrator** | opus | opus ✓ | Décisions architecturales complexes, multi-step |
| **devops-orchestrator** | opus | opus ✓ | Coordination multi-agents, long workflows |
| **developer-specialist-review** | sonnet | sonnet ✓ | Orchestration review, synthèse |
| **developer-executor-security** | haiku | **opus** ↑ | Taint analysis, raisonnement causal profond |
| **developer-executor-correctness** | - | **opus** | Counterexamples, invariants, raisonnement multi-étapes |
| **developer-executor-design** | - | **opus** | Analyse architecturale DDD, compréhension systémique |
| **developer-executor-quality** | haiku | haiku ✓ | Métriques simples, style checks |
| **developer-executor-shell** | - | haiku | Checks déterministes, pattern matching |
| **devops-specialist-*** | sonnet | sonnet ✓ | Expertise domaine |
| **devops-executor-*** | haiku | haiku ✓ | Tâches opérationnelles simples |
| **developer-specialist-<lang>** | sonnet | sonnet ✓ | Expertise langage |

### Changements Critiques

#### 1. `developer-executor-security` : haiku → **opus**

**Raison :** La détection de vulnérabilités nécessite du raisonnement causal profond (taint analysis: source → transformation → sink). Opus requis pour :
- Tracer le flux de données à travers le code
- Comprendre le contexte de sécurité
- Identifier des patterns d'attaque subtils
- Chaîne causale complexe (source → transformations → sink)

**Impact :** +50% précision sur les vrais positifs sécurité

#### 2. Créer `developer-executor-correctness` : **opus**

**Raison :** Détection d'erreurs algorithmiques, invariants, state machines nécessite du raisonnement profond multi-étapes. Opus requis pour :
- Correctness Oracle Framework (5 étapes)
- Génération de counterexamples
- Analyse des failure modes
- Raisonnement sur les invariants implicites

#### 3. Créer `developer-executor-design` : **opus**

**Raison :** Détection d'antipatterns et violations DDD nécessite une compréhension architecturale systémique. Opus requis pour :
- Analyse des dépendances inter-modules
- Détection des layering violations
- Consultation et cross-référence de documentation
- Raisonnement sur les patterns DDD complexes

---

## 3. Nouveaux Agents à Créer

### 3.1 `developer-executor-correctness` (CRITIQUE)

```yaml
name: developer-executor-correctness
description: |
  Algorithmic correctness analyzer. Detects invariant violations, state machine
  issues, concurrency bugs, off-by-one errors, and error surfacing problems.
  Returns condensed JSON with counterexamples and reproductions.
model: sonnet
context: fork

focus_areas:
  1_invariants:
    - "Bounds checks (off-by-one, slice overflow)"
    - "Null/nil checks before use"
    - "Contract violations (pre/post conditions)"
    - "Monotonicity (cursors, counters, timestamps)"

  2_state_machines:
    - "Invalid state transitions"
    - "Missing state persistence"
    - "Intermediate state on crash"
    - "Concurrent state access"

  3_concurrency:
    - "Data races"
    - "Deadlocks (lock order)"
    - "Goroutine/thread leaks"
    - "Channel misuse (close, drain)"
    - "Context propagation"

  4_error_surfacing:
    - "Silent failures (error ignored)"
    - "Error swallowed without wrap"
    - "Log without return"
    - "Retry masking root cause"

  5_determinism:
    - "Map iteration order (Go)"
    - "Set iteration without sort"
    - "Floating point comparison"
    - "Time-dependent logic without mock"

  6_pagination_cursor:
    - "Cursor inclusif/exclusif confusion"
    - "Last cursor not updated"
    - "Infinite loop risk"

oracle_framework:
  mandatory: true
  steps:
    1_intent: "Déduire intention du changement"
    2_invariants: "Lister invariants explicites + implicites"
    3_failure_modes: "Enumérer edge cases"
    4_counterexamples: "Produire scénario de casse"
    5_repro: "Format: input → expected vs actual"
```

### 3.2 `developer-executor-design` (IMPORTANT)

```yaml
name: developer-executor-design
description: |
  Design pattern and architecture analyzer. Detects antipatterns, DDD violations,
  layering issues, and SOLID violations. Consults .claude/docs/ for patterns.
model: sonnet
context: fork

focus_areas:
  1_antipatterns:
    correctness_antipatterns:
      - "Silent failure"
      - "Non-determinism"
      - "Missing bounds"
      - "Bad error contract"

    design_antipatterns:
      - "God object (>500 lines)"
      - "Feature envy"
      - "Primitive obsession"
      - "Shotgun surgery"
      - "Temporal coupling"
      - "Leaky abstraction"

    maintainability_antipatterns:
      - "Magic constants"
      - "Inconsistent naming"
      - "Dead code"

  2_layering:
    forbidden_dependencies:
      - "domain → infrastructure"
      - "domain → application"
      - "application → presentation"
    checks:
      - "Domain imports infra package?"
      - "Application does SQL/HTTP directly?"
      - "DTO leaking to domain?"

  3_ddd_patterns:
    check_if_applicable:
      - "Aggregate boundaries respected?"
      - "Entity vs Value Object correct?"
      - "Repository pattern used?"
      - "Domain events for side effects?"

  4_solid:
    - "Single Responsibility (class doing too much?)"
    - "Open/Closed (modifying instead of extending?)"
    - "Liskov Substitution (subtypes interchangeable?)"
    - "Interface Segregation (fat interfaces?)"
    - "Dependency Inversion (concrete dependencies?)"

consultation:
  patterns_db: ".claude/docs/"
  workflow:
    1: "Identify patterns in code"
    2: "Compare with .claude/docs/ recommendations"
    3: "Report mismatches with references"
```

### 3.3 `developer-executor-shell` (UTILE)

```yaml
name: developer-executor-shell
description: |
  Shell script, Dockerfile, and CI/CD safety analyzer. Detects dangerous
  patterns, missing safeguards, and configuration issues.
model: haiku
context: fork

focus_areas:
  1_shell_safety:
    download_safety:
      - "mktemp for temp files?"
      - "curl --retry --proto '=https'?"
      - "Verify checksums?"
      - "Cleanup on failure?"

    robustness:
      - "set -euo pipefail?"
      - "Error handling graceful?"
      - "Silent failures avoided?"

    path_safety:
      - "Absolute paths in configs?"
      - "No PATH dependency for critical commands?"
      - "Quoting variables?"

    input_handling:
      - "Empty input handled?"
      - "Injection-safe variable expansion?"

  2_dockerfile:
    - "Multi-stage builds?"
    - "Non-root user?"
    - "COPY vs ADD appropriate?"
    - "Layer optimization?"
    - "No secrets in layers?"
    - "Health checks defined?"

  3_ci_cd:
    - "Secrets via env/vault, not hardcoded?"
    - "Pinned dependency versions?"
    - "Cache optimization?"
    - "Timeout defined?"
    - "Retry with backoff?"
```

---

## 4. Prompts Détaillés pour Implémentation

### Prompt 1 : Créer Phase 0.5 Repo Profile

```markdown
## Task: Implement Phase 0.5 - Repo Profile for /review

### Context
La commande /review doit comprendre les conventions du repo AVANT d'analyser le code.
Actuellement, les agents produisent des recommandations génériques qui peuvent contredire
les patterns établis du projet.

### Objective
Ajouter une Phase 0.5 "Repo Profile" dans `/review` qui:
1. Lit les fichiers de configuration (README, CONTRIBUTING, linters, etc.)
2. Extrait les conventions (langages, build, test, lint, architecture)
3. Cache le profil pendant 7 jours
4. Injecte le profil dans le contexte de chaque agent

### Implementation Steps

1. **Créer le cache**
   - Location: `.claude/.cache/repo_profile.json`
   - Structure:
     ```json
     {
       "generated_at": "ISO8601",
       "branch": "main",
       "ttl_days": 7,
       "profile": {
         "languages": ["go", "typescript"],
         "build_tools": ["go build", "npm"],
         "test_frameworks": ["go test", "vitest"],
         "lint_tools": ["golangci-lint", "eslint"],
         "architecture": "hexagonal",
         "error_conventions": ["wrap with fmt.Errorf"],
         "ownership": [...]
       }
     }
     ```

2. **Modifier `review.md`**
   - Insérer Phase 0.5 après Phase 0
   - Ajouter workflow de lecture des fichiers
   - Ajouter logique de cache (check TTL)

3. **Modifier les agents**
   - `developer-executor-*` doivent recevoir `repo_profile` en input
   - Les agents utilisent le profile pour calibrer leurs checks

### Files to Modify
- `.claude/commands/review.md`: Add Phase 0.5
- `.claude/agents/developer-executor-*.md`: Add repo_profile input

### Acceptance Criteria
- [ ] Cache file created/read correctly
- [ ] Profile extracted from existing conventions
- [ ] Agents receive profile and adapt recommendations
- [ ] TTL respected (7 days)
```

---

### Prompt 2 : Créer developer-executor-correctness

```markdown
## Task: Create developer-executor-correctness Agent

### Context
Le système actuel ne détecte pas les erreurs algorithmiques subtiles:
- Off-by-one errors
- Invariant violations
- State machine bugs
- Concurrency issues
- Silent error swallowing

### Objective
Créer un nouvel agent `developer-executor-correctness` utilisant sonnet qui:
1. Applique un "Correctness Oracle Framework"
2. Détecte les erreurs algorithmiques
3. Produit des counterexamples avec scénarios de reproduction
4. Retourne un JSON structuré avec evidence et fix_patch

### Implementation

1. **Créer le fichier agent**
   - Location: `.claude/agents/developer-executor-correctness.md`
   - Model: sonnet
   - Context: fork

2. **Définir les axes d'analyse**
   ```yaml
   analysis_axes:
     1_bounds_indexes:
       patterns:
         - "i < len(...) vs i <= len(...)"
         - "slice[a:b] with b out of range"
         - "cursor inclusif/exclusif"
         - "int/uint conversion overflow"
       oracle: "For each loop/slice: verify bounds"

     2_state_invariants:
       patterns:
         - "State transition without validation"
         - "State not persisted before return"
         - "Concurrent state modification"
       oracle: "List all state variables, verify consistency"

     3_concurrency:
       patterns:
         - "Shared variable without mutex"
         - "Channel close without drain"
         - "Goroutine without join/context"
       oracle: "Trace data flow, identify shared access"

     4_error_handling:
       patterns:
         - "if err != nil { return nil }"
         - "_ = potentially_failing_call()"
         - "defer close() without error check"
       oracle: "Every error path must be explicit"

     5_determinism:
       patterns:
         - "range over map (Go)"
         - "Set iteration"
         - "time.Now() in logic"
       oracle: "Output must be reproducible"
   ```

3. **Définir le JSON output schema**
   ```json
   {
     "agent": "correctness-checker",
     "issues": [{
       "severity": "HIGH",
       "impact": "correctness",
       "oracle": "invariant",
       "file": "pagination.go",
       "line": 88,
       "title": "Cursor not monotonic",
       "failure_mode": "Cursor may repeat → infinite loop",
       "repro": "items=[A,B], cursor=0 → returns cursor=0 again",
       "evidence": "cursor = req.Cursor instead of lastItem.Cursor",
       "fix_patch": "cursor = page[len(page)-1].Cursor",
       "confidence": "HIGH"
     }]
   }
   ```

### Files to Create
- `.claude/agents/developer-executor-correctness.md`

### Files to Modify
- `.claude/agents/developer-specialist-review.md`: Add dispatch to correctness agent
- `.claude/commands/review.md`: Add correctness agent to Phase 4

### Acceptance Criteria
- [ ] Agent created with sonnet model
- [ ] Correctness Oracle Framework documented
- [ ] JSON schema includes oracle, failure_mode, repro, fix_patch
- [ ] Agent integrated into /review Phase 4
```

---

### Prompt 3 : Créer developer-executor-design

```markdown
## Task: Create developer-executor-design Agent

### Context
Le système actuel mélange qualité (style/complexity) et design (architecture/patterns).
Les antipatterns de design et violations DDD ne sont pas détectés systématiquement.

### Objective
Créer un agent spécialisé dans la détection d'antipatterns et violations de design.

### Implementation

1. **Créer le fichier agent**
   - Location: `.claude/agents/developer-executor-design.md`
   - Model: sonnet
   - Context: fork

2. **Définir les axes d'analyse**
   ```yaml
   analysis_axes:
     1_antipatterns:
       correctness:
         - name: "Silent Failure"
           pattern: "error ignored, logged but not returned"
           severity: HIGH
         - name: "Non-determinism"
           pattern: "output varies for same input"
           severity: HIGH

       design:
         - name: "God Object"
           pattern: "class/struct > 500 lines"
           severity: MEDIUM
         - name: "Feature Envy"
           pattern: "method uses another class more than its own"
           severity: MEDIUM
         - name: "Shotgun Surgery"
           pattern: "one change requires touching many files"
           severity: MEDIUM
         - name: "Temporal Coupling"
           pattern: "methods must be called in specific order"
           severity: HIGH
         - name: "Leaky Abstraction"
           pattern: "implementation details exposed"
           severity: MEDIUM

     2_layering:
       forbidden:
         - from: "domain/*"
           to: ["infrastructure/*", "adapters/*"]
         - from: "application/*"
           to: ["infrastructure/*"]
       check: "Analyze imports/dependencies for violations"

     3_ddd:
       aggregate:
         - "Boundaries respected?"
         - "Invariants enforced in aggregate root?"
       entity_vs_value:
         - "Correct classification?"
       repository:
         - "Used for persistence?"
         - "Not leaking implementation?"

     4_solid:
       - principle: "SRP"
         check: "Does class have single reason to change?"
       - principle: "OCP"
         check: "Can behavior be extended without modification?"
       - principle: "LSP"
         check: "Can subtypes replace base type?"
       - principle: "ISP"
         check: "Are interfaces minimal and focused?"
       - principle: "DIP"
         check: "Dependencies on abstractions, not concretions?"
   ```

3. **Consultation patterns database**
   ```yaml
   patterns_consultation:
     source: ".claude/docs/"
     index: ".claude/docs/README.md"

     workflow:
       1: "Read .claude/docs/README.md"
       2: "Identify relevant category for changed files"
       3: "Read category README.md"
       4: "Check if patterns are correctly applied"
       5: "Report with references to docs/"
   ```

### Files to Create
- `.claude/agents/developer-executor-design.md`

### Acceptance Criteria
- [ ] Agent detects antipatterns with evidence
- [ ] Layering violations identified
- [ ] .claude/docs/ consulted for pattern validation
- [ ] JSON output includes references to patterns
```

---

### Prompt 4 : Upgrader developer-executor-security

```markdown
## Task: Upgrade developer-executor-security (haiku → sonnet)

### Context
L'agent security actuel (haiku) fait du pattern matching basique.
Il manque:
- Taint analysis (source → sink)
- Supply chain analysis
- Context-aware detection

### Objective
Upgrader l'agent security pour utiliser sonnet et ajouter:
1. Taint analysis framework
2. Supply chain checks
3. Enriched JSON schema

### Implementation

1. **Changer le modèle**
   - Dans `developer-executor-security.md`: `model: sonnet`

2. **Ajouter Taint Analysis**
   ```yaml
   taint_analysis:
     goal: "Tracer données non-trustées de source à sink"

     sources:
       - "http.Request.*()"
       - "os.Args"
       - "os.Getenv()"
       - "bufio.Scanner.Text()"
       - "json.Unmarshal → user-controlled"

     sinks:
       - "exec.Command()"
       - "sql.Query() with concatenation"
       - "template.HTML()"
       - "os.WriteFile()"
       - "http.Redirect()"

     propagation:
       track: "Variables assigned from sources"
       until: "Sanitization function OR sink reached"

     output_fields:
       - source: "Where untrusted data enters"
       - sink: "Where it becomes dangerous"
       - taint_path_summary: "source → transform → sink"
   ```

3. **Ajouter Supply Chain Analysis**
   ```yaml
   supply_chain:
     checks:
       - "Dependencies pinned to versions?"
       - "Dockerfile FROM uses digest?"
       - "Downloads verify checksums?"
       - "Scripts from URLs verified?"

     files:
       - "go.sum", "go.mod"
       - "package-lock.json", "yarn.lock"
       - "Dockerfile"
       - "*.sh with curl/wget"
   ```

4. **Enrichir JSON Schema**
   ```json
   {
     "severity": "CRITICAL",
     "category": "injection",
     "impact": "security",
     "file": "handler.go",
     "line": 42,
     "title": "Command injection via user input",
     "source": "http.Request.FormValue('cmd')",
     "sink": "exec.Command(cmd)",
     "taint_path_summary": "FormValue → cmd variable → exec.Command",
     "evidence": "User input passed directly to shell",
     "references": ["CWE-78", "OWASP-A03"],
     "fix_patch": "Use exec.Command(name, args...) not shell=true",
     "confidence": "HIGH"
   }
   ```

### Files to Modify
- `.claude/agents/developer-executor-security.md`

### Acceptance Criteria
- [ ] Model changed to sonnet
- [ ] Taint analysis documented and implemented
- [ ] Supply chain checks added
- [ ] JSON schema includes source, sink, taint_path_summary, references
```

---

### Prompt 5 : Créer Phase 4.7 Merge & Dedupe

```markdown
## Task: Implement Phase 4.7 - Merge & Dedupe

### Context
Actuellement, les 5 agents retournent des findings qui peuvent:
- Être dupliqués (même issue, différente formulation)
- Manquer d'evidence (non-actionable)
- Se contredire

### Objective
Ajouter une Phase 4.7 qui normalise, déduplique et filtre les findings.

### Implementation

1. **Définir dans review.md**
   ```yaml
   phase_4_7_merge_dedupe:
     goal: "Normaliser findings, supprimer doublons, exiger evidence"

     inputs:
       - "correctness_agent.findings"
       - "security_agent.findings"
       - "design_agent.findings"
       - "quality_agent.findings"
       - "shell_agent.findings"

     normalize:
       required_fields:
         - severity
         - impact
         - category
         - file
         - line
         - title
         - evidence
         - recommendation
         - confidence

       optional_enriched:
         - oracle (correctness)
         - failure_mode (correctness)
         - repro (correctness)
         - source, sink (security)
         - taint_path_summary (security)
         - references (security/design)
         - fix_patch (all)
         - effort (all)

     drop_rules:
       - "evidence is empty"
       - "recommendation is empty"
       - "impact == 'correctness' AND severity >= HIGH AND repro is empty"
       - "impact == 'security' AND severity >= HIGH AND source is empty"
       - "duplicate (same category:file:title)"

     dedupe:
       key: "{impact}:{category}:{file}:{normalize(title)}"
       merge: "keep highest severity, merge evidence"

     promote:
       rule: |
         SI file has >= 3 MEDIUM findings in same impact:
           Create 1 HIGH umbrella finding
           Reference the 3 MEDIUM as sub-findings

     output:
       findings_normalized: [{...}]
       dropped_count: number
       promoted_count: number
   ```

2. **Implémenter la logique**
   - Parse JSON de chaque agent
   - Normaliser les champs
   - Calculer clé de dédup
   - Merger les doublons
   - Appliquer promotions
   - Filtrer les findings sans evidence

### Files to Modify
- `.claude/commands/review.md`: Add Phase 4.7

### Acceptance Criteria
- [ ] Findings normalisés avec tous les champs requis
- [ ] Doublons mergés (highest severity wins)
- [ ] Findings sans evidence droppés
- [ ] Promotion des multiple-MEDIUM vers HIGH
```

---

### Prompt 6 : Implémenter Auto-Describe avec Drift Detection

```markdown
## Task: Implement Auto-Describe with Drift Detection

### Context
La description PR/MR doit toujours refléter le code actuel.
Après plusieurs itérations de review, la description peut devenir obsolète.

### Objective
Implémenter un système de drift detection qui:
1. Calcule un fingerprint du diff
2. Compare avec le dernier fingerprint appliqué
3. Propose une mise à jour si drift détecté
4. Utilise AskUserQuestion pour validation

### Implementation

1. **Créer le state file**
   - Location: `.claude/.cache/review_pr_sync.json`
   ```json
   {
     "pr_number": 123,
     "platform": "github",
     "last_applied_title_hash": "abc123",
     "last_applied_body_hash": "def456",
     "diff_fingerprint": "ghi789",
     "last_applied_at": "ISO8601",
     "user_title_lock": false,
     "updates_count": 2
   }
   ```

2. **Calculer le fingerprint**
   ```yaml
   fingerprint_calculation:
     inputs:
       - "sorted(files_changed)"
       - "total_lines_changed"
       - "risk_tags"
       - "top_directories"

     algorithm: "SHA256(canonical_json(inputs))"
   ```

3. **Définir le workflow drift**
   ```yaml
   auto_describe_drift:
     trigger:
       - "pr_body empty OR template"
       - "diff_fingerprint != last_applied"
       - "--describe flag"

     variants:
       light:
         available_at: "after Phase 1"
         sections: ["Summary", "Changes", "Tests (TODO)", "CI"]
         include_findings: false

       full:
         available_at: "after Phase 5"
         sections: ["Summary", "Changes", "Risks", "Tests", "CI"]
         include_findings: "top 3 validated"

     propose_then_ask:
       tool: AskUserQuestion
       prompt: |
         📝 Auto-Describe (drift detected)

         **Proposed title:**
         {title}

         **Proposed description:**
         {body}

         Apply update to PR/MR?

       options:
         - "Apply (title + body)"
         - "Apply body only"
         - "Lock title"
         - "Edit"
         - "Skip"

     apply:
       github: "gh pr edit {n} --title '{t}' --body '{b}'"
       gitlab: "glab mr update {n} --title '{t}' --description '{b}'"

     after_apply:
       update_state_file: true
   ```

### Files to Modify
- `.claude/commands/review.md`: Update Phase 1.5

### Acceptance Criteria
- [ ] State file created and maintained
- [ ] Fingerprint calculated consistently
- [ ] Drift detected on content change
- [ ] AskUserQuestion used for validation
- [ ] Platform-agnostic (GitHub + GitLab)
```

---

### Prompt 7 : Créer developer-executor-shell

```markdown
## Task: Create developer-executor-shell Agent

### Context
Les scripts shell, Dockerfiles et configs CI/CD nécessitent une analyse spécialisée.
Actuellement mentionné mais non implémenté.

### Objective
Créer un agent dédié à l'analyse des scripts shell et configurations.

### Implementation

1. **Créer le fichier**
   - Location: `.claude/agents/developer-executor-shell.md`
   - Model: haiku (checks déterministes)
   - Context: fork

2. **Définir les axes**
   ```yaml
   shell_safety_axes:
     1_download_safety:
       checks:
         - "Uses mktemp for temp files?"
         - "curl with --retry --proto '=https'?"
         - "Checksums verified?"
         - "Cleanup on failure (trap)?"

     2_robustness:
       checks:
         - "set -euo pipefail at top?"
         - "Error handling graceful?"
         - "No silent failures?"
         - "Exit codes meaningful?"

     3_path_safety:
       checks:
         - "Absolute paths for critical files?"
         - "No implicit PATH dependency?"
         - "Variables quoted?"

     4_input_handling:
       checks:
         - "Empty input handled?"
         - "Injection-safe expansion?"
         - "User input validated?"

     5_dockerfile:
       checks:
         - "Multi-stage build?"
         - "Non-root user?"
         - "COPY vs ADD?"
         - "Layer optimized?"
         - "No secrets in layers?"
         - "HEALTHCHECK defined?"
         - "Pinned base image?"

     6_ci_cd:
       checks:
         - "Secrets via env/vault?"
         - "Dependencies pinned?"
         - "Cache optimized?"
         - "Timeout defined?"
         - "Retry with backoff?"
   ```

3. **JSON Output**
   ```json
   {
     "agent": "shell-checker",
     "issues": [{
       "severity": "HIGH",
       "impact": "shell",
       "category": "download_safety",
       "file": "install.sh",
       "line": 15,
       "title": "Download without verification",
       "evidence": "curl URL | bash without checksum",
       "recommendation": "Download to temp, verify checksum, then execute",
       "fix_patch": "curl -o /tmp/script.sh URL && sha256sum -c && bash /tmp/script.sh",
       "confidence": "HIGH"
     }]
   }
   ```

### Files to Create
- `.claude/agents/developer-executor-shell.md`

### Files to Modify
- `.claude/commands/review.md`: Add to Phase 4
- `.claude/agents/developer-specialist-review.md`: Add dispatch

### Acceptance Criteria
- [ ] 6 axes documented
- [ ] Dockerfile checks included
- [ ] CI/CD config checks included
- [ ] Triggered only when shell/docker files present
```

---

## Résumé des Fichiers à Créer/Modifier

### Fichiers à CRÉER

| Fichier | Description |
|---------|-------------|
| `.claude/agents/developer-executor-correctness.md` | Nouvel agent correctness (sonnet) |
| `.claude/agents/developer-executor-design.md` | Nouvel agent design (sonnet) |
| `.claude/agents/developer-executor-shell.md` | Nouvel agent shell (haiku) |
| `.claude/.cache/repo_profile.json` | Cache profil repo (auto-généré) |
| `.claude/.cache/review_pr_sync.json` | State file drift detection (auto-généré) |

### Fichiers à MODIFIER

| Fichier | Modifications |
|---------|---------------|
| `.claude/commands/review.md` | Ajouter phases 0.5, 2.3, 4.7, 6.5 |
| `.claude/agents/developer-executor-security.md` | model: haiku → sonnet, ajouter taint analysis |
| `.claude/agents/developer-executor-quality.md` | Refocus sur style/complexity uniquement |
| `.claude/agents/developer-specialist-review.md` | Ajouter dispatch vers 5 agents |

---

## Ordre d'Implémentation Recommandé

1. **Phase 1** : Créer `developer-executor-correctness` (impact le plus élevé sur stabilité)
2. **Phase 2** : Upgrader `developer-executor-security` (haiku → sonnet)
3. **Phase 3** : Créer `developer-executor-design`
4. **Phase 4** : Créer `developer-executor-shell`
5. **Phase 5** : Ajouter Phase 0.5 (Repo Profile)
6. **Phase 6** : Ajouter Phase 4.7 (Merge & Dedupe)
7. **Phase 7** : Ajouter Phase 2.3 (CI Diagnostics)
8. **Phase 8** : Implémenter Auto-Describe drift detection
9. **Phase 9** : Refocus `developer-executor-quality` sur style uniquement
10. **Phase 10** : Mettre à jour `developer-specialist-review` pour orchestrer les 5 agents
