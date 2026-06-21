# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this Azure DevOps extension, please report it by:

1. **DO NOT** open a public GitHub issue
2. Email the maintainer privately (or use GitHub Security Advisories)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

## Security Considerations

### Credential Storage

This extension uses Azure DevOps service connections to store sensitive data:

- **Private Keys**: Stored encrypted by Azure DevOps
- **Passwords**: Stored encrypted with `isConfidential: true`
- **Public Keys**: Stored in service connection (not encrypted, as they're public)

### Runtime Security

The extension implements several security measures:

1. **Password Masking**: Passwords are masked in logs using `##vso[task.setsecret]`
2. **Secure File Permissions**: Private keys created with 600 permissions (owner read/write only)
3. **Temporary Storage**: Keys written to temporary directories with restricted access
4. **Secure Deletion**: Uses `shred` command when available for secure file deletion
5. **Automatic Cleanup**: Trap handlers ensure cleanup on success, failure, or interruption
6. **Environment Cleanup**: Environment variables unset after use

### What This Extension Does NOT Do

- ❌ Does not send data to external services
- ❌ Does not log sensitive information
- ❌ Does not store credentials on disk permanently
- ❌ Does not use Sigstore transparency log (air-gapped mode)

### Best Practices for Users

1. **Limit Access**: Restrict service connection permissions to specific projects/teams
2. **Rotate Keys**: Periodically generate new Cosign key pairs
3. **Audit Usage**: Enable Azure DevOps audit logging for service connection usage
4. **Secure Agents**: Ensure build agents are properly secured and patched
5. **Network Security**: Use HTTPS registries when possible
6. **Review Logs**: Regularly review pipeline logs for suspicious activity

### Known Limitations

1. **Air-Gapped Only**: This extension is designed for air-gapped environments without transparency log
2. **Bash Dependency**: Currently only supports Linux agents with Bash
3. **Local Keys Only**: Uses local key files (not keyless signing)

### Dependencies

This extension has minimal dependencies:

- **External Tools**: Cosign CLI (must be pre-installed on agents)
- **Runtime**: Bash shell, Docker CLI
- **Optional**: `shred` for secure deletion, `jq` for JSON parsing

### Updates and Patches

- Security patches will be released as soon as possible
- Version updates follow semantic versioning
- Check GitHub releases for security-related updates

### Compliance

This extension is suitable for:

- Air-gapped environments
- On-premise Azure DevOps Server
- Environments with strict security requirements
- Compliance-regulated industries

### Additional Resources

- [Cosign Security Model](https://github.com/sigstore/cosign#security)
- [Azure DevOps Service Connection Security](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
- [Container Image Signing Best Practices](https://docs.sigstore.dev/)

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Acknowledgments

Thanks to the Sigstore community for Cosign and security best practices.
