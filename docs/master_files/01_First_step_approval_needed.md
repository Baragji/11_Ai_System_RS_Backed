# Phase 0 – Foundation & Approval Playbook

> **Purpose**: Establish the non-negotiable groundwork that must be verified before any feature delivery begins. Exiting Phase 0 signals that security, compliance, observability, and AI-governance controls are production-grade and auditable from day zero.

## 0.1 Governance Activation & Roles
- **Executive sponsor** formally designates Product, Security, and Compliance owners; RACI logged in Confluence.
- **Architecture decision board (ADB)** charter approved; weekly review cadence defined.
- **Documentation baseline** created in repo (`/docs/governance/`), including ADR template, RFC-9457 error contract reference, and ISO/IEC 42001 control mapping spreadsheet.
- **Success metrics** published:
  - Mean time to detect (MTTD) incidents ≤ 5 min via telemetry alerts.
  - Mean time to remediate (MTTR) critical workflow failures ≤ 60 min with automated rollback.
  - Zero high/critical findings in SAST/DAST/security scanners at merge gates.
  - 100% trace coverage for Planner→Coder→Critic workflows via OpenTelemetry spans.

## 0.2 Secure Environment Provisioning
- **Infrastructure as Code**: Terraform plans for dev/stage/prod VPCs, private subnets, Postgres, Redis, Kafka, and OpenTelemetry Collector reviewed and signed off by ADB.
- **Secrets management**: HashiCorp Vault or AWS Secrets Manager baseline with short-lived tokens; human access audited via IAM Identity Center / SSO.
- **Network posture**: Zero-trust segmentation (mTLS between services, mutual auth for Kafka/Otel collectors). Security team validates using automated policy-as-code (OPA/Conftest) run in CI.
- **Endpoint baselines**: Hardened AMIs (CIS Level 1) or container base images signed via Sigstore Cosign; SBOMs stored in artifact registry.

## 0.3 Toolchain & Repository Hardening
- **Monorepo initialization** with commit signing (GPG/Sigstore), branch protection (require PR reviews, status checks, security approval for privileged areas).
- **CI/CD bootstrap** (GitHub Actions or GitLab CI):
  - Pipeline stages: lint/format → unit tests → integration tests → SAST (CodeQL/Semgrep) → dependency scan (Trivy, Snyk) → secrets scan (ggshield) → SBOM generation (CycloneDX 1.6) → SLSA v1 provenance attestation → IaC policy checks.
  - Pipelines run on hardened, ephemeral runners with network egress controls.
- **Artifact management**: Container images pushed to registry with provenance attestations; immutable tags enforced.

## 0.4 Observability, Logging & Error Contracts
- **OpenTelemetry** SDK and Collector configs drafted for backend, agents, and frontend Node adapter; traces exported to Tempo/Jaeger, metrics to Prometheus, logs to Loki/Elastic.
- **RFC 9457 templates** implemented in shared library (`packages/errors`) with localization-ready problem types.
- **Alerting policy**: PagerDuty/OPSGenie runbooks linked; SLO dashboard (availability ≥ 99.5%, orchestration success ≥ 95%).
- **Data retention**: Log/trace retention policy aligned with GDPR & EU AI Act transparency (≥ 6 months, redact PII).

## 0.5 AI Governance & Dataset Controls
- **Model registry** established (Weights & Biases or MLflow) with versioning, lineage, and approval workflow.
- **Dataset inventory**: Datasets cataloged in data governance tool (e.g., Collibra); provenance, consent, and usage rights documented.
- **Evaluation harness**: Offline benchmark suite (security prompts, alignment checks, hallucination tests) defined; baseline success thresholds documented.
- **Policy enforcement**: Guardrail layer (e.g., Guardrails AI, Azure Content Safety, or custom regex/embedding filters) selected with blocking/soft response modes.

## 0.6 Risk & Compliance Checkpoints
- **EU AI Act readiness** checklist executed; transparency artifacts (model cards, data sheets) templates reviewed.
- **ISO/IEC 42001** control mapping linked to work items in backlog (Jira/Azure DevOps) with acceptance criteria.
- **OWASP ASVS v5 & LLM Top 10** mitigations mapped to architecture components; red-team playbook drafted.
- **Business continuity**: RTO ≤ 2h, RPO ≤ 15m defined; backup/restore scripts smoke-tested in sandbox.

## 0.7 Exit Criteria (All Must Pass)
1. ADB sign-off on Terraform plan, security architecture diagram, and orchestration state design.
2. CI/CD pipeline run demonstrates green status with all security scanners and provenance attestations stored.
3. OpenTelemetry traces captured for synthetic Planner→Coder→Critic workflow hitting mock services, verifying RFC 9457 responses on fault injection.
4. Vault/secrets rotation exercise executed with audit logs retained.
5. AI evaluation harness executes baseline tests against mock model endpoint with guardrails enforcing blocklists.
6. Compliance officer approves documentation pack: governance charter, control matrix, runbooks, and data processing records.

_No feature delivery or agent implementation may begin until Phase 0 exit is documented in the repo and acknowledged by Security & Compliance owners._
