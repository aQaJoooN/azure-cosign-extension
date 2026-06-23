# Cosign Azure DevOps Extension

Securely sign and verify container images in Azure DevOps pipelines using Sigstore Cosign — designed for both connected and air-gapped environments.

This extension provides a production-ready Azure DevOps task and custom service connection for securely managing Cosign signing credentials and automating container image signing workflows.

---

# Features

* Secure Cosign key management using Azure DevOps service connections
* Container image signing with Sigstore Cosign
* Signature verification support
* Air-gapped environment compatibility
* Automatic Docker registry authentication
* Image digest resolution and signing
* Secure temporary credential handling and cleanup
* Support for HTTP and HTTPS container registries
* Compatible with Azure DevOps Services and Azure DevOps Server

---

# Included Components

## Cosign Signing Task

Pipeline task for:

* Signing container images
* Verifying image signatures
* Authenticating to container registries
* Handling image digest resolution automatically

## Cosign Service Connection

Custom service connection type for securely storing:

* Cosign private key
* Cosign public key
* Cosign password
* Registry URL

---

# Typical Use Cases

* Secure software supply chain pipelines
* Air-gapped enterprise environments
* Internal Harbor registries
* Private Docker registries
* Kubernetes and container platform deployments
* CI/CD image attestation workflows

---

# Prerequisites

The build agent must have:

* Docker installed
* Cosign installed
* Network access to the target registry

Supported platforms:

* Azure DevOps Services
* Azure DevOps Server (on-premise)

---

# Example Pipeline

```yaml
- task: CosignSign@1
  inputs:
    cosignService: 'CosignProd'
    dockerRegistryService: 'HarborRegistry'
    imageName: 'project/myapp'
    imageTag: '$(Build.BuildId)'
    prependRegistryUrl: true
    allowInsecureRegistry: true
    verifySignature: true
```

---

# Security

The extension is designed with security-focused defaults:

* Secrets stored in Azure DevOps service connections
* Password masking in logs
* Secure temporary file permissions
* Automatic cleanup after execution
* Optional secure file shredding
* No transparency log dependency for isolated environments

---

# Installation

1. Install the extension into your Azure DevOps organization or server
2. Create a "Cosign Signing Connection"
3. Create a Docker Registry service connection
4. Add the `CosignSign` task to your pipeline

---

# Documentation

Full documentation, examples, releases, and source code:

* GitHub Repository:
  https://github.com/aQaJoooN/azure-cosign-extension

* Issues and Support:
  https://github.com/aQaJoooN/azure-cosign-extension/issues

---

# License

MIT License

---

# Acknowledgments

Powered by Sigstore Cosign for container signing and software supply chain security.
