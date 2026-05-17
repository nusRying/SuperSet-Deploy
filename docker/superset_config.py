import os
from urllib.parse import quote, urlparse

from flask_caching.backends.rediscache import RedisCache


def env_or_file(name: str, default: str | None = None) -> str:
    value = os.getenv(name)
    if value:
        return value
    file_path = os.getenv(f"{name}_FILE")
    if file_path and os.path.exists(file_path):
        with open(file_path, encoding="utf-8") as file:
            return file.read().strip()
    if default is not None:
        return default
    raise RuntimeError(f"{name} or {name}_FILE is required")


def env_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "y", "on"}


def build_postgres_uri() -> str:
    user = quote(env_or_file("POSTGRES_USER", "superset"), safe="")
    password = quote(env_or_file("POSTGRES_PASSWORD"), safe="")
    host = os.getenv("POSTGRES_HOST", "db")
    port = os.getenv("POSTGRES_PORT", "5432")
    database = quote(os.getenv("POSTGRES_DB", "superset"), safe="")
    return f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"


SECRET_KEY = env_or_file("SUPERSET_SECRET_KEY")
SQLALCHEMY_DATABASE_URI = os.getenv("SUPERSET_SQLALCHEMY_DATABASE_URI") or build_postgres_uri()
SQLALCHEMY_ENGINE_OPTIONS = {
    "pool_pre_ping": True,
    "pool_recycle": 300,
}

ENABLE_PROXY_FIX = env_bool("ENABLE_PROXY_FIX", True)
PREFERRED_URL_SCHEME = os.getenv("PREFERRED_URL_SCHEME", "https")
SESSION_COOKIE_SECURE = env_bool("SESSION_COOKIE_SECURE", True)
SESSION_COOKIE_SAMESITE = os.getenv("SESSION_COOKIE_SAMESITE", "Lax")
WTF_CSRF_ENABLED = True
WTF_CSRF_TIME_LIMIT = 60 * 60 * 24 * 365

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = os.getenv("REDIS_PORT", "6379")
REDIS_DB = os.getenv("REDIS_DB", "0")
REDIS_URL = os.getenv("REDIS_URL", f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}")
REDIS_PARSED_URL = urlparse(REDIS_URL)

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": int(os.getenv("CACHE_DEFAULT_TIMEOUT", "300")),
    "CACHE_KEY_PREFIX": "superset_cache_",
    "CACHE_REDIS_URL": REDIS_URL,
}
DATA_CACHE_CONFIG = CACHE_CONFIG
FILTER_STATE_CACHE_CONFIG = {
    **CACHE_CONFIG,
    "CACHE_KEY_PREFIX": "superset_filter_",
    "CACHE_DEFAULT_TIMEOUT": int(os.getenv("FILTER_STATE_CACHE_TIMEOUT", "86400")),
}
EXPLORE_FORM_DATA_CACHE_CONFIG = {
    **CACHE_CONFIG,
    "CACHE_KEY_PREFIX": "superset_explore_",
    "CACHE_DEFAULT_TIMEOUT": int(os.getenv("EXPLORE_FORM_DATA_CACHE_TIMEOUT", "86400")),
}


class CeleryConfig:
    broker_url = os.getenv("CELERY_BROKER_URL", REDIS_URL)
    result_backend = os.getenv("CELERY_RESULT_BACKEND", REDIS_URL)
    imports = (
        "superset.sql_lab",
        "superset.tasks.scheduler",
        "superset.tasks.thumbnails",
        "superset.tasks.cache",
    )
    worker_prefetch_multiplier = int(os.getenv("CELERY_WORKER_PREFETCH_MULTIPLIER", "10"))
    task_acks_late = True
    task_annotations = {
        "sql_lab.get_sql_results": {
            "rate_limit": os.getenv("SQLLAB_RATE_LIMIT", "100/s"),
        },
    }
    beat_schedule = {}


CELERY_CONFIG = CeleryConfig
RESULTS_BACKEND = RedisCache(
    host=REDIS_PARSED_URL.hostname or REDIS_HOST,
    port=REDIS_PARSED_URL.port or int(REDIS_PORT),
    password=REDIS_PARSED_URL.password,
    db=int((REDIS_PARSED_URL.path or f"/{REDIS_DB}").lstrip("/") or REDIS_DB),
    key_prefix="superset_results_",
)

FEATURE_FLAGS = {
    "ALERT_REPORTS": env_bool("SUPERSET_FEATURE_ALERT_REPORTS", False),
    "SQLLAB_BACKEND_PERSISTENCE": True,
}

TALISMAN_ENABLED = env_bool("TALISMAN_ENABLED", False)
MAPBOX_API_KEY = os.getenv("MAPBOX_API_KEY", "")
