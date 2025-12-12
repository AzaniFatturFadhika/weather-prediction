"""
Configuration settings for the Weather Prediction API
"""
import os
from typing import Optional

class Settings:
    """Application settings"""
    
    # API Settings
    API_TITLE: str = "Weather Prediction API"
    API_VERSION: str = "2.0.0"
    API_DESCRIPTION: str = "API for weather prediction using AI/ML models"
    
    # Server Settings
    HOST: str = "0.0.0.0"  # Listen on all interfaces
    PORT: int = 8000
    
    # Database Settings
    DB_HOST: str = os.getenv("DB_HOST", "127.0.0.1")
    DB_USER: str = os.getenv("DB_USER", "root")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")
    DB_NAME: str = os.getenv("DB_NAME", "weather_app_bd")
    DB_PORT: int = int(os.getenv("DB_PORT", "3306"))
    
    # Email Settings
    EMAIL_HOST: str = "smtp.gmail.com"
    EMAIL_PORT: int = 587
    EMAIL_USERNAME: str = os.getenv("EMAIL_USERNAME", "warsenosetyono@gmail.com")
    EMAIL_PASSWORD: str = os.getenv("EMAIL_PASSWORD", "wfzlohiviczbiclz")
    
    # Security Settings
    OTP_EXPIRY_SECONDS: int = 300  # 5 minutes
    
    # AI Model Settings
    _BASE_DIR: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    _DEFAULT_MODEL_PATH: str = os.path.join(_BASE_DIR, "ml_models", "combined.joblib")

    _model_path_env: Optional[str] = os.getenv("MODEL_PATH")
    if _model_path_env:
        MODEL_PATH: str = (
            _model_path_env
            if os.path.isabs(_model_path_env)
            else os.path.abspath(os.path.join(_BASE_DIR, _model_path_env))
        )
    else:
        MODEL_PATH: str = _DEFAULT_MODEL_PATH
    
    # CORS Settings
    CORS_ORIGINS: list = ["*"]
    CORS_CREDENTIALS: bool = True
    CORS_METHODS: list = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    CORS_HEADERS: list = ["*"]

    def get_db_config(self) -> dict:
        """Get database configuration as dictionary"""
        return {
            'host': self.DB_HOST,
            'user': self.DB_USER,
            'passwd': self.DB_PASSWORD,
            'db': self.DB_NAME,
            'port': self.DB_PORT,
        }

# Create global settings instance
settings = Settings()
