# Repository Overview

## Name
- ai-platform-monorepo

## Structure
- Root package.json (npm workspaces)
- apps/api: Fastify TypeScript API service
- .github/workflows/security.yml: Security pipeline (CodeQL, Semgrep, npm audit, container SBOM, Trivy, Cosign, SLSA)
- Dockerfile: Multi-stage build; runtime uses distroless node (nodejs20-debian12)
- k8s/: Manifests for Istio, observability, security
- observability/: Prometheus, Grafana, logging, OTEL collector
- terraform/: Infra modules (EKS, VPC, Vault, Redis, RDS, Kafka, OTEL)
- security/: OPA policies, RBAC, Vault
- db/maintenance: backup/restore scripts
- docs/: Plans, logs, and implementation notes

## Languages & Tooling
- TypeScript (Node 20), Fastify, Zod/Joi
- OpenTelemetry instrumentation
- PostgreSQL, Redis, Kafka clients
- ESLint, ts-node, tsc

## Build & Run
- Build: npm run build (workspace apps/api)
- Start: npm run start (production node dist/index.js)
- Docker: multi-stage build; distroless runtime with Node entrypoint

## Security Pipeline Highlights
1. CodeQL analysis (JavaScript)
2. Semgrep with SARIF upload
3. Dependency Security
   - npm ci + npm audit --audit-level=high
   - Trivy filesystem scan (SARIF upload)
4. Container Build & Scan
   - docker buildx build & push (ghcr.io/prod-ai/platform-api)
   - CycloneDX SBOM (npm) artifact
   - Syft image SBOM (CycloneDX) + JSON license diagnostics
   - Trivy image scan (HIGH,CRITICAL; exit-code=1)
   - Cosign sign + SBOM attest
5. SLSA provenance generation
6. Policy Gate: cosign verify + verify-attestation

## Notable Configs
- OpenTelemetry exporter configs via deps (grpc OTLP)
- Fastify security: helmet, rate-limit, sensible
- Database migrations: node-pg-migrate

## Recent Changes (by assistant)
- Dockerfile switched to distroless runtime (gcr.io/distroless/nodejs20-debian12)
- Added license diagnostics to CI: Syft JSON printed + uploaded
- Fixed CycloneDX SBOM generation command compatibility (no --flatten)

## SBOM & License Notes
- CycloneDX npm SBOM produced at build (sbom.cdx.json)
- Image SBOM via Syft (image.cdx.json) + detailed JSON (image.syft.json)
- License diagnostics prints name/version/licenses/paths to identify GPL/LGPL sources

## Next Steps
- If license policy still fails, consider Chainguard node runtime or scope deny-licenses to app deps only.