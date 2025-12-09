import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:demo1/pages/variables.dart';

/// Service untuk mengakses endpoint prediksi cuaca AI dari backend
class AIPredictionService {
  /// Prediksi cuaca per jam (Hourly Prediction)
  ///
  /// Parameters:
  /// - [day]: Hari (1-31)
  /// - [month]: Bulan (1-12)
  /// - [year]: Tahun (>= 2000)
  /// - [hour]: Jam mulai (0-23)
  /// - [numHours]: Jumlah jam untuk prediksi (default: 24)
  ///
  /// Returns: Map berisi status, message, dan data prediksi
  static Future<Map<String, dynamic>> predictHourly({
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
        Uri.parse('$myDomain/ai-prediction/hourly'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Gagal mengambil prediksi hourly: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in predictHourly: $e');
      rethrow;
    }
  }

  /// Prediksi cuaca harian (Daily Prediction)
  ///
  /// Parameters:
  /// - [day]: Hari (1-31)
  /// - [month]: Bulan (1-12)
  /// - [year]: Tahun (>= 2000)
  /// - [numDays]: Jumlah hari untuk prediksi (default: 3)
  ///
  /// Returns: Map berisi status, message, dan data prediksi
  static Future<Map<String, dynamic>> predictDaily({
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
        Uri.parse('$myDomain/ai-prediction/daily'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Gagal mengambil prediksi daily: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in predictDaily: $e');
      rethrow;
    }
  }

  /// Dapatkan informasi tentang model AI yang dimuat
  ///
  /// Returns: Map berisi informasi model (version, features, targets, dll)
  static Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$myDomain/ai-prediction/model-info'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengambil info model: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getModelInfo: $e');
      rethrow;
    }
  }

  /// Helper function untuk prediksi hari ini (hourly)
  static Future<Map<String, dynamic>> predictTodayHourly(
      {int numHours = 24}) async {
    final now = DateTime.now();
    return predictHourly(
      day: now.day,
      month: now.month,
      year: now.year,
      hour: now.hour,
      numHours: numHours,
    );
  }

  /// Helper function untuk prediksi beberapa hari ke depan (daily)
  static Future<Map<String, dynamic>> predictNextDays(
      {int numDays = 3}) async {
    final now = DateTime.now();
    return predictDaily(
      day: now.day,
      month: now.month,
      year: now.year,
      numDays: numDays,
    );
  }
}
