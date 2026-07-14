"""Application configuration loaded from the environment."""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Strongly typed settings for the API process."""

    model_config = SettingsConfigDict(env_file=(".env", "../.env"), env_file_encoding="utf-8", extra="ignore")
    app_name: str = "Textbook-to-Video Learning Platform"
    app_environment: str = "development"
    app_debug: bool = False
    app_host: str = "0.0.0.0"
    app_port: int = Field(default=8000, ge=1, le=65535)
    log_level: str = "INFO"
    allowed_origins: str = "http://localhost:3000,http://localhost:8080,http://localhost:5057"
    static_assets_path: str = "rendered"
    database_url: str = "postgresql+asyncpg://textbook_video:textbook_video@localhost:5432/textbook_video"
    ollama_base_url: str = "http://localhost:11434"
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "gemma4:latest"
    ollama_fallback_model: str | None = None
    ollama_timeout_seconds: float = Field(default=120.0, gt=0)
    ollama_timeout_seconds: float = Field(default=120.0, gt=0)
    max_concurrent_render_jobs: int = Field(default=2, ge=1)

    @property
    def cors_origins(self) -> list[str]:
        """Return normalized CORS origins from the comma-separated setting."""
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    """Return the process-wide immutable settings instance."""
    return Settings()
