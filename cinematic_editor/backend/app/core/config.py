# backend/app/core/config.py
from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional

class Settings(BaseSettings):
    # ── App ───────────────────────────────────────────────
    APP_NAME: str    = "Cinematic Editor API"
    DEBUG:    bool   = False

    # ── Database ──────────────────────────────────────────
    DATABASE_URL: str = "postgresql+asyncpg://user:pass@localhost/cinematic_db"
    REDIS_URL:    str = "redis://localhost:6379"

    # ── Security ──────────────────────────────────────────
    # [PLACEHOLDER] عيّن قيمة عشوائية طويلة قبل الإنتاج
    JWT_SECRET_KEY:    str = "CHANGE_THIS_SECRET"
    JWT_ALGORITHM:     str = "HS256"
    JWT_EXPIRE_MINUTES:int = 10080  # أسبوع

    # ── AWS ───────────────────────────────────────────────
    # [PLACEHOLDER] ضع مفاتيح AWS هنا أو في .env
    AWS_ACCESS_KEY_ID:     Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None
    AWS_REGION:  str = "us-east-1"
    AWS_S3_BUCKET: str = "cinematic-editor-assets"

    # ── Anthropic ─────────────────────────────────────────
    # [PLACEHOLDER] مفتاح Anthropic لتحليل الأوامر العربية
    ANTHROPIC_API_KEY: Optional[str] = None

    # ── GPU ───────────────────────────────────────────────
    GPU_DEVICE: str = "cuda:0"
    MAX_GPU_JOBS: int = 2

    # ── Processing ────────────────────────────────────────
    TEMP_DIR: str = "/tmp/cinematic_processing"

    class Config:
        env_file = ".env"
        case_sensitive = True

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
