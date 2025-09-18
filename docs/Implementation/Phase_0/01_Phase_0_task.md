# STOP FUCKING AROUND - IMPLEMENT PHASE 0 NOW

You are a senior DevSecOps engineer who has been tasked with ACTUALLY IMPLEMENTING Phase 0, not just writing more documentation about it. Your job is to deliver PRODUCTION-READY code, configurations, and artifacts - not plans, not explanations, not theoretical bullshit.

## IMMEDIATE DELIVERABLES REQUIRED

You MUST create actual, working artifacts for each of these. No more planning - IMPLEMENT:

### 1. TERRAFORM INFRASTRUCTURE CODE
Create complete Terraform modules for:
- VPC with private subnets and security groups
- RDS Postgres with encryption and backups
- ElastiCache Redis with TLS
- MSK Kafka with SASL/SCRAM
- EKS cluster with pod security standards
- Vault deployment with auto-unseal
- OpenTelemetry Collector with proper configs

**DELIVER**: Complete .tf files with variables, outputs, and provider configs. PRODUCTION-GRADE ONLY.

### 2. KUBERNETES MANIFESTS AND HELM CHARTS
Create deployment configs for:
- OpenTelemetry Collector with OTLP receivers
- Prometheus + Grafana stack
- Jaeger for distributed tracing
- Service mesh (Istio) with mTLS
- OPA Gatekeeper policies
- Pod Security Policies/Standards
- Network Policies for zero-trust

**DELIVER**: YAML files and Helm charts that actually deploy and work.

### 3. CI/CD PIPELINE CODE
Build GitHub Actions workflows that:
- Run SAST scans (CodeQL, Semgrep)
- Execute dependency scans (Trivy, npm audit)
- Generate SBOMs (CycloneDX format)
- Create SLSA provenance attestations
- Sign containers with Cosign
- Enforce security gates (fail on high/critical)

**DELIVER**: Complete .github/workflows/*.yml files, not pseudo-code.

### 4. APPLICATION SCAFFOLDING WITH SECURITY
Create the actual monorepo structure with:
- Fastify API with RFC 9457 error handling middleware
- OpenTelemetry instrumentation configured
- Database connection with connection pooling
- Redis client with TLS
- Kafka producer/consumer with SASL
- Health check endpoints with dependency validation
- Input validation with Joi/Zod schemas

**DELIVER**: Working TypeScript/Node.js code that compiles and runs.

### 5. OBSERVABILITY CONFIGURATION FILES
Provide actual config files for:
- OpenTelemetry Collector (complete YAML)
- Prometheus scrape configs and recording rules
- Grafana dashboards (JSON exports)
- Alertmanager notification rules
- Log aggregation pipeline configs

**DELIVER**: Production-ready configuration files, not examples.

### 6. SECURITY POLICIES AS CODE
Create enforceable policies:
- OPA Rego policies for API authorization
- Kubernetes security policies (Gatekeeper)
- Network policies for service-to-service communication
- Vault policies for secret access
- RBAC configurations

**DELIVER**: Working policy files that enforce actual security controls.

### 7. DATABASE SCHEMAS AND MIGRATIONS
Build the actual database foundation:
- SQL schema files for all core tables
- Database migration scripts (using node-pg-migrate)
- Row-level security policies
- Indexes and constraints for performance
- Backup and restore procedures

**DELIVER**: SQL files that create a working database schema.

## TECHNICAL REQUIREMENTS

### NO FUCKING PLACEHOLDERS
- Every config file must have real values, not TODOs
- All code must compile/validate without errors
- Database schemas must be syntactically correct SQL
- Kubernetes manifests must pass `kubectl apply --dry-run`
- Terraform must pass `terraform plan` validation

### PRODUCTION SECURITY STANDARDS
- All secrets must use proper secret management (Vault paths, K8s secrets)
- Network communications must be TLS/mTLS only
- Container images must be signed and have SBOMs
- All services must have health checks and graceful shutdown
- Input validation must be comprehensive with proper error responses

### REAL INTEGRATION POINTS
- OpenTelemetry must actually export to Jaeger/Prometheus
- Kafka must authenticate with SASL and use schema registry
- Database connections must use connection pooling and SSL
- Redis must use TLS and authentication
- API must integrate with actual IdP (OIDC configuration)

## SPECIFIC OUTPUT FORMAT

For each deliverable, provide:

1. **File path and name** (exact repository structure)
2. **Complete file content** (copy-pasteable, working code)
3. **Configuration values** (real, not placeholder)
4. **Dependencies and prerequisites** (specific versions)
5. **Validation commands** (how to test it works)

## EXAMPLE OF WHAT I EXPECT

Instead of "configure OpenTelemetry Collector," I want:

```yaml
# /k8s/observability/otel-collector.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
data:
  otel-collector-config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
            tls:
              cert_file: /etc/certs/server.crt
              key_file: /etc/certs/server.key
    processors:
      batch:
        timeout: 1s
        send_batch_size: 1024
    exporters:
      jaeger:
        endpoint: jaeger-collector.observability.svc.cluster.local:14250
        tls:
          insecure: false
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [jaeger]
---
apiVersion: apps/v1
kind: Deployment
[COMPLETE DEPLOYMENT MANIFEST HERE]
```

## STOP BEING THEORETICAL - BUILD THE FOUNDATION

I don't want more explanations about what Phase 0 should include. I want you to IMPLEMENT Phase 0 with actual, working, production-grade code and configurations that I can deploy immediately.

Your response should contain ONLY executable artifacts - code, configs, and manifests. No more planning documents, no more architectural discussions, no more theoretical frameworks.

BUILD THE FUCKING FOUNDATION NOW.