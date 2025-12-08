# 🤖 AI Model Integration Guide

## Daftar Isi
1. [Overview](#overview)
2. [Backend Setup](#backend-setup)
3. [API Endpoints](#api-endpoints)
4. [Flutter Integration](#flutter-integration)
5. [Contoh Penggunaan](#contoh-penggunaan)

---

## Overview

Model AI (`v4_weather_model_combined.joblib`) telah diintegrasikan ke dalam backend FastAPI. Model ini mampu memprediksi cuaca berdasarkan:
- **Hourly Prediction**: Per jam dengan fitur (day, month, year, hour)
- **Daily Prediction**: Per hari dengan fitur (day, month, year)

### Keunggulan Model
✅ Tidak memerlukan data historis sensor
✅ Prediksi berdasarkan pola musiman (date-based)
✅ Output mencakup temperatur, humidity, windspeed, pressure, dan kondisi cuaca

---

## Backend Setup

### 1. Pastikan Model File Ada
Model harus tersedia di:
```
weather-prediction/
├── models - Random Forest - Prediksi cuma pake tanggal/
│   └── new/
│       └── v4_weather_model_combined.joblib
```

### 2. Install Dependensi
```bash
pip install joblib pandas scikit-learn
```

### 3. Jalankan Backend
```bash
cd backend
python main.py
```

Anda akan melihat output seperti:
```
✓ AI Model loaded successfully from .../v4_weather_model_combined.joblib
```

---

## API Endpoints

### 1. Model Info Endpoint
**GET** `/ai-model/info`

Dapatkan informasi tentang model yang dimuat.

**Response:**
```json
{
  "status": 200,
  "model_loaded": true,
  "version": "4.0",
  "trained_date": "...",
  "hourly_features": ["day", "month", "year", "hour"],
  "hourly_targets": ["temp", "humidity", "windspeed", "sealevelpressure"],
  "daily_features": ["day", "month", "year"],
  "daily_targets": ["temp_min", "temp_max", "temp_mean", "humidity", "windspeed", "sealevelpressure"]
}
```

---

### 2. Hourly Prediction Endpoint
**POST** `/ai-prediction/hourly`

Prediksi cuaca per jam untuk periode tertentu.

**Request Body:**
```json
{
  "day": 8,
  "month": 12,
  "year": 2025,
  "hour": 10,
  "num_hours": 24
}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `day` | int | ✓ | Hari (1-31) |
| `month` | int | ✓ | Bulan (1-12) |
| `year` | int | ✓ | Tahun (≥2000) |
| `hour` | int | ✗ | Jam mulai (0-23, default: 0) |
| `num_hours` | int | ✗ | Jumlah jam untuk prediksi (default: 24) |

**Response:**
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
    },
    ...
  ]
}
```

---

### 3. Daily Prediction Endpoint
**POST** `/ai-prediction/daily`

Prediksi cuaca harian untuk periode tertentu.

**Request Body:**
```json
{
  "day": 8,
  "month": 12,
  "year": 2025,
  "num_days": 3
}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `day` | int | ✓ | Hari (1-31) |
| `month` | int | ✓ | Bulan (1-12) |
| `year` | int | ✓ | Tahun (≥2000) |
| `num_days` | int | ✗ | Jumlah hari untuk prediksi (default: 3) |

**Response:**
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
    },
    ...
  ]
}
```

---

## Flutter Integration

### 1. Tambahkan Model untuk Request
Tambahkan ke file `lib/pages/variables.dart` atau model file Anda:

```dart
class PredictionRequest {
  final String predictionType;
  final int day;
  final int month;
  final int year;
  final int? hour;
  final int numHours;
  final int numDays;

  PredictionRequest({
    required this.predictionType,
    required this.day,
    required this.month,
    required this.year,
    this.hour,
    this.numHours = 24,
    this.numDays = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'prediction_type': predictionType,
      'day': day,
      'month': month,
      'year': year,
      if (hour != null) 'hour': hour,
      'num_hours': numHours,
      'num_days': numDays,
    };
  }
}
```

### 2. Buat Service untuk AI Prediction
Buat file `lib/services/ai_prediction_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:demo1/pages/variables.dart';

class AIPredictionService {
  static const String baseUrl = '$myDomain/ai-prediction';

  // Prediksi Hourly
  static Future<dynamic> predictHourly({
    required int day,
    required int month,
    required int year,
    required int hour,
    int numHours = 24,
  }) async {
    try {
      final request = {
        'day': day,
        'month': month,
        'year': year,
        'hour': hour,
        'num_hours': numHours,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/hourly'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch hourly prediction');
      }
    } catch (e) {
      print('Error in predictHourly: $e');
      rethrow;
    }
  }

  // Prediksi Daily
  static Future<dynamic> predictDaily({
    required int day,
    required int month,
    required int year,
    int numDays = 3,
  }) async {
    try {
      final request = {
        'day': day,
        'month': month,
        'year': year,
        'num_days': numDays,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/daily'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch daily prediction');
      }
    } catch (e) {
      print('Error in predictDaily: $e');
      rethrow;
    }
  }

  // Get Model Info
  static Future<dynamic> getModelInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$myDomain/ai-model/info'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch model info');
      }
    } catch (e) {
      print('Error in getModelInfo: $e');
      rethrow;
    }
  }
}
```

### 3. Gunakan di Widget
Contoh menggunakan service di widget:

```dart
import 'package:demo1/services/ai_prediction_service.dart';

class PredictionWidget extends StatefulWidget {
  @override
  _PredictionWidgetState createState() => _PredictionWidgetState();
}

class _PredictionWidgetState extends State<PredictionWidget> {
  List<dynamic> hourlyPredictions = [];
  List<dynamic> dailyPredictions = [];
  bool isLoading = false;

  void fetchHourlyPrediction() async {
    setState(() => isLoading = true);
    try {
      final now = DateTime.now();
      final result = await AIPredictionService.predictHourly(
        day: now.day,
        month: now.month,
        year: now.year,
        hour: now.hour,
        numHours: 24,
      );
      
      setState(() {
        hourlyPredictions = result['data'] ?? [];
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching prediction: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void fetchDailyPrediction() async {
    setState(() => isLoading = true);
    try {
      final now = DateTime.now();
      final result = await AIPredictionService.predictDaily(
        day: now.day,
        month: now.month,
        year: now.year,
        numDays: 3,
      );
      
      setState(() {
        dailyPredictions = result['data'] ?? [];
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching prediction: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: fetchHourlyPrediction,
          child: Text('Prediksi Hourly'),
        ),
        ElevatedButton(
          onPressed: fetchDailyPrediction,
          child: Text('Prediksi Daily'),
        ),
        if (isLoading)
          CircularProgressIndicator()
        else if (dailyPredictions.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: dailyPredictions.length,
            itemBuilder: (context, index) {
              final prediction = dailyPredictions[index];
              return Card(
                child: ListTile(
                  title: Text('${prediction['date']}'),
                  subtitle: Text('${prediction['conditions']}'),
                  trailing: Text('${prediction['temp_max']}°C'),
                ),
              );
            },
          ),
      ],
    );
  }
}
```

---

## Contoh Penggunaan

### Via cURL (Testing)

**1. Get Model Info:**
```bash
curl http://192.168.1.87:8000/ai-model/info
```

**2. Prediksi Hourly:**
```bash
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

**3. Prediksi Daily:**
```bash
curl -X POST http://192.168.1.87:8000/ai-prediction/daily \
  -H "Content-Type: application/json" \
  -d '{
    "day": 8,
    "month": 12,
    "year": 2025,
    "num_days": 3
  }'
```

---

## 🎯 Troubleshooting

### Model Tidak Dimuat
**Pesan Error:** `✗ Failed to load AI model`

**Solusi:**
1. Pastikan file `v4_weather_model_combined.joblib` ada di path yang benar
2. Pastikan dependencies sudah diinstall: `pip install joblib pandas scikit-learn`
3. Cek permission file

### Request Invalid
**Pesan Error:** `Input tanggal tidak valid`

**Solusi:**
- Pastikan day: 1-31, month: 1-12, year: ≥2000
- Pastikan hour: 0-23 untuk prediksi hourly

### CORS Error di Flutter
**Solusi:** Backend sudah dikonfigurasi dengan CORS yang permisif. Jika masih error, pastikan URL yang digunakan benar.

---

## 📊 Struktur Model Output

### Hourly Targets
- `temp`: Temperatur (°C)
- `humidity`: Kelembaban (%)
- `windspeed`: Kecepatan angin (m/s)
- `sealevelpressure`: Tekanan permukaan laut (hPa)
- `conditions`: Kondisi cuaca (string)

### Daily Targets
- `temp_min`: Temperatur minimum (°C)
- `temp_max`: Temperatur maksimum (°C)
- `temp_mean`: Temperatur rata-rata (°C)
- `humidity`: Kelembaban (%)
- `windspeed`: Kecepatan angin (m/s)
- `sealevelpressure`: Tekanan permukaan laut (hPa)
- `conditions`: Kondisi cuaca dominan (string)

---

**Last Updated:** December 8, 2025
**Model Version:** 4.0
