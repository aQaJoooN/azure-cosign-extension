# Cosign Azure DevOps Extension

[![Build and Release](https://github.com/aQaJoooN/azure-cosign-extension/actions/workflows/build.yml/badge.svg)](https://github.com/aQaJoooN/azure-cosign-extension/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Sign container images with Cosign in air-gapped Azure DevOps environments.

## Features

- Custom service connection for secure credential storage (private key, public key, password)
- Automatic image digest resolution and signing
- Signature verification with identity extraction
- Air-gapped support (no transparency log required)
- Secure credential handling with automatic cleanup

## Prerequisites

- Azure DevOps Server (on-premise) or Azure DevOps Services
- Docker and Cosign installed on build agents
- Cosign key pair (`cosign generate-key-pair`)

## Installation

### From GitHub Releases (Recommended)

1. Download `.vsix` from [Releases](https://github.com/aQaJoooN/azure-cosign-extension/releases)
2. Upload to Azure DevOps: Organization Settings → Extensions → Upload extension
3. Install to your project collection

### Manual Build

```bash
npm install -g tfx-cli
tfx extension create --manifest-globs vss-extension.json
```

## Setup

### 1. Create Service Connection

1. Project Settings → Service connections → New service connection
2. Select "Cosign Signing Connection"
3. Fill in:
   - **Connection Name**: Your friendly name
   - **Cosign Private Key**: Content of `cosign.key` file
   - **Cosign Public Key**: Content of `cosign.pub` file
   - **Cosign Password**: Password for the private key
4. Save

### 2. Use in Pipeline

```yaml
- task: CosignSign@1
  inputs:
    cosignService: 'YourConnectionName'
    imageName: 'registry.local/myapp'
    imageTag: '$(Build.BuildId)'
    allowInsecureRegistry: true
    verifySignature: true
```

## Task Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| cosignService | Yes | - | Service connection name |
| imageName | Yes | - | Container image repository |
| imageTag | Yes | latest | Image tag to sign |
| allowInsecureRegistry | No | true | Allow HTTP registries |
| verifySignature | No | true | Verify after signing |

## Example Pipeline

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  imageName: 'harbor.company.com/project/app'
  imageTag: '$(Build.BuildId)'

stages:
- stage: BuildAndSign
  jobs:
  - job: Build
    steps:
    - task: Docker@2
      inputs:
        command: build
        repository: $(imageName)
        tags: $(imageTag)
    
    - task: Docker@2
      inputs:
        command: push
        repository: $(imageName)
        tags: $(imageTag)
    
    - task: CosignSign@1
      inputs:
        cosignService: 'CosignProd'
        imageName: '$(imageName)'
        imageTag: '$(imageTag)'
```

## How It Works

1. Retrieves credentials from service connection
2. Creates temporary secure key files (600 permissions)
3. Resolves image digest from name:tag
4. Signs image digest with private key
5. Verifies signature with public key (optional)
6. Extracts identity with jq if available
7. Securely cleans up (unsets variables, deletes files)

## Manual Verification

```bash
cosign verify \
  --key cosign.pub \
  --allow-insecure-registry \
  --insecure-ignore-tlog=true \
  registry.local/app:tag | jq '.[].critical.identity'
```

## Security Features

- Credentials encrypted in service connections
- Passwords masked in logs (`##vso[task.setsecret]`)
- Private keys with 600 permissions
- Secure file deletion (shred when available)
- Automatic cleanup on success/failure
- Air-gapped mode (no external services)

## GitHub Setup

### Push to GitHub

```bash
cd azure-cosign-extension
git init
git add .
git commit -m "feat: initial release"
git remote add origin https://github.com/aQaJoooN/azure-cosign-extension.git
git push -u origin main
```

### Create Release

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

GitHub Actions automatically builds `.vsix` and creates release.

## Versioning

Follows [Semantic Versioning](https://semver.org/):

```bash
# Bug fix: v1.0.0 → v1.0.1
git tag -a v1.0.1 -m "fix: correct verification"

# New feature: v1.0.0 → v1.1.0
git tag -a v1.1.0 -m "feat: add Windows support"

# Breaking change: v1.0.0 → v2.0.0
git tag -a v2.0.0 -m "feat!: new connection format"
```

## Troubleshooting

**Image digest not found**
```bash
# Ensure image exists
docker pull registry.local/app:tag
```

**Cosign not found**
```bash
# Install Cosign on agent
curl -LO https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign
```

**Credentials not found**
- Verify service connection is created
- Check connection name matches task input
- Ensure all three fields are filled (private key, public key, password)

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

For security issues, see [SECURITY.md](SECURITY.md).

## License

MIT License - see [LICENSE](LICENSE) file.

## Support

- **Issues**: [GitHub Issues](https://github.com/aQaJoooN/azure-cosign-extension/issues)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

## Acknowledgments

Built with [Sigstore Cosign](https://github.com/sigstore/cosign) for container supply chain security.
