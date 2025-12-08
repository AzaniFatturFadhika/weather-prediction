# -*- coding: utf-8 -*-
"""
Weather Prediction API v4.1 (REST API untuk Flutter)
====================================================
REST API berbasis Flask untuk model prediksi cuaca v4.

Endpoints:
- POST /api/predict/hourly     - Prediksi per jam
- POST /api/predict/daily      - Prediksi per hari
- GET  /api/predict/range      - Prediksi rentang tanggal
- GET  /api/model/info         - Info model
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os
import json

# ===================== CONSTANTS =====================
WEATHER_CODE_TO_CONDITION = {
    0: 'Clear', 1: 'Partially Cloudy', 2: 'Partially Cloudy', 3: 'Overcast',
    51: 'Light Rain', 53: 'Moderate Rain', 55: 'Heavy Showers',
    61: 'Rain, Overcast', 63: 'Rain, Overcast', 65: 'Heavy Rain'
}

WEATHER_CODE_TO_RAIN = {
    0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0,
    51: 0.2, 53: 0.7, 55: 1.1,
    61: 1.7, 63: 4.0, 65: 10.3
}

# ===================== FLASK APP SETUP =====================
app = Flask(__name__)
CORS(app)  # Enable CORS untuk Flutter

# Model Global
model = None
model_path = ""

# Features & Targets
hourly_features = ['day', 'month', 'year', 'hour']
daily_features = ['day', 'month', 'year']

hourly_targets_reg = ['temp', 'humidity', 'windspeed', 'sealevelpressure']
daily_targets_reg = ['temp_min', 'temp_max', 'temp_mean', 'humidity_avg', 'windspeed_avg', 'pressure_avg']

# ===================== MODEL LOADING =====================
def load_model(path):
    """Load dan normalize model"""
    global model, model_path
    
    if not os.path.exists(path):
        raise FileNotFoundError(f"Model file not found: {path}")
    
    try:
        raw_model = joblib.load(path)
        model = normalize_model(raw_model)
        model_path = path
        return True
    except Exception as e:
        raise Exception(f"Failed to load model: {str(e)}")

def normalize_model(raw):
    """Normalize berbagai format model v4"""
    norm = {
        'hourly': {'regressor': None, 'classifier': None},
        'daily': {'regressor': None, 'classifier': None},
        'encoders': {},
        'meta': {}
    }
    
    norm['meta']['version'] = raw.get('version', 'Unknown')
    norm['meta']['date'] = raw.get('trained_date', 'Unknown')
    
    # Case 1: Combined Package
    if 'hourly' in raw and 'daily' in raw and isinstance(raw['hourly'], dict):
        norm['hourly']['regressor'] = raw['hourly'].get('regressor')
        norm['hourly']['classifier'] = raw['hourly'].get('classifier')
        norm['daily']['regressor'] = raw['daily'].get('regressor')
        norm['daily']['classifier'] = raw['daily'].get('classifier')
        norm['encoders']['hourly'] = raw.get('label_encoder_hourly')
        norm['encoders']['daily'] = raw.get('label_encoder_daily')
    
    # Case 2: Partial Package
    elif 'regressor' in raw and 'classifier' in raw:
        cols = raw.get('feature_columns', [])
        is_hourly = 'hour' in cols
        key = 'hourly' if is_hourly else 'daily'
        norm[key]['regressor'] = raw['regressor']
        norm[key]['classifier'] = raw['classifier']
        norm['encoders'][key] = raw.get('label_encoder')
    
    return norm

# ===================== UTILITY FUNCTIONS =====================
def get_condition_name(code, le=None):
    """Convert code ke kondisi readable"""
    if le and isinstance(code, (int, np.integer)):
        try:
            return le.inverse_transform([int(code)])[0]
        except:
            pass
    return WEATHER_CODE_TO_CONDITION.get(code, str(code))

def datetime_to_features(dt):
    """Convert datetime ke features dict"""
    return {
        'day': dt.day,
        'month': dt.month,
        'year': dt.year,
        'hour': dt.hour
    }

# ===================== API ENDPOINTS =====================

@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'model_loaded': model is not None,
        'model_file': os.path.basename(model_path) if model else None
    })

@app.route('/api/predict/hourly', methods=['POST'])
def predict_hourly():
    """
    Prediksi cuaca per jam
    
    Request:
    {
        "date": "2025-12-08",
        "hour": 14
    }
    
    Response:
    {
        "timestamp": "2025-12-08 14:00",
        "temp": 23.5,
        "humidity": 65.2,
        "windspeed": 3.1,
        "sealevelpressure": 1013.2,
        "condition": "Overcast"
    }
    """
    try:
        if not model:
            return jsonify({'error': 'Model not loaded'}), 400
        
        data = request.json
        date_str = data.get('date')
        hour = int(data.get('hour', 0))
        
        # Parse date
        dt = datetime.strptime(date_str, '%Y-%m-%d')
        dt = dt.replace(hour=hour)
        
        # Prepare input
        X = pd.DataFrame([datetime_to_features(dt)])[hourly_features]
        
        # Predict
        h_reg = model['hourly']['regressor']
        h_clf = model['hourly']['classifier']
        
        if not h_reg or not h_clf:
            return jsonify({'error': 'Hourly model not available'}), 400
        
        pred_reg = h_reg.predict(X)[0]
        pred_clf = h_clf.predict(X)[0]
        
        le = model['encoders'].get('hourly')
        condition = get_condition_name(pred_clf, le)
        
        result = {
            'timestamp': dt.strftime('%Y-%m-%d %H:%M'),
            'temp': float(pred_reg[0]),
            'humidity': float(pred_reg[1]),
            'windspeed': float(pred_reg[2]),
            'sealevelpressure': float(pred_reg[3]),
            'condition': condition
        }
        
        return jsonify(result), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/predict/daily', methods=['POST'])
def predict_daily():
    """
    Prediksi cuaca per hari
    
    Request:
    {
        "date": "2025-12-08"
    }
    
    Response:
    {
        "date": "2025-12-08",
        "temp_min": 20.5,
        "temp_max": 28.3,
        "temp_mean": 24.4,
        "humidity_avg": 68.5,
        "windspeed_avg": 3.5,
        "pressure_avg": 1012.8,
        "condition": "Overcast"
    }
    """
    try:
        if not model:
            return jsonify({'error': 'Model not loaded'}), 400
        
        data = request.json
        date_str = data.get('date')
        
        # Parse date
        d = datetime.strptime(date_str, '%Y-%m-%d').date()
        
        # Prepare input
        X = pd.DataFrame([{
            'day': d.day,
            'month': d.month,
            'year': d.year
        }])[daily_features]
        
        # Predict
        d_reg = model['daily']['regressor']
        d_clf = model['daily']['classifier']
        
        if not d_reg or not d_clf:
            return jsonify({'error': 'Daily model not available'}), 400
        
        pred_reg = d_reg.predict(X)[0]
        pred_clf = d_clf.predict(X)[0]
        
        le = model['encoders'].get('daily')
        condition = get_condition_name(pred_clf, le)
        
        result = {
            'date': d.strftime('%Y-%m-%d'),
            'temp_min': float(pred_reg[0]),
            'temp_max': float(pred_reg[1]),
            'temp_mean': float(pred_reg[2]),
            'humidity_avg': float(pred_reg[3]),
            'windspeed_avg': float(pred_reg[4]),
            'pressure_avg': float(pred_reg[5]),
            'condition': condition
        }
        
        return jsonify(result), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/predict/range', methods=['POST'])
def predict_range():
    """
    Prediksi cuaca untuk rentang tanggal
    
    Request:
    {
        "start_date": "2025-12-08",
        "start_hour": 0,
        "end_date": "2025-12-10",
        "end_hour": 23,
        "type": "hourly" atau "daily"
    }
    
    Response:
    {
        "type": "hourly",
        "data": [
            {
                "timestamp": "2025-12-08 00:00",
                "temp": 23.5,
                ...
            },
            ...
        ]
    }
    """
    try:
        if not model:
            return jsonify({'error': 'Model not loaded'}), 400
        
        data = request.json
        start_date = datetime.strptime(data.get('start_date'), '%Y-%m-%d')
        end_date = datetime.strptime(data.get('end_date'), '%Y-%m-%d')
        start_hour = int(data.get('start_hour', 0))
        end_hour = int(data.get('end_hour', 23))
        pred_type = data.get('type', 'hourly')
        
        start = start_date.replace(hour=start_hour)
        end = end_date.replace(hour=end_hour)
        
        results = []
        
        if pred_type == 'hourly':
            timestamps = []
            current = start
            while current <= end:
                timestamps.append(current)
                current += timedelta(hours=1)
            
            X = pd.DataFrame([datetime_to_features(t) for t in timestamps])[hourly_features]
            
            h_reg = model['hourly']['regressor']
            h_clf = model['hourly']['classifier']
            
            pred_reg = h_reg.predict(X)
            pred_clf = h_clf.predict(X)
            
            le = model['encoders'].get('hourly')
            
            for i, t in enumerate(timestamps):
                condition = get_condition_name(pred_clf[i], le)
                results.append({
                    'timestamp': t.strftime('%Y-%m-%d %H:%M'),
                    'temp': float(pred_reg[i][0]),
                    'humidity': float(pred_reg[i][1]),
                    'windspeed': float(pred_reg[i][2]),
                    'sealevelpressure': float(pred_reg[i][3]),
                    'condition': condition
                })
        
        else:  # daily
            dates = []
            current = start.date()
            while current <= end.date():
                dates.append(current)
                current += timedelta(days=1)
            
            X = pd.DataFrame([{
                'day': d.day,
                'month': d.month,
                'year': d.year
            } for d in dates])[daily_features]
            
            d_reg = model['daily']['regressor']
            d_clf = model['daily']['classifier']
            
            pred_reg = d_reg.predict(X)
            pred_clf = d_clf.predict(X)
            
            le = model['encoders'].get('daily')
            
            for i, d in enumerate(dates):
                condition = get_condition_name(pred_clf[i], le)
                results.append({
                    'date': d.strftime('%Y-%m-%d'),
                    'temp_min': float(pred_reg[i][0]),
                    'temp_max': float(pred_reg[i][1]),
                    'temp_mean': float(pred_reg[i][2]),
                    'humidity_avg': float(pred_reg[i][3]),
                    'windspeed_avg': float(pred_reg[i][4]),
                    'pressure_avg': float(pred_reg[i][5]),
                    'condition': condition
                })
        
        return jsonify({
            'type': pred_type,
            'count': len(results),
            'data': results
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/model/info', methods=['GET'])
def model_info():
    """Get informasi model"""
    try:
        if not model:
            return jsonify({'error': 'Model not loaded'}), 400
        
        info = {
            'version': model['meta'].get('version'),
            'trained_date': model['meta'].get('date'),
            'model_file': os.path.basename(model_path),
            'hourly': {
                'regressor': type(model['hourly']['regressor']).__name__ if model['hourly']['regressor'] else None,
                'classifier': type(model['hourly']['classifier']).__name__ if model['hourly']['classifier'] else None
            },
            'daily': {
                'regressor': type(model['daily']['regressor']).__name__ if model['daily']['regressor'] else None,
                'classifier': type(model['daily']['classifier']).__name__ if model['daily']['classifier'] else None
            }
        }
        
        return jsonify(info), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ===================== STARTUP =====================
if __name__ == '__main__':
    import sys
    
    # Default model path
    model_path_default = 'new/v4_weather_model_combined.joblib'
    
    # Try to load model
    try:
        if os.path.exists(model_path_default):
            load_model(model_path_default)
            print(f"✓ Model loaded: {model_path_default}")
        else:
            print(f"⚠ Default model not found: {model_path_default}")
    except Exception as e:
        print(f"✗ Error loading model: {e}")
    
    # Start Flask server
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
    print(f"\n🚀 Starting Weather Prediction API on port {port}")
    print(f"📍 Visit: http://localhost:{port}/api/health")
    
    app.run(host='0.0.0.0', port=port, debug=True)
