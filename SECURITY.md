# Security Policy

## Supported Versions

This repository tracks the current Compose template on the `main` branch.

## Reporting A Vulnerability

If you find a security issue in this deployment template, open a private security advisory on GitHub or contact the repository owner directly.

Please include:

- affected file or service
- impact
- reproduction steps
- recommended fix, if known

## Deployment Security Notes

- Change default credentials before production use.
- Keep `SUPERSET_SECRET_KEY` stable and private.
- Do not expose PostgreSQL or Redis publicly.
- Back up `postgres_data` before upgrades.
- Rotate credentials if the repository or deployment environment is exposed.
