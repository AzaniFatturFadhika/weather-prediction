import 'package:flutter/material.dart';
import 'package:demo1/services/ai_prediction_service.dart';

/// Contoh halaman untuk menampilkan prediksi cuaca AI
class AIPredictionPage extends StatefulWidget {
  const AIPredictionPage({super.key});

  @override
  _AIPredictionPageState createState() => _AIPredictionPageState();
}

class _AIPredictionPageState extends State<AIPredictionPage> {
  bool _isLoading = false;
  List<dynamic> _dailyPredictions = [];
  List<dynamic> _hourlyPredictions = [];
  String _selectedTab = 'daily'; // 'daily' atau 'hourly'
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDailyPrediction();
  }

  /// Fetch prediksi daily (harian) dari AI backend
  void _fetchDailyPrediction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AIPredictionService.predictNextDays(numDays: 7);

      if (result['status'] == 200) {
        setState(() {
          _dailyPredictions = result['data'] ?? [];
          _selectedTab = 'daily';
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Terjadi kesalahan';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
      print('Error fetching daily prediction: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetch prediksi hourly (per jam) dari AI backend
  void _fetchHourlyPrediction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AIPredictionService.predictTodayHourly(numHours: 24);

      if (result['status'] == 200) {
        setState(() {
          _hourlyPredictions = result['data'] ?? [];
          _selectedTab = 'hourly';
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Terjadi kesalahan';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
      print('Error fetching hourly prediction: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Weather Prediction'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fetchDailyPrediction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 'daily'
                          ? const Color(0xFF2196F3)
                          : Colors.grey[300],
                    ),
                    child: Text(
                      'Daily Forecast',
                      style: TextStyle(
                        color: _selectedTab == 'daily'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fetchHourlyPrediction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 'hourly'
                          ? const Color(0xFF2196F3)
                          : Colors.grey[300],
                    ),
                    child: Text(
                      'Hourly Forecast',
                      style: TextStyle(
                        color: _selectedTab == 'hourly'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : _selectedTab == 'daily'
                        ? _buildDailyForecastList()
                        : _buildHourlyForecastList(),
          ),
        ],
      ),
    );
  }

  /// Build daily forecast list
  Widget _buildDailyForecastList() {
    if (_dailyPredictions.isEmpty) {
      return const Center(
        child: Text('Tidak ada data prediksi'),
      );
    }

    return ListView.builder(
      itemCount: _dailyPredictions.length,
      itemBuilder: (context, index) {
        final prediction = _dailyPredictions[index];
        return _buildDailyPredictionCard(prediction);
      },
    );
  }

  /// Build daily prediction card
  Widget _buildDailyPredictionCard(dynamic prediction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  prediction['date'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    prediction['conditions'] ?? 'N/A',
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo(
                  'Max Temp',
                  '${prediction['temp_max']?.toString() ?? "N/A"}°C',
                  '🌡️',
                ),
                _buildWeatherInfo(
                  'Min Temp',
                  '${prediction['temp_min']?.toString() ?? "N/A"}°C',
                  '🌡️',
                ),
                _buildWeatherInfo(
                  'Humidity',
                  '${prediction['humidity']?.toString() ?? "N/A"}%',
                  '💧',
                ),
                _buildWeatherInfo(
                  'Wind',
                  '${prediction['windspeed']?.toString() ?? "N/A"} m/s',
                  '💨',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build hourly forecast list
  Widget _buildHourlyForecastList() {
    if (_hourlyPredictions.isEmpty) {
      return const Center(
        child: Text('Tidak ada data prediksi'),
      );
    }

    return ListView.builder(
      itemCount: _hourlyPredictions.length,
      itemBuilder: (context, index) {
        final prediction = _hourlyPredictions[index];
        return _buildHourlyPredictionCard(prediction);
      },
    );
  }

  /// Build hourly prediction card
  Widget _buildHourlyPredictionCard(dynamic prediction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: const Border(
          left: BorderSide(
            color: Color(0xFF2196F3),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction['date_formatted'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  prediction['conditions'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${prediction['temp']?.toString() ?? "N/A"}°C',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '💧 ${prediction['humidity']?.toString() ?? "N/A"}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget untuk menampilkan info cuaca
  Widget _buildWeatherInfo(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
