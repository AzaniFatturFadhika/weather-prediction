# Weather Prediction API - Backend

A clean, modular FastAPI backend for weather prediction using AI/ML models.

## 📁 Project Structure

```
backend/
├── app/
│   ├── __init__.py          # App factory and initialization
│   ├── core/                # Core configurations
│   │   ├── config.py        # Application settings
│   │   └── database.py      # Database connections
│   ├── models/              # Pydantic schemas
│   │   └── schemas.py       # Request/response models
│   ├── routes/              # API endpoints
│   │   ├── auth.py          # Authentication routes
│   │   ├── weather.py       # Weather data routes
│   │   └── prediction.py    # AI prediction routes
│   ├── services/            # Business logic
│   │   ├── auth_service.py      # User management
│   │   ├── weather_service.py   # Weather data logic
│   │   └── prediction_service.py # AI predictions
│   └── utils/               # Utility functions
│       ├── email.py         # Email utilities
│       └── security.py      # Security utilities
├── main.py                  # Application entry point (Modular Architecture)
├── legacy_fetch_api.py      # Legacy API fetcher
├── requirements.txt         # Python dependencies
└── weather_app_bd.sql       # Database schema
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Setup Database

```bash
# Import database schema
mysql -u root -p < weather_app_bd.sql
```

### 3. Configure Environment (Optional)

Create a `.env` file for custom configuration:

```env
# Database
DB_HOST=127.0.0.1
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=weather_app_bd
DB_PORT=3306

# Email (for OTP)
EMAIL_USERNAME=your_email@gmail.com
EMAIL_PASSWORD=your_app_password

# Server
HOST=0.0.0.0
PORT=8000
```

### 4. Run the Server

**Option A: Using new refactored code (recommended)**

```bash
python main.py
```

**Option B: Using legacy code**

```bash
python main.py
```

### 5. Access API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 📡 API Endpoints

### Authentication (`/auth`)

- `POST /auth/generate-otp` - Generate OTP for email verification
- `POST /auth/register` - Register new user with OTP
- `POST /auth/login` - User login
- `GET /auth/user-info` - Get user information
- `POST /auth/forgot-password` - Reset password with OTP

### Weather Data (`/weather-data`)

- `GET /weather-data/last` - Get latest weather data
- `GET /weather-data/line-chart` - Get chart data
- `POST /weather-data/create` - Create weather data record

### AI Prediction (`/ai-prediction`)

- `POST /ai-prediction/hourly` - Hourly weather prediction
- `POST /ai-prediction/daily` - Daily weather prediction
- `GET /ai-prediction/model-info` - Get AI model information

## 🏗️ Architecture

### Design Patterns

- **Separation of Concerns**: Routes, services, and data access are separated
- **Dependency Injection**: FastAPI's dependency system for database connections
- **Factory Pattern**: Application creation through factory function
- **Repository Pattern**: Database access through service layer

### Key Features

- ✅ Clean, modular code structure
- ✅ Type hints throughout
- ✅ Automatic API documentation
- ✅ CORS support for Flutter/web clients
- ✅ Context managers for database connections
- ✅ Error handling and validation
- ✅ Email-based OTP verification
- ✅ AI model integration

## 🔧 Development

### Code Organization

- **core/**: Configuration and shared resources
- **models/**: Data validation schemas (Pydantic)
- **routes/**: API endpoint definitions
- **services/**: Business logic implementation
- **utils/**: Reusable utility functions

### Adding New Features

1. Add schemas in `models/schemas.py`
2. Implement business logic in `services/`
3. Create routes in `routes/`
4. Register router in `routes/__init__.py`

## 📊 Database Schema

Required tables:

- `users` - User accounts
- `otp` - OTP verification codes
- `weather_data` - Sensor weather data
- `historical_dataset` - Historical data for training

## 🔒 Security

- Password hashing with bcrypt
- OTP-based email verification
- Input validation with Pydantic
- CORS configuration for API access

## 📝 Migration from Old Code

The new structure provides:

- Better maintainability
- Easier testing
- Clear separation of concerns
- Type safety
- Automatic documentation

## 🐛 Troubleshooting

**Model not loading?**

- Check model path in `app/core/config.py`
- Ensure model file exists: `ml-models/new/combined.joblib`

**Database connection failed?**

- Verify MySQL is running
- Check credentials in config or `.env`
- Ensure database `weather_app_bd` exists

**Email not sending?**

- Configure Gmail app password
- Enable "Less secure app access" or use app-specific password

## 📚 API Examples

### Register User

```bash
# 1. Generate OTP
curl -X POST "http://localhost:8000/auth/generate-otp" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'

# 2. Register with OTP
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "email": "user@example.com",
    "password": "password123",
    "role": "user",
    "otp": 123456
  }'
```

### Get Weather Prediction

```bash
curl -X POST "http://localhost:8000/ai-prediction/daily" \
  -H "Content-Type: application/json" \
  -d '{
    "day": 8,
    "month": 12,
    "year": 2025,
    "num_days": 3
  }'
```

## 📄 License

Copyright © 2025 Weather Prediction Team
