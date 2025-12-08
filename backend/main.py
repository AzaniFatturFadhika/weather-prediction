from fastapi import FastAPI, HTTPException, BackgroundTasks, Path
import secrets
import asyncio
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from fastapi.middleware.cors import CORSMiddleware
import mysql.connector as MySQLdb
from pydantic import BaseModel
import bcrypt
import numpy as np
from sklearn.linear_model import LinearRegression
import pickle
import uvicorn
from datetime import datetime, timedelta
import joblib
import pandas as pd
import os

db_config = {
    'host': '127.0.0.1',
    'user': 'root',
    'passwd': '',
    'db': 'weather_app_bd',
    'port': 3306,
}


class User(BaseModel):
    username: str
    password: str
    email: str
    role: str
    otp: int


# Create connection per request to avoid stale connections and "Commands out of sync" errors
def get_db_connection():
    return MySQLdb.connect(**db_config)


app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# ============== AI MODEL LOADING ==============
# Load the AI model at startup
MODEL_PATH = os.path.join(os.path.dirname(__file__), '..', 'models - Random Forest', 'new', 'v4_weather_model_combined.joblib')
ai_model = None

try:
    ai_model = joblib.load(MODEL_PATH)
    print(f"✓ AI Model loaded successfully from {MODEL_PATH}")
except Exception as e:
    print(f"✗ Failed to load AI model: {e}")
    print(f"  Model path: {MODEL_PATH}")

# ============================================


# OTP related...
async def remove_otp(email: str):
    await asyncio.sleep(300)  # Remove OTP after 5 minutes
    if email in otp_map:
        del otp_map[email]


otp_map = {}


def send_email(subject, message, to_email):
    try:
        # Set up the email server
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()

        # Replace 'YOUR_EMAIL_USERNAME' and 'YOUR_EMAIL_PASSWORD' with your actual email credentials
        email_username = '1901029@iot.bdu.ac.bd'
        email_password = 'ohvgfbujrmliuepi'

        server.login(email_username, email_password)

        # Create message
        msg = MIMEMultipart()
        msg['From'] = email_username
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(message, 'plain'))

        # Send the email
        server.sendmail(email_username, to_email, msg.as_string())
        print("Email sent successfully!")
    except smtplib.SMTPException as e:
        print(f"Failed to send email: {e}")
    finally:
        server.quit()


@app.post("/generate_otp/")
async def generate_otp(email: str):
    print(f"Received email: {email}")
    if '@' not in email or '.' not in email:
        raise HTTPException(status_code=400, detail="Invalid email format")

    otp = str(secrets.randbelow(900000) + 100000)  # Generate a 6-digit OTP
    otp_map[email] = otp
    asyncio.create_task(remove_otp(email))
    send_email("User Verification", f"Your OTP is: {otp}", email)
    print(f"OTP for {email} is: {otp}")

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = "UPDATE otp SET otp=%s, createAt=CURRENT_TIMESTAMP WHERE email=%s"
        cursor.execute(query, (otp, email))
        affectedRows = cursor.rowcount
        if affectedRows == 0:
            query = "INSERT INTO otp(email, otp) VALUES (%s, %s)"
            cursor.execute(query, (email, otp))
        conn.commit()
    finally:
        cursor.close()
        conn.close()

    return {"message": "OTP generated successfully."}


# ...OTP related

# User related...
@app.options("/users/")
async def options_users():
    return {"allow": "GET, POST, PUT, DELETE, OPTIONS"}


@app.post("/users/")
def create_user(user: User):
    hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        print(user)
        query = "SELECT otp FROM otp WHERE email=%s"
        cursor.execute(query, (user.email,))
        row = cursor.fetchone()
        prevOtp = row[0]
        print(f'prevOtp: {prevOtp}')

        msg = ''
        status = ''
        if prevOtp == user.otp:
            print("OTP matched")
            query = "INSERT INTO users (username, password, email, role) VALUES (%s, %s, %s, %s)"
            cursor.execute(query, (user.username, hashed_password, user.email, user.role))
            status = 200
            msg = "User created successfully"
        else:
            print("OTP not matched")
            status = 403
            msg = "Otp not matched"

        print(f'msg: {msg}')
        print(f'status: {status}')

        conn.commit()
        return {
            'status': status,
            'msg': msg
        }
    finally:
        cursor.close()
        conn.close()


# ...User related
class Login(BaseModel):
    username: str
    password: str


@app.post("/login/")
async def login(user: Login):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT password FROM users WHERE username = %s", (user.username,))
        db_user = cursor.fetchone()
        if db_user and bcrypt.checkpw(user.password.encode(), db_user[0].encode()):
            return {"message": "Login successful"}
        else:
            raise HTTPException(status_code=401, detail="Invalid username or password")
    finally:
        cursor.close()
        conn.close()


# *******

# Read User Info
# Internal access: http://127.0.0.1:8000/userInfo?username=sayor
@app.get("/userInfo")
def getUserInfo(username: str = None):
    username = username if username is not None else 0

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = "SELECT username, email FROM users WHERE username=%s"
        cursor.execute(query, (username,))
        row = cursor.fetchone()

        print(row);

        if row:
            return {
                "username": row[0],
                "email": row[1],
            }
        else:
            return {}
    finally:
        cursor.close()
        conn.close()


# *******

# Read last weather data
# Internal access: http://127.0.0.1:8000/weather-data/get/last?location=Gazipur
@app.get("/weather-data/get/last")
def getLastWeatherData(location: str = None):
    location = location if location is not None else 0

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = "SELECT * FROM weather_data WHERE location=%s ORDER BY id DESC LIMIT 1"
        cursor.execute(query, (location,))
        row = cursor.fetchone()

        print(row);

        if row:
            return {
                "id": row[0],
                "temp": row[1],
                "humidity": row[2],
                "isRaining": row[3],
                "lightIntensity": row[4],
                "windSpeed": row[5],
                "airPressure": row[6],
            }
        else:
            return {}
    finally:
        cursor.close()
        conn.close()


# *******

# weather prediction
# Internal access: http://127.0.0.1:8000/weather-data/get-predicted-data?day=7&&month=2&&year=2012
@app.get("/weather-data/get-predicted-data")
def getPredictedWeatherData(day: int = None, month: int = None, year: int = None):
    day = day if day is not None else 0
    month = month if month is not None else 0
    year = year if year is not None else 0

    # Create a datetime object for the given date
    start_date = datetime(year, month, day)

    finalResult = []

    # Generate three consecutive dates starting from the given date
    for i in range(3):
        # Increment the date by one day
        current_date = start_date + timedelta(days=i)
        day = current_date.strftime('%d')
        month = current_date.strftime('%m')
        year = current_date.strftime('%Y')
        print(f"{day}-{month}-{year}")

        # Use AI model v4 for predictions
        try:
            if ai_model is None:
                raise Exception("AI model not loaded")
            
            # Create prediction input for daily model
            input_data = pd.DataFrame({
                'day': [int(day)],
                'month': [int(month)],
                'year': [int(year)]
            })
            
            # Get daily regressor and classifier from AI model v4
            daily_regressor = ai_model['daily']['regressor']
            daily_classifier = ai_model['daily']['classifier']
            label_encoder = ai_model['label_encoder_daily']
            target_cols = ai_model['daily']['target_regression']
            
            # Get regression predictions (temperature, humidity, etc.)
            reg_predictions = daily_regressor.predict(input_data)
            
            # Get classification prediction (weather condition)
            clf_prediction = daily_classifier.predict(input_data)
            condition_name = label_encoder.inverse_transform(clf_prediction)[0]
            
            print(f"✓ AI Prediction successful")
            print(f"  Regression values: {reg_predictions[0]}")
            print(f"  Classification: {condition_name} (code: {clf_prediction[0]})")
            
            # Map results sesuai dengan target columns dari model
            reg_values = reg_predictions[0]
            
            # Tentukan mapping berdasarkan target_cols yang sebenarnya
            # Biasanya: ['temp_min', 'temp_max', 'temp_mean', 'humidity', 'windspeed', 'pressure']
            tempmin = round(reg_values[0], 3)    # temp_min
            tempmax = round(reg_values[1], 3)    # temp_max  
            temp = round(reg_values[2], 3)       # temp_mean
            humidity = round(reg_values[3], 3)   # humidity
            windspeed = round(reg_values[4], 3)  # windspeed
            pressure = round(reg_values[5], 3)   # pressure
            conditions = int(clf_prediction[0])   # condition code
            
        except Exception as e:
            print(f"Error in AI prediction: {e}")
            # Fallback to default values
            tempmax = 30.0
            tempmin = 20.0
            temp = 25.0
            humidity = 60.0
            windspeed = 5.0
            pressure = 1013.0
            conditions = 2
        
        # Define conditions mapping for v4 model
        conditions_mapping = {
            0: 'Clear',
            1: 'Overcast', 
            2: 'Partially cloudy',
            3: 'Rain',
            4: 'Rain, Overcast',
            5: 'Rain, Partially cloudy'
        }

        print("Predicted tempmax (C):", tempmax)
        print("Predicted tempmin (C):", tempmin)
        print("Predicted temp (C):", temp)
        print("Predicted humidity (%):", humidity)
        print("Predicted windspeed (m/s):", windspeed)
        print("Predicted sea level pressure:", pressure)
        print("Predicted conditions:", conditions_mapping.get(conditions, 'Unknown'))

        finalResult.append({
                'date': f"{day}-{month}-{year}",
                'tempmax': tempmax,
                'tempmin': tempmin,
                'temp': temp,
                'humidity': humidity,
                'windspeed': windspeed,
                'pressure': pressure,
                'conditions': conditions_mapping[conditions]
            })


    return finalResult



# *******

# Get line chart data
# Internal access: http://127.0.0.1:8000/weather-data/line-chart
@app.get("/weather-data/line-chart")
def getLineChartData():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = "SELECT windSpeed FROM weather_data WHERE location=%s ORDER BY id DESC LIMIT 10"
        cursor.execute(query, ("Gazipur",))
        rows = cursor.fetchall()

        ws = [];
        for row in rows:
            ws.append(row[0]);

        return ws
    finally:
        cursor.close()
        conn.close()

# *******

class User2(BaseModel):
    password: str
    email: str
    otp: int

@app.post("/forgot-password")
def forgotPassword(user: User2):
    print(user)
    hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        query = "SELECT otp FROM otp WHERE email=%s"
        cursor.execute(query, (user.email,))
        row = cursor.fetchone()
        prevOtp = row[0]
        print(f'prevOtp: {prevOtp}')

        msg = ''
        status = ''
        if prevOtp == user.otp:
            print("OTP matched")
            query = "UPDATE users SET password=%s WHERE email=%s"
            cursor.execute(query, (hashed_password, user.email))
            status = 200
            msg = "Password updated successfully"
        else:
            print("OTP not matched")
            status = 403
            msg = "Otp not matched"

        print(f'msg: {msg}')
        print(f'status: {status}')

        conn.commit()
        return {
            'status': status,
            'msg': msg
        }
    finally:
        cursor.close()
        conn.close()

# *******

@app.get("/weather-data/create")
def newWeatherData(
        temp: float = None,
        humidity: float = None,
        isRaining: int = None,
        lightIntensity: float = None,
        windSpeed: float = None,
        pressure: float = None,
):
    # Handle oprional params value
    temp = temp if temp is not None else 0
    humidity = humidity if humidity is not None else 0
    isRaining = isRaining if isRaining is not None else 0
    lightIntensity = lightIntensity if lightIntensity is not None else 0
    windSpeed = windSpeed if windSpeed is not None else 0
    pressure = pressure if pressure is not None else 0

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = "INSERT INTO weather_data(temp, humidity, isRaining, lightIntensity, windSpeed, airPressure) VALUES (%s, %s, %s, %s, %s, %s)"
        cursor.execute(query, (temp, humidity, isRaining, lightIntensity, windSpeed, pressure))
        affectedRows = cursor.rowcount
        conn.commit()
        if affectedRows == 1:
            return {"status": 200}
        else:
            return {"status": 403}
    finally:
        cursor.close()
        conn.close()

# *******

# ============== AI PREDICTION ENDPOINTS ==============

class DailyPredictionRequest(BaseModel):
    """Request model untuk prediksi cuaca harian"""
    day: int
    month: int
    year: int
    num_days: int = 3  # Jumlah hari untuk prediksi daily (default 3)


class HourlyPredictionRequest(BaseModel):
    """Request model untuk prediksi cuaca per jam"""
    day: int
    month: int
    year: int
    hour: int = 0  # Jam mulai (default 0)
    num_hours: int = 24  # Jumlah jam untuk prediksi hourly (default 24)


@app.post("/ai-prediction/hourly")
def predict_hourly_weather(request: HourlyPredictionRequest):
    """
    Prediksi cuaca per jam menggunakan model AI

    Request:
    {
        "day": 8,
        "month": 12,
        "year": 2025,
        "hour": 10,
        "num_hours": 24
    }
    """
    if ai_model is None:
        raise HTTPException(status_code=500, detail="AI Model tidak berhasil dimuat")

    try:
        # Validasi input
        if not (1 <= request.day <= 31 and 1 <= request.month <= 12 and request.year >= 2000):
            raise HTTPException(status_code=400, detail="Input tanggal tidak valid")

        # Buat datetime awal
        start_date = datetime(request.year, request.month, request.day, request.hour or 0)

        # Generate datetime untuk jumlah jam yang diminta
        future_dates = [start_date + timedelta(hours=i) for i in range(request.num_hours)]

        # Buat input DataFrame
        X_input = pd.DataFrame({
            'day': [d.day for d in future_dates],
            'month': [d.month for d in future_dates],
            'year': [d.year for d in future_dates],
            'hour': [d.hour for d in future_dates]
        })

        # Pastikan urutan kolom sesuai
        hourly_features = ai_model['hourly']['feature_columns']
        X_input = X_input[hourly_features]

        # Lakukan prediksi
        h_reg = ai_model['hourly']['regressor']
        h_clf = ai_model['hourly']['classifier']

        # Prediksi nilai numerik
        pred_reg = h_reg.predict(X_input)

        # Prediksi kondisi (encoded)
        pred_clf_encoded = h_clf.predict(X_input)

        # Decode kondisi
        label_encoder = ai_model['label_encoder_hourly']
        pred_conditions = label_encoder.inverse_transform(pred_clf_encoded.astype(int))

        # Format hasil
        results = []
        target_cols = ai_model['hourly']['target_regression']

        for i, future_date in enumerate(future_dates):
            result = {
                'datetime': future_date.isoformat(),
                'date_formatted': future_date.strftime('%Y-%m-%d %H:%M'),
                'conditions': str(pred_conditions[i]),
            }

            # Tambahkan nilai prediksi numerik
            for j, col in enumerate(target_cols):
                result[col] = float(round(pred_reg[i][j], 2))

            results.append(result)

        return {
            'status': 200,
            'message': 'Prediksi hourly berhasil',
            'model_version': ai_model.get('version', 'unknown'),
            'data': results
        }

    except Exception as e:
        print(f"Error dalam prediksi hourly: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error prediksi: {str(e)}")


@app.post("/ai-prediction/daily")
def predict_daily_weather(request: DailyPredictionRequest):
    """
    Prediksi cuaca harian menggunakan model AI

    Request:
    {
        "day": 8,
        "month": 12,
        "year": 2025,
        "num_days": 3
    }
    """
    if ai_model is None:
        raise HTTPException(status_code=500, detail="AI Model tidak berhasil dimuat")

    try:
        # Validasi input
        if not (1 <= request.day <= 31 and 1 <= request.month <= 12 and request.year >= 2000):
            raise HTTPException(status_code=400, detail="Input tanggal tidak valid")

        # Buat datetime awal
        start_date = datetime(request.year, request.month, request.day)

        # Generate datetime untuk jumlah hari yang diminta
        future_dates = [start_date + timedelta(days=i) for i in range(request.num_days)]

        # Buat input DataFrame
        X_input = pd.DataFrame({
            'day': [d.day for d in future_dates],
            'month': [d.month for d in future_dates],
            'year': [d.year for d in future_dates],
        })

        # Pastikan urutan kolom sesuai
        daily_features = ai_model['daily']['feature_columns']
        X_input = X_input[daily_features]

        # Lakukan prediksi
        d_reg = ai_model['daily']['regressor']
        d_clf = ai_model['daily']['classifier']

        # Prediksi nilai numerik
        pred_reg = d_reg.predict(X_input)

        # Prediksi kondisi (encoded)
        pred_clf_encoded = d_clf.predict(X_input)

        # Decode kondisi
        label_encoder = ai_model['label_encoder_daily']
        pred_conditions = label_encoder.inverse_transform(pred_clf_encoded.astype(int))

        # Format hasil
        results = []
        target_cols = ai_model['daily']['target_regression']

        for i, future_date in enumerate(future_dates):
            result = {
                'date': future_date.strftime('%Y-%m-%d'),
                'conditions': str(pred_conditions[i]),
            }

            # Tambahkan nilai prediksi numerik
            for j, col in enumerate(target_cols):
                result[col] = float(round(pred_reg[i][j], 2))

            results.append(result)

        return {
            'status': 200,
            'message': 'Prediksi daily berhasil',
            'model_version': ai_model.get('version', 'unknown'),
            'data': results
        }

    except Exception as e:
        print(f"Error dalam prediksi daily: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error prediksi: {str(e)}")


@app.get("/ai-model/info")
def get_model_info():
    """Dapatkan informasi tentang model AI yang dimuat"""
    if ai_model is None:
        return {
            'status': 400,
            'message': 'Model tidak dimuat',
            'model_loaded': False
        }

    return {
        'status': 200,
        'model_loaded': True,
        'version': ai_model.get('version', 'unknown'),
        'trained_date': ai_model.get('trained_date', 'unknown'),
        'hourly_features': ai_model['hourly']['feature_columns'],
        'hourly_targets': ai_model['hourly']['target_regression'],
        'daily_features': ai_model['daily']['feature_columns'],
        'daily_targets': ai_model['daily']['target_regression'],
    }

# ============================================

if __name__ == "__main__":
    uvicorn.run(app, host="10.252.206.210", port=8000)
