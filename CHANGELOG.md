# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-21-06

### Added
- Custom service connection for Cosign credentials
  - Secure storage for private key
  - Secure storage for public key
  - Secure storage for password
- Azure DevOps task for container image signing
  - Automatic image digest resolution
  - Sign with private key
  - Verify with public key
  - Optional signature verification with identity extraction
  - Configurable insecure registry support
- Air-gapped environment support
  - No transparency log uploads
  - No external service dependencies
  - Offline signature verification
- Security features
  - Password masking in logs
  - Secure temporary file handling
  - Automatic cleanup on success/failure
  - Secure file deletion with shred
- Comprehensive documentation
  - README with examples
  - Deployment guide
  - Quick start guide
  - Technical overview
- GitHub Actions CI/CD pipeline
  - Automatic validation
  - Semantic versioning
  - Automated releases with .vsix artifacts

### Security
- All credentials encrypted in service connections
- No hardcoded secrets
- Proper file permissions (600 for private keys)
- Trap handlers for cleanup
- Environment variable cleanup

## [Unreleased]

### Planned
- Windows agent support (PowerShell)
- Multiple signature support
- Attestation generation
- Policy enforcement task
- SBOM attachment support

---

## Release Notes

### Version 1.0.0

First stable release of the Cosign Azure DevOps Extension.

**Features:**
- Sign container images with Cosign
- Custom service connection for secure credential storage
- Air-gapped environment support
- Automatic signature verification
- Comprehensive documentation

**Requirements:**
- Azure DevOps Server 2019+ or Azure DevOps Services
- Linux build agents with Bash
- Docker CLI installed
- Cosign CLI installed

**Installation:**
Download the `.vsix` file from [GitHub Releases](https://github.com/aQaJoooN/azure-cosign-extension.git/releases) and upload to your Azure DevOps Server.

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed installation instructions.
