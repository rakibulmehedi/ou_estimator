# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | :white_check_mark: |
| < 1.1.0 | :x:                |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

To report a security vulnerability, email the maintainer directly:

**Email:** rakibulislammehedi4@gmail.com  
**Subject line:** `[SECURITY] ou_estimator — <brief description>`

### What to Include

- A description of the vulnerability and its potential impact
- Steps to reproduce the issue
- The affected version(s)
- Any suggested mitigations (optional)

### Response Timeline

| Severity | Initial Response | Target Resolution |
| -------- | ---------------- | ----------------- |
| Critical | Within 48 hours  | Within 7 days     |
| High     | Within 7 days    | Within 30 days    |
| Medium   | Within 14 days   | Within 60 days    |
| Low      | Within 30 days   | Best effort       |

### Scope

This is a Flutter mobile application that runs entirely on-device. It performs
local statistical computation (Ornstein-Uhlenbeck parameter estimation) on
user-supplied data. There are no backend services, no authentication systems,
and no network data transmission.

Security concerns relevant to this project include:

- Unsafe handling of user-imported CSV/TXT files
- Data leakage via the export/share feature
- Local storage security (Isar database)
- Vulnerabilities in third-party dependencies

### Disclosure Policy

After a fix is released, we will publish a security advisory on GitHub. We
request a 90-day coordinated disclosure window before public disclosure of
the vulnerability details.

### Thanks

We appreciate responsible disclosure and will acknowledge reporters in the
release notes (unless anonymity is requested).
