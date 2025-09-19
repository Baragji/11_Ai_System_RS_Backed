# CI/CD Pipeline Documentation

## Overview

The security.yml workflow implements a production-grade CI/CD pipeline with:
- Static analysis (CodeQL, Semgrep)
- Dependency security scanning (npm audit, Trivy)
- Container image building and scanning
- SBOM generation (CycloneDX format)
- Container signing with Cosign
- SLSA provenance generation
- Policy gate validation

## Container Registry Setup

The workflow pushes container images to GitHub Container Registry (GHCR) at:
```
ghcr.io/{repository_owner}/platform-api
```

For this repository (Baragji/11_Ai_System_RS_Backed), images will be pushed to:
```
ghcr.io/baragji/platform-api
```

## Required Secrets

### Container Signing (Cosign)
The workflow requires the following secrets for container signing:

1. **COSIGN_PRIVATE_KEY**: Your Cosign private key (PEM format)
2. **COSIGN_PASSWORD**: Password for the Cosign private key

To generate these:
```bash
# Generate a key pair
cosign generate-key-pair

# Add cosign.key contents to COSIGN_PRIVATE_KEY secret
# Add the password used during generation to COSIGN_PASSWORD secret
```

### GitHub Container Registry Authentication
The workflow uses the built-in `GITHUB_TOKEN` for authentication to GHCR, which has the required `packages: write` permission.

No additional secrets are needed for GHCR authentication when pushing to the same repository owner's namespace.

## Workflow Behavior

### On Pull Requests
- Runs static analysis and security scans
- Builds the container image but does NOT push it
- Skips image scanning, signing, and SLSA provenance generation

### On Push to Main
- Runs all security scans
- Builds and pushes the container image to GHCR
- Generates SBOM and performs image scanning
- Signs the container with Cosign
- Generates SLSA provenance
- Validates signatures and attestations in policy gate

## Troubleshooting

### Permission Errors
If you see "permission_denied: The requested installation does not exist":

1. Ensure the workflow has `packages: write` permission (already configured)
2. Verify you're pushing to the correct namespace (ghcr.io/{your_repository_owner}/platform-api)
3. Check that the GITHUB_TOKEN has not been overridden in repository settings

### Missing Cosign Secrets
If Cosign steps fail:
1. Generate a Cosign key pair as shown above
2. Add the private key and password as repository secrets
3. Never commit the private key to the repository

### SLSA Generation Failures
If SLSA provenance generation fails:
1. Ensure the container was successfully pushed in the previous step
2. Check that the image digest is properly captured
3. Verify the GITHUB_TOKEN has the required permissions

## Security Considerations

- The workflow only pushes images on push events to prevent unauthorized builds from forks
- All secrets are properly scoped and never logged
- Container images are scanned for HIGH and CRITICAL vulnerabilities
- SBOM generation provides software supply chain transparency
- Cosign signatures provide image authenticity verification
- SLSA provenance provides build integrity attestation