# Production Code Validation Checklist

## 1. TERRAFORM INFRASTRUCTURE VALIDATION

### Syntax & Structure
```bash
# Navigate to terraform directory
cd terraform/

# Check syntax
terraform fmt -check
terraform validate

# Check for security issues
tfsec .
checkov -d .

# Plan without applying
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | jq '.planned_values'
```

### What to Look For:
- **Hard-coded secrets** in .tf files (FAIL if found)
- **Public subnets** for databases (FAIL - should be private)
- **Unencrypted storage** (FAIL - all RDS/EBS should have encryption)
- **Missing backup configurations** (FAIL for production)
- **Overly permissive security groups** (check for 0.0.0.0/0)

## 2. KUBERNETES MANIFEST VALIDATION

### Syntax & Security
```bash
# Validate all K8s manifests
find k8s/ -name "*.yaml" -exec kubectl apply --dry-run=client -f {} \;

# Security policy validation
kubectl apply --dry-run=server -f k8s/security/

# Check for security issues
kubesec scan k8s/observability/otel-collector.yaml
kube-score score k8s/observability/*.yaml
```

### What to Look For:
- **Missing resource limits** (CPU/memory - FAIL)
- **Running as root** (securityContext.runAsUser: 0 - FAIL)
- **Privileged containers** (privileged: true - FAIL)
- **Missing readiness/liveness probes** (FAIL for production)
- **Hardcoded passwords** in ConfigMaps (FAIL)

## 3. APPLICATION CODE VALIDATION

### TypeScript Compilation & Dependencies
```bash
# Install dependencies
npm install

# Check for security vulnerabilities
npm audit --audit-level=high
npm audit signatures

# TypeScript compilation
cd apps/api
npm run build

# Check for unused dependencies
npx depcheck

# Security linting
npx eslint src/ --ext .ts
```

### Code Quality Checks
```bash
# Run tests (if they exist)
npm test

# Check test coverage
npm run test:coverage

# Check for code smells
npx sonarjs-cli src/
```

### What to Look For:
- **High/critical npm audit findings** (FAIL)
- **TypeScript compilation errors** (FAIL)
- **Missing input validation** on API endpoints (FAIL)
- **Database queries without parameterization** (SQL injection risk - FAIL)
- **Secrets in environment variables** without proper vault integration (FAIL)

## 4. DATABASE SCHEMA VALIDATION

### SQL Syntax & Security
```bash
# Check SQL syntax (requires psql)
cd apps/api/migrations/
for file in *.sql; do
  psql --echo-errors --quiet -f "$file" postgres://dummy 2>&1 | grep -i error
done

# Check for security issues in schemas
grep -r "WITHOUT GRANT" migrations/ # Should find RLS policies
grep -r "CREATE USER\|CREATE ROLE" migrations/ # Check privilege escalation
```

### What to Look For:
- **Missing Row Level Security (RLS)** on multi-tenant tables (FAIL)
- **Overly permissive grants** (GRANT ALL - investigate)
- **Missing indexes** on frequently queried columns (performance issue)
- **No audit columns** (created_at, updated_at, created_by - investigation needed)

## 5. SECURITY CONFIGURATION VALIDATION

### OPA Policy Testing
```bash
# Test OPA policies
cd security/opa/
opa test . -v

# Validate Rego syntax
opa fmt api-authorization.rego --diff
```

### Vault Policy Testing
```bash
# Validate Vault policies
cd security/vault/policies/
vault policy fmt platform-api.hcl
# Check for overly broad permissions
grep -i "\*" *.hcl
```

## 6. OBSERVABILITY CONFIGURATION VALIDATION

### Prometheus Config
```bash
# Validate Prometheus config
promtool check config observability/prometheus/prometheus.yml
promtool check rules observability/prometheus/recording-rules.yml
```

### OpenTelemetry Config
```bash
# Validate OTel collector config
docker run --rm -v $(pwd)/observability:/cfg otel/opentelemetry-collector:latest \
  --config-validate --config=/cfg/otel-collector-config.yaml
```

### Grafana Dashboards
```bash
# Check dashboard JSON validity
cd observability/grafana/dashboards/
for dashboard in *.json; do
  echo "Validating $dashboard"
  jq . "$dashboard" > /dev/null && echo "✓ Valid JSON" || echo "✗ Invalid JSON"
done
```

## 7. REAL PRODUCTION READINESS TESTS

### Load Testing Setup
```bash
# Create a simple load test to verify the health endpoints work
cat > load-test.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export default function () {
  const response = http.get('http://localhost:3000/health');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
}
EOF

# Run load test (requires k6)
k6 run --vus 10 --duration 30s load-test.js
```

### Security Penetration Testing
```bash
# Install and run basic security scan
npm install -g @zaproxy/zap-cli
zap-cli start --start-options '-config api.disablekey=true'
zap-cli spider http://localhost:3000
zap-cli active-scan http://localhost:3000
zap-cli report -o security-report.html -f html
```

## 8. INTEGRATION TESTING CHECKLIST

### Database Connections
- Can the API actually connect to Postgres?
- Do migrations run without errors?
- Are connection pools properly configured?

### Redis Integration
- Can the API connect to Redis with TLS?
- Do cache operations work correctly?
- Are TTL policies being enforced?

### Kafka Integration
- Can producers send messages?
- Do consumers receive messages?
- Is schema registry integration working?

## PRODUCTION READINESS SCORECARD

| Component | Status | Critical Issues Found |
|-----------|--------|---------------------|
| Terraform | ⏳ Testing | |
| K8s Manifests | ⏳ Testing | |
| API Code | ⏳ Testing | |
| Database Schema | ⏳ Testing | |
| Security Policies | ⏳ Testing | |
| Observability | ⏳ Testing | |

## FAILURE CRITERIA (IMMEDIATE REJECTION)

- Any high/critical security vulnerabilities
- Hardcoded secrets or credentials
- Database without encryption at rest
- Services running as root user
- Missing input validation on API endpoints
- SQL injection vulnerabilities
- Missing authentication/authorization
- No observability instrumentation
- Terraform that creates public databases
- Missing backup/disaster recovery

## COMMANDS TO RUN EVERYTHING

```bash
#!/bin/bash
# Production validation script

echo "🔍 Validating Terraform..."
cd terraform && terraform validate && tfsec . && cd ..

echo "🔍 Validating Kubernetes..."
find k8s/ -name "*.yaml" -exec kubectl apply --dry-run=client -f {} \;

echo "🔍 Validating Application..."
npm audit --audit-level=high && cd apps/api && npm run build && cd ../..

echo "🔍 Validating Database..."
# Add your database validation commands here

echo "🔍 Security scan..."
npm install -g @zaproxy/zap-cli
# Add security scanning commands

echo "✅ Validation complete - check output for failures"
```

Run this validation script and anything that fails is not production-ready.