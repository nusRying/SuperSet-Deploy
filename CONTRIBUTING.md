# Contributing

Thanks for helping improve this Apache Superset Coolify deployment template.

## Scope

Good contributions include:

- Coolify deployment fixes
- Apache Superset configuration improvements
- Docker Compose reliability improvements
- database driver additions
- documentation and troubleshooting updates
- security hardening that keeps the template easy to deploy

Avoid unrelated application code or broad refactors that do not improve the deployment template.

## Development

Validate the Compose file before opening a pull request:

```bash
docker compose --env-file .env.example config --quiet
```

If Docker is available, also run:

```bash
docker compose --env-file .env.example build
```

## Pull Requests

Please include:

- what changed
- why it changed
- how it was tested
- any Coolify-specific migration notes

Keep changes focused. If a change affects persisted data or secrets, call that out clearly.
