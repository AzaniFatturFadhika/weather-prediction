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
    HOST: str = "192.168.110.129"
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
    EMAIL_USERNAME: str = os.getenv("EMAIL_USERNAME", "1901029@iot.bdu.ac.bd")
    EMAIL_PASSWORD: str = os.getenv("EMAIL_PASSWORD", "ohvgfbujrmliuepi")
    
    # Security Settings
    OTP_EXPIRY_SECONDS: int = 300  # 5 minutes
    
    # AI Model Settings
    MODEL_PATH: str = os.path.join(
        os.path.dirname(__file__), 
        '..', '..', '..', 
        'ml-models', 
        'new', 
        'combined.joblib'
    )
    
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
