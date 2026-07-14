# Security Policy

## Supported Versions

The following versions of BugSage receive security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| 0.1.x   | :x:                |
| < 0.1   | :x:                |

Only the latest minor release line (`0.2.x`) is actively maintained. If you discover a vulnerability in an older release, please still report it — we may issue guidance or backport a fix when impact is high.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues, pull requests, or discussions.**

### Preferred method

Report vulnerabilities privately using [GitHub Security Advisories](https://github.com/MONARCHKOLI/bugsage/security/advisories/new):

1. Open **Report a vulnerability** on the repository Security Advisories page.
2. Include as much detail as you can (see below).
3. Submit the report. Only maintainers will be able to see it until we choose to publish or request a CVE.

### Alternative method

If you cannot use private reporting, email the maintainer at [monarchkoli12@gmail.com](mailto:monarchkoli12@gmail.com) with the subject line:

```text
[SECURITY] BugSage vulnerability report
```

### What to include

Please provide:

- A clear description of the vulnerability and its potential impact
- Affected BugSage version(s) (gem version or Git commit SHA)
- Ruby and Rails versions used in reproduction
- Step-by-step reproduction instructions
- Proof of concept, logs, or patches (if available)
- Any suggested remediation

Redact secrets, API keys, and personal data from reproductions and logs.

### What to expect

| Stage | Expectation |
| ----- | ----------- |
| Acknowledgement | Within **5 business days** |
| Initial triage | Within **10 business days** of acknowledgement |
| Status updates | As progress is made, or at least every **30 days** until resolution |

If the report is **accepted**, we will work on a fix, coordinate disclosure timing with you when possible, and publish a security advisory and/or `CHANGELOG.md` entry as appropriate.

If the report is **declined** (for example, out of scope, already fixed, or not a security issue), we will explain why.

We ask that you **do not publicly disclose** the vulnerability until we have released a fix or explicitly agreed on a disclosure date. Coordinated disclosure windows of up to **90 days** are typical unless a shorter or longer timeline is agreed.

## Scope

In scope for this policy includes, for example:

- Remote or local privilege escalation via BugSage middleware or endpoints
- Unintended exposure of application secrets, credentials, or user data through BugSage capture, logging, dashboard, console, or AI features
- Path traversal or arbitrary file write through apply-fix / patch features outside intended development safeguards
- Cross-site scripting or request forgery affecting BugSage-served pages or endpoints
- Supply-chain issues in published gem artifacts

Out of scope (please use public issues when appropriate):

- Bugs with no security impact
- Denial of service that only requires exhausting normal application resources
- Vulnerabilities solely in third-party dependencies (report upstream; tell us if BugSage needs a dependency bump)
- Security issues in host Rails applications that are not caused by BugSage

## Safe Harbor

We appreciate good-faith security research. If you report a vulnerability responsibly and in accordance with this policy, we will not pursue legal action related to that research.

Thank you for helping keep BugSage and its users safe.
