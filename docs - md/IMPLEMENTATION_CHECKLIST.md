# ✅ AI Integration - Implementation Checklist

## 📋 Verification Checklist

Use checklist ini untuk memverifikasi bahwa semua setup sudah benar.

---

## 🔍 Phase 1: File Verification

### Backend Files
- [ ] `backend/main.py` exists
- [ ] `backend/main.py` contains `import joblib`
- [ ] `backend/main.py` contains `import pandas as pd`
- [ ] `backend/main.py` contains `import os`
- [ ] `backend/main.py` contains model loading code
- [ ] `backend/main.py` contains `/ai-model/info` endpoint
- [ ] `backend/main.py` contains `/ai-prediction/daily` endpoint
- [ ] `backend/main.py` contains `/ai-prediction/hourly` endpoint

### Flutter Files
- [ ] `Weather-Station/lib/services/ai_prediction_service.dart` exists
- [ ] `Weather-Station/lib/pages/ai_prediction_page.dart` exists
- [ ] `Weather-Station/lib/pages/variables.dart` has correct IP address

### Documentation Files
- [ ] `INTEGRATION_SUMMARY.md` exists
- [ ] `AI_SETUP_GUIDE.md` exists
- [ ] `AI_QUICK_REFERENCE.md` exists
- [ ] `AI_INTEGRATION_GUIDE.md` exists
- [ ] `AI_MODEL_ARCHITECTURE.md` exists
- [ ] `AI_DOCUMENTATION_INDEX.md` exists
- [ ] `README_AI.md` exists
- [ ] `verify_ai_integration.sh` exists

### Model Files
- [ ] `models - Random Forest - Prediksi cuma pake tanggal/new/v4_weather_model_combined.joblib` exists
- [ ] File size > 50MB (typical for trained model)
- [ ] File is readable (permissions OK)

---

## 💾 Phase 2: Dependencies

### Python Dependencies
```bash
pip list | grep -E "joblib|pandas|scikit-learn"
```

Expected output:
- [ ] joblib >= 1.0
- [ ] pandas >= 1.0
- [ ] scikit-learn >= 0.20

Install if missing:
```bash
pip install joblib pandas scikit-learn
```

### Flutter Dependencies
Check `pubspec.yaml`:
- [ ] http package exists
- [ ] All packages can be resolved
- [ ] Run `flutter pub get` successfully

---

## 🚀 Phase 3: Backend Startup

### Start Backend
```bash
cd backend
python main.py
```

Expected output:
```
✓ AI Model loaded successfully from .../v4_weather_model_combined.joblib
Uvicorn running on http://0.0.0.0:8000
```

- [ ] Backend starts without errors
- [ ] Model loads successfully
- [ ] Uvicorn server running on port 8000
- [ ] No warnings about missing dependencies

---

## 🧪 Phase 4: API Testing

### Test 1: Model Info Endpoint

Command:
```bash
curl http://192.168.1.87:8000/ai-model/info
```

Expected response:
```json
{
  "status": 200,
  "model_loaded": true,
  "version": "4.0",
  ...
}
```

- [ ] Status 200 (OK)
- [ ] model_loaded = true
- [ ] Contains version, features, targets
- [ ] Response time < 1 second

### Test 2: Daily Prediction Endpoint

Command:
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/daily \
  -H "Content-Type: application/json" \
  -d '{"day":8,"month":12,"year":2025,"num_days":3}'
```

Expected response:
```json
{
  "status": 200,
  "message": "Prediksi daily berhasil",
  "data": [
    {
      "date": "2025-12-08",
      "conditions": "...",
      "temp_min": ...,
      "temp_max": ...,
      ...
    }
  ]
}
```

- [ ] Status 200
- [ ] Returns 3 predictions
- [ ] All fields present (date, conditions, temps, humidity, etc.)
- [ ] Response time < 500ms

### Test 3: Hourly Prediction Endpoint

Command:
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/hourly \
  -H "Content-Type: application/json" \
  -d '{"day":8,"month":12,"year":2025,"hour":10,"num_hours":24}'
```

Expected response:
```json
{
  "status": 200,
  "message": "Prediksi hourly berhasil",
  "data": [
    {
      "datetime": "2025-12-08T10:00:00",
      "date_formatted": "2025-12-08 10:00",
      "conditions": "...",
      "temp": ...,
      ...
    }
  ]
}
```

- [ ] Status 200
- [ ] Returns 24 predictions
- [ ] datetime and date_formatted present
- [ ] All fields present
- [ ] Response time < 500ms

### Test 4: Error Handling

Command (invalid date):
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/daily \
  -H "Content-Type: application/json" \
  -d '{"day":32,"month":12,"year":2025,"num_days":3}'
```

Expected response:
```json
{
  "status": 400,
  "detail": "Input tanggal tidak valid"
}
```

- [ ] Status 400 or 422
- [ ] Returns error message
- [ ] Doesn't crash server

---

## 📱 Phase 5: Flutter Integration

### Step 1: Import Service
In your Flutter file:
```dart
import 'package:demo1/services/ai_prediction_service.dart';
```

- [ ] Import compiles without errors
- [ ] No red squiggles in IDE

### Step 2: Test Daily Prediction Call
```dart
final result = await AIPredictionService.predictNextDays(numDays: 3);
print(result);
```

- [ ] Call executes without errors
- [ ] Returns valid response
- [ ] Data can be accessed: `result['data']`

### Step 3: Test Hourly Prediction Call
```dart
final result = await AIPredictionService.predictTodayHourly(numHours: 24);
print(result);
```

- [ ] Call executes without errors
- [ ] Returns valid response with 24 items

### Step 4: Test Error Handling
```dart
try {
  final result = await AIPredictionService.predictDaily(
    day: 32, month: 12, year: 2025
  );
} catch (e) {
  print('Error: $e');
}
```

- [ ] Error is caught properly
- [ ] Error message is meaningful
- [ ] App doesn't crash

### Step 5: Run Prediction Page
If using example page:
```bash
flutter run
# Navigate to prediction page
```

- [ ] Page loads without errors
- [ ] Buttons are clickable
- [ ] Data displays correctly
- [ ] Switching between tabs works
- [ ] Loading indicator shows during request
- [ ] Error states handled

---

## 🎯 Phase 6: Integration to Home Page

### Option A: Add to Existing home.dart

```dart
import 'package:demo1/services/ai_prediction_service.dart';

// In initState:
await AIPredictionService.predictNextDays(numDays: 3);

// In setState:
dailyForecast = result['data'];
```

- [ ] Import added
- [ ] Service call in initState
- [ ] Data displayed in UI
- [ ] No errors during refresh

### Option B: Standalone Page

```dart
routes: {
  '/prediction': (context) => const AIPredictionPage(),
}
```

- [ ] Route added to main.dart
- [ ] Page accessible from navigation
- [ ] Back button works
- [ ] Data persists correctly

---

## 🔧 Phase 7: Configuration

### Update IP Address
In `Weather-Station/lib/pages/variables.dart`:
```dart
String myDomain = "http://192.168.1.87:8000";
```

- [ ] IP address is correct (check with `ipconfig getifaddr en0`)
- [ ] Port 8000 is correct
- [ ] Backend is running on this IP/port

### Update Backend Host
In `backend/main.py` (last line):
```python
uvicorn.run(app, host="192.168.1.87", port=8000)
```

- [ ] Host IP matches your machine IP
- [ ] Port 8000 (or changed appropriately)
- [ ] Backend accessible from flutter device

---

## 📊 Phase 8: Performance Testing

### Startup Time
- [ ] Backend starts in < 5 seconds
- [ ] Model loads in < 3 seconds

### API Response Time
- [ ] Model info: < 100ms
- [ ] Daily prediction: < 200ms
- [ ] Hourly prediction: < 500ms

### UI Responsiveness
- [ ] Daily prediction loads without freezing
- [ ] Hourly prediction loads without freezing
- [ ] Switching tabs is smooth
- [ ] Pull-to-refresh works

---

## 🐛 Phase 9: Error Scenarios

### Test Each Error Case

#### Invalid Date (day > 31)
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/daily \
  -H "Content-Type: application/json" \
  -d '{"day":32,"month":12,"year":2025}'
```
- [ ] Returns 400 with error message
- [ ] Message is clear

#### Invalid Month (month > 12)
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/daily \
  -H "Content-Type: application/json" \
  -d '{"day":8,"month":13,"year":2025}'
```
- [ ] Returns 400 with error message

#### Invalid Year (year < 2000)
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/daily \
  -H "Content-Type: application/json" \
  -d '{"day":8,"month":12,"year":1999}'
```
- [ ] Returns 400 with error message

#### Invalid Hour (hour > 23)
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/hourly \
  -H "Content-Type: application/json" \
  -d '{"day":8,"month":12,"year":2025,"hour":24}'
```
- [ ] Returns 400 with error message

#### Network Unreachable
Disconnect network and try:
```dart
final result = await AIPredictionService.predictNextDays();
```
- [ ] Exception is caught
- [ ] Error message is shown to user
- [ ] App doesn't crash

---

## ✨ Phase 10: Final Validation

### Code Quality
- [ ] No red errors in Flutter files
- [ ] No red errors in Python files
- [ ] No warnings about unused imports
- [ ] Code is properly formatted

### Documentation
- [ ] All 7 documentation files exist
- [ ] Documentation is readable
- [ ] Includes examples & diagrams
- [ ] Troubleshooting section helpful

### Functionality
- [ ] All 3 endpoints working
- [ ] All error cases handled
- [ ] UI displays predictions correctly
- [ ] Performance is acceptable

### Security
- [ ] CORS properly configured
- [ ] Input validation working
- [ ] No sensitive data in responses
- [ ] Error messages don't leak info

---

## 📋 Summary Checklist

### Must Have (Required)
- [ ] Model file exists
- [ ] Backend starts without errors
- [ ] All 3 API endpoints respond correctly
- [ ] Flutter service imports without errors
- [ ] Predictions display in UI

### Should Have (Important)
- [ ] Error handling works
- [ ] Input validation works
- [ ] Documentation complete
- [ ] IP address configured correctly
- [ ] Performance acceptable

### Nice to Have (Optional)
- [ ] Example page fully functional
- [ ] Integrated to home page
- [ ] UI customized to brand
- [ ] Caching implemented
- [ ] Analytics tracking added

---

## ✅ Final Verification

Run the verification script:
```bash
bash verify_ai_integration.sh
```

Expected output:
```
✓ All checks passed!
```

Or manually verify with:
```bash
# 1. Check files exist
ls backend/main.py
ls Weather-Station/lib/services/ai_prediction_service.dart

# 2. Check imports
grep "import joblib" backend/main.py
grep "import 'package:demo1/services/ai_prediction_service.dart'" Weather-Station/lib/pages/home.dart

# 3. Check backend
python main.py  # Should show model loaded

# 4. Check API
curl http://192.168.1.87:8000/ai-model/info  # Should return JSON
```

All checks passed?
- [ ] **YES** → Ready to deploy! 🚀
- [ ] **NO** → Review checklist above & troubleshoot

---

## 🆘 If Something Fails

1. **Check Phase 1:** Verify all files exist
2. **Check Phase 2:** Verify dependencies installed
3. **Check Phase 3:** Backend starts cleanly
4. **Check Phase 4:** API endpoints respond
5. **Check Phase 5:** Flutter imports work
6. **Check Phase 7:** IP address correct

See [AI_SETUP_GUIDE.md](AI_SETUP_GUIDE.md) → Troubleshooting section

---

**Status:** ✅ Ready to verify  
**Date:** December 8, 2025  
**Version:** 1.0
