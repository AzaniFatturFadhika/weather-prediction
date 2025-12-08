# 🚀 AI Model Integration - Setup Guide

## 📋 Ringkasan Perubahan

Saya telah mengintegrasikan model AI (`v4_weather_model_combined.joblib`) ke dalam sistem backend-frontend Anda. Berikut adalah perubahan yang telah dilakukan:

### 1. **Backend (main.py)**
- ✅ Menambahkan import: `joblib`, `pandas`, `os`
- ✅ Loading model AI saat startup aplikasi
- ✅ 3 endpoint API baru untuk prediksi:
  - `POST /ai-prediction/hourly` - Prediksi per jam
  - `POST /ai-prediction/daily` - Prediksi per hari
  - `GET /ai-model/info` - Info model

### 2. **Flutter - Service Layer**
- ✅ File baru: `lib/services/ai_prediction_service.dart`
  - Class untuk handle semua request ke endpoint AI
  - Helper functions untuk prediksi harian & per jam

### 3. **Flutter - UI Example**
- ✅ File baru: `lib/pages/ai_prediction_page.dart`
  - Halaman contoh untuk menampilkan prediksi
  - Tab selector (Daily/Hourly)
  - Kartu prediksi yang responsive

### 4. **Dokumentasi**
- ✅ File: `AI_INTEGRATION_GUIDE.md`
  - Panduan lengkap setup & penggunaan

---

## 🔧 Langkah Setup

### Step 1: Verifikasi File Model
Pastikan file model ada di lokasi yang benar:

```
weather-prediction/
└── models - Random Forest - Prediksi cuma pake tanggal/
    └── new/
        └── v4_weather_model_combined.joblib  ✓ (harus ada)
```

### Step 2: Install Dependencies (Backend)
```bash
cd backend
pip install joblib pandas scikit-learn
```

### Step 3: Update IP Address
Ubah konfigurasi di `Weather-Station/lib/pages/variables.dart`:

```dart
String myDomain = "http://192.168.1.87:8000";  // Sesuaikan dengan IP Anda
```

### Step 4: Update `main.py` Host
Ubah di `backend/main.py` (baris terakhir):

```python
if __name__ == "__main__":
    uvicorn.run(app, host="192.168.1.87", port=8000)  # Gunakan IP Anda
```

### Step 5: Jalankan Backend
```bash
python main.py
```

Anda akan melihat:
```
✓ AI Model loaded successfully from .../v4_weather_model_combined.joblib
Uvicorn running on http://192.168.1.87:8000
```

### Step 6: Test Backend (Optional)
Gunakan cURL atau Postman:

```bash
# Test model info
curl http://192.168.1.87:8000/ai-model/info

# Test daily prediction
curl -X POST http://192.168.1.87:8000/ai-prediction/daily \
  -H "Content-Type: application/json" \
  -d '{
    "day": 8,
    "month": 12,
    "year": 2025,
    "num_days": 3
  }'

# Test hourly prediction
curl -X POST http://192.168.1.87:8000/ai-prediction/hourly \
  -H "Content-Type: application/json" \
  -d '{
    "day": 8,
    "month": 12,
    "year": 2025,
    "hour": 10,
    "num_hours": 24
  }'
```

### Step 7: Integrasikan ke Flutter

#### Option A: Gunakan Halaman Prediksi yang Sudah Ada
Buka file `lib/main.dart` dan tambahkan route:

```dart
import 'package:demo1/pages/ai_prediction_page.dart';

// Di dalam MaterialApp routes:
routes: {
  '/prediction': (context) => const AIPredictionPage(),
  // ... routes lainnya
},
```

Kemudian tambahkan button di halaman utama:
```dart
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/prediction');
  },
  child: const Text('AI Prediction'),
)
```

#### Option B: Integrasikan ke Halaman Existing
Gunakan `AIPredictionService` di widget existing:

```dart
import 'package:demo1/services/ai_prediction_service.dart';

// Dalam State class:
void _loadAIPrediction() async {
  try {
    final result = await AIPredictionService.predictNextDays(numDays: 3);
    setState(() {
      // Update UI dengan result['data']
    });
  } catch (e) {
    // Handle error
  }
}
```

### Step 8: Jalankan Flutter App
```bash
flutter run
```

---

## 📊 Struktur Respons API

### Daily Prediction Response
```json
{
  "status": 200,
  "message": "Prediksi daily berhasil",
  "model_version": "4.0",
  "data": [
    {
      "date": "2025-12-08",
      "conditions": "Partially cloudy",
      "temp_min": 18.50,
      "temp_max": 28.30,
      "temp_mean": 23.40,
      "humidity": 62.10,
      "windspeed": 4.80,
      "sealevelpressure": 1012.90
    }
  ]
}
```

### Hourly Prediction Response
```json
{
  "status": 200,
  "message": "Prediksi hourly berhasil",
  "model_version": "4.0",
  "data": [
    {
      "datetime": "2025-12-08T10:00:00",
      "date_formatted": "2025-12-08 10:00",
      "conditions": "Clear",
      "temp": 25.45,
      "humidity": 65.32,
      "windspeed": 5.21,
      "sealevelpressure": 1013.45
    }
  ]
}
```

---

## 🎯 File-File yang Diubah/Dibuat

### Diubah:
1. `backend/main.py`
   - Tambahan import
   - Loading model
   - 3 endpoint baru

### Dibuat:
1. `Weather-Station/lib/services/ai_prediction_service.dart`
   - Service class untuk API calls

2. `Weather-Station/lib/pages/ai_prediction_page.dart`
   - Halaman contoh UI

3. `AI_INTEGRATION_GUIDE.md`
   - Dokumentasi lengkap

4. `AI_SETUP_GUIDE.md` (file ini)
   - Panduan setup

---

## ⚠️ Troubleshooting

### ❌ Error: "AI Model tidak berhasil dimuat"
**Penyebab:** File model tidak ditemukan
**Solusi:**
```bash
# Pastikan path benar
ls -la "models - Random Forest - Prediksi cuma pake tanggal/new/v4_weather_model_combined.joblib"

# Jika file tidak ada, periksa:
# 1. Nama folder persis sama
# 2. Nama file persis sama (case-sensitive)
# 3. File tidak corrupt
```

### ❌ Error: "CORS error" di Flutter
**Penyebab:** Backend tidak accessible
**Solusi:**
```bash
# Verifikasi:
1. Backend running: ps aux | grep main.py
2. IP address correct: ipconfig getifaddr en0 (macOS)
3. Port 8000 open: nc -zv 192.168.1.87 8000
4. Firewall allow: System Preferences > Security & Privacy
```

### ❌ Error: "Prediksi gagal"
**Penyebab:** Input data invalid
**Solusi:**
```
- Pastikan day: 1-31, month: 1-12, year: >= 2000
- Pastikan hour: 0-23 (untuk hourly)
- Cek format JSON request
```

### ❌ Error: "Model version mismatch"
**Penyebab:** Model format salah
**Solusi:**
```bash
# Verifikasi model format:
python3 -c "import joblib; m = joblib.load('path/to/model'); print(m.keys())"

# Output harus mengandung: 'hourly', 'daily', 'label_encoder_hourly', 'label_encoder_daily'
```

---

## 🧪 Testing Checklist

- [ ] Backend running dan model loaded
- [ ] `/ai-model/info` endpoint return data
- [ ] `/ai-prediction/daily` endpoint return data
- [ ] `/ai-prediction/hourly` endpoint return data
- [ ] Flutter `AIPredictionService` import tanpa error
- [ ] `AIPredictionPage` render tanpa error
- [ ] Daily prediction button works
- [ ] Hourly prediction button works
- [ ] Data display dengan benar

---

## 📞 Support

Jika ada masalah, periksa:
1. Logs backend: Jalankan `python main.py` dan lihat output
2. Network: Pastikan device dan backend di network yang sama
3. Model file: Pastikan file `.joblib` ada dan valid
4. Dependencies: `pip list` dan cek semua package terinstall

---

## 🚀 Next Steps

1. **Customize UI:** Modify `ai_prediction_page.dart` sesuai kebutuhan
2. **Add to Home Page:** Integrate `AIPredictionService` ke `home.dart`
3. **Caching:** Implementasikan caching untuk mengurangi API calls
4. **Notifications:** Tambah push notification untuk prediksi penting
5. **Analytics:** Track prediksi accuracy

---

**Last Updated:** December 8, 2025
**Model Version:** 4.0
**Status:** ✅ Ready to Use
