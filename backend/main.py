"""
Weather Prediction API - Main Entry Point
==========================================

A FastAPI-based REST API for weather prediction using AI/ML models.

Features:
- User authentication with OTP verification
- Real-time weather data management
- AI-powered hourly and daily weather predictions
- RESTful API design with automatic documentation

Author: Weather Prediction Team
Version: 2.0.0
"""
import uvicorn
from app import create_app
from app.core.config import settings

# Create FastAPI application
app = create_app()

if __name__ == "__main__":
    # Run the application
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=True,  # Enable auto-reload during development
        log_level="info"
    )
