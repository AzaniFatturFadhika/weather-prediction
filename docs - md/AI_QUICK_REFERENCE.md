# 🎯 AI Integration - Quick Reference Card

## 🚀 Start Backend Quickly

```bash
cd weather-prediction/backend
python main.py
```

Expected output:
```
✓ AI Model loaded successfully
Uvicorn running on http://192.168.1.87:8000
```

---

## 📡 API Endpoints Quick Test

### 1. Get Model Info
```bash
curl http://192.168.1.87:8000/ai-model/info
```

### 2. Daily Prediction (Next 3 Days)
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/daily \
  -H "Content-Type: application/json" \
  -d '{"day":8,"month":12,"year":2025,"num_days":3}'
```

### 3. Hourly Prediction (Next 24 Hours)
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/hourly \
  -H "Content-Type: application/json" \
  -d '{"day":8,"month":12,"year":2025,"hour":10,"num_hours":24}'
```

---

## 📱 Flutter Usage

### Import Service
```dart
import 'package:demo1/services/ai_prediction_service.dart';
```

### Daily Prediction
```dart
final result = await AIPredictionService.predictNextDays(numDays: 7);
final predictions = result['data'];

for (var pred in predictions) {
  print('${pred['date']}: ${pred['conditions']}, Max: ${pred['temp_max']}°C');
}
```

### Hourly Prediction
```dart
final result = await AIPredictionService.predictTodayHourly(numHours: 24);
final predictions = result['data'];

for (var pred in predictions) {
  print('${pred['date_formatted']}: ${pred['temp']}°C');
}
```

### Get Model Info
```dart
final info = await AIPredictionService.getModelInfo();
print('Model Version: ${info['version']}');
print('Targets: ${info['daily_targets']}');
```

---

## 🔍 Check Connectivity

```bash
# Test model file exists
ls -la "models - Random Forest - Prediksi cuma pake tanggal/new/"

# Test backend running
curl -s http://192.168.1.87:8000/ai-model/info | jq .status

# Test from phone/emulator
# Change 192.168.1.87 to your machine IP
ipconfig getifaddr en0  # macOS
ipconfig getifaddr en0  # Linux
ipconfig getifaddr WiFi  # Windows
```

---

## 📊 Response Structure

**Daily Prediction Fields:**
- `date` - Format: YYYY-MM-DD
- `conditions` - String (e.g., "Clear", "Rain")
- `temp_min`, `temp_max`, `temp_mean` - °C
- `humidity` - %
- `windspeed` - m/s
- `sealevelpressure` - hPa

**Hourly Prediction Fields:**
- `datetime` - ISO format
- `date_formatted` - YYYY-MM-DD HH:MM
- `conditions` - String
- `temp`, `humidity`, `windspeed`, `sealevelpressure`

---

## ⚙️ Configuration

**Update these files with your IP:**

1. `Weather-Station/lib/pages/variables.dart`
```dart
String myDomain = "http://192.168.1.87:8000";
```

2. `backend/main.py` (last line)
```python
uvicorn.run(app, host="192.168.1.87", port=8000)
```

---

## 📝 Common Tasks

### Add Prediction to Home Page
```dart
// In home.dart initState:
await AIPredictionService.predictNextDays(numDays: 3);
```

### Handle Errors
```dart
try {
  final result = await AIPredictionService.predictNextDays();
  // Use result
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'))
  );
}
```

### Custom Prediction Date
```dart
final result = await AIPredictionService.predictDaily(
  day: 15,
  month: 12,
  year: 2025,
  numDays: 5,
);
```

---

## 🐛 Debugging

### Enable Logs
```python
# In main.py, uncomment print statements:
print(f"Request: {request}")
print(f"Predictions: {pred_reg}")
```

### Check Model Loaded
```bash
python3 -c "
import joblib
m = joblib.load('models - Random Forest - Prediksi cuma pake tanggal/new/v4_weather_model_combined.joblib')
print('Keys:', list(m.keys()))
print('Version:', m['version'])
"
```

### Monitor Backend
```bash
# Keep backend running with logs
python main.py 2>&1 | tee backend.log

# Or in another terminal:
tail -f backend.log
```

---

## ✅ Pre-Launch Checklist

- [ ] Model file exists at correct path
- [ ] Backend runs without errors
- [ ] `/ai-model/info` returns data
- [ ] `/ai-prediction/daily` returns valid data
- [ ] `/ai-prediction/hourly` returns valid data
- [ ] Flutter imports without errors
- [ ] Flutter can connect to backend
- [ ] UI displays predictions correctly

---

## 📚 Full Documentation

See `AI_INTEGRATION_GUIDE.md` for complete reference.

---

**Version:** 4.0 | **Date:** December 8, 2025
