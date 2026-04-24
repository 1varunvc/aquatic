# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| > 2.2   | Yes       |
| < 2.3   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability in aquatic-cli, please report it responsibly:

1. **Do not** open a public GitHub issue.
2. Email: **1varunvc@gmail.dev** (or open a private security advisory on GitHub).
3. Include: description, steps to reproduce, and potential impact.
4. You will receive an acknowledgment within 48 hours.

## Security Considerations

- All Bash scripts use `set -euo pipefail` for strict error handling.
- User inputs passed to `sed` are sanitized to prevent injection.
- No secrets, API keys, or tokens are stored in the repository.
- No third-party npm dependencies are used; Node.js scripts use only built-in modules.
- The `dev` command is gated behind `AQUATIC_DEV=1` to prevent accidental execution of personal-use snippets.

