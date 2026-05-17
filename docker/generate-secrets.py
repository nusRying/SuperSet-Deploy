import os
import secrets
import stat
import time
from pathlib import Path


SECRETS_DIR = Path(os.getenv("SUPERSET_SECRETS_DIR", "/run/superset-secrets"))
SECRETS_DIR.mkdir(parents=True, exist_ok=True)
os.umask(0o077)


def ensure_secret(name: str, length: int) -> str:
    path = SECRETS_DIR / name
    if not path.exists():
        path.write_text(secrets.token_urlsafe(length), encoding="utf-8")
        path.chmod(stat.S_IRUSR | stat.S_IWUSR)
    return path.read_text(encoding="utf-8").strip()


postgres_password = ensure_secret("postgres_password", 36)
superset_secret_key = ensure_secret("superset_secret_key", 64)
admin_password = ensure_secret("admin_password", 24)

(SECRETS_DIR / ".ready").write_text("ready\n", encoding="utf-8")

print("Superset generated secrets are ready.", flush=True)
print("Initial Superset admin username: admin", flush=True)
print(f"Initial Superset admin password: {admin_password}", flush=True)
print("Store this password, then change it from Superset after first login.", flush=True)

while True:
    time.sleep(3600)
