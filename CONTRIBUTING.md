# Contributing to Cosign Azure DevOps Extension

Thank you for your interest in contributing!

## How to Contribute

### Reporting Bugs

1. Check if the bug is already reported in [GitHub Issues](../../issues)
2. If not, create a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Azure DevOps version
   - Cosign version
   - Relevant logs (with secrets removed)

### Suggesting Enhancements

1. Open a GitHub issue with tag `enhancement`
2. Describe the feature and use case
3. Explain why it would be useful
4. Provide examples if possible

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages
6. Push to your fork
7. Open a pull request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/aQaJoooN/azure-cosign-extension.git.git
cd azure-cosign-extension

# Install tfx-cli
npm install -g tfx-cli

# Build the extension
tfx extension create --manifest-globs vss-extension.json
```

### Testing

Before submitting a PR, ensure:

- [ ] JSON files are valid (use `jq` to validate)
- [ ] Shell scripts have no syntax errors (`bash -n script.sh`)
- [ ] No hardcoded secrets or sensitive data
- [ ] Documentation is updated
- [ ] Extension builds successfully
- [ ] Task works in a test Azure DevOps environment

### Code Style

- **Shell Scripts**: Follow bash best practices
  - Use `set -euo pipefail`
  - Quote variables
  - Use meaningful variable names
  - Add comments for complex logic

- **JSON**: 
  - 2-space indentation
  - No trailing commas

- **Documentation**:
  - Use Markdown
  - Keep lines under 120 characters
  - Include code examples

### Commit Messages

Use clear, descriptive commit messages:

```
feat: add support for Windows agents
fix: correct trap handler cleanup
docs: update installation instructions
security: mask additional sensitive variables
```

### Version Numbering

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Security

- Never commit sensitive data (keys, passwords, tokens)
- Review security implications of changes
- Report security issues privately (see SECURITY.md)

### Questions?

Open a GitHub issue with tag `question` or discussion.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
