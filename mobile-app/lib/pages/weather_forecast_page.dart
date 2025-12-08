import 'package:flutter/material.dart';
import '../services/ai_prediction_service.dart';

class WeatherForecastPage extends StatefulWidget {
  const WeatherForecastPage({Key? key}) : super(key: key);

  @override
  State<WeatherForecastPage> createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 3));
  List<Map<String, dynamic>> _forecastData = [];
  bool _isLoading = false;

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }

  Future<void> _generateForecast() async {
    setState(() {
      _isLoading = true;
      _forecastData.clear();
    });

    try {
      // Calculate number of days
      final int daysDiff = _selectedEndDate.difference(_selectedStartDate).inDays + 1;
      
      // Generate forecast for each day
      List<Map<String, dynamic>> allForecasts = [];
      
      for (int i = 0; i < daysDiff; i++) {
        final targetDate = _selectedStartDate.add(Duration(days: i));
        
        try {
          final result = await AIPredictionService.predictDaily(
            day: targetDate.day,
            month: targetDate.month,
            year: targetDate.year,
            numDays: 1, // Predict one day at a time
          );

          if (result['status'] == 200 && result['data'] != null) {
            final dayData = result['data'][0]; // First (and only) day
            allForecasts.add({
              'date': targetDate,
              'conditions': dayData['conditions'],
              'temp_min': dayData['temp_min'],
              'temp_max': dayData['temp_max'],
              'temp_mean': dayData['temp_mean'],
              'humidity_avg': dayData['humidity_avg'],
              'windspeed_avg': dayData['windspeed_avg'],
              'pressure_avg': dayData['pressure_avg'],
            });
          }
        } catch (e) {
          print('Error predicting for ${targetDate.toIso8601String()}: $e');
          // Add placeholder data for failed prediction
          allForecasts.add({
            'date': targetDate,
            'conditions': 'Error',
            'temp_min': 0.0,
            'temp_max': 0.0,
            'temp_mean': 0.0,
            'humidity_avg': 0.0,
            'windspeed_avg': 0.0,
            'pressure_avg': 0.0,
          });
        }
      }

      setState(() {
        _forecastData = allForecasts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating forecast: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text('Weather Forecast'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selection Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('From:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                '${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                '${_selectedEndDate.day}/${_selectedEndDate.month}/${_selectedEndDate.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Select Dates'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _generateForecast,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.psychology),
                            label: Text(_isLoading ? 'Generating...' : 'Generate Forecast'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Forecast Results
            if (_forecastData.isNotEmpty) ...[
              const Text(
                'Weather Forecast Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildForecastTable(),
              ),
            ] else if (!_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Select date range and generate forecast\nto see predictions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        elevation: 4,
        child: DataTable(
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          dataTextStyle: const TextStyle(fontSize: 13),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Conditions')),
            DataColumn(label: Text('Min Temp\n(°C)')),
            DataColumn(label: Text('Max Temp\n(°C)')),
            DataColumn(label: Text('Avg Temp\n(°C)')),
            DataColumn(label: Text('Humidity\n(%)')),
            DataColumn(label: Text('Wind\n(km/h)')),
            DataColumn(label: Text('Pressure\n(hPa)')),
          ],
          rows: _forecastData.map((forecast) {
            final date = forecast['date'] as DateTime;
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConditionColor(forecast['conditions']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      forecast['conditions'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(Text('${forecast['temp_min'].toStringAsFixed(1)}')),
                DataCell(Text('${forecast['temp_max'].toStringAsFixed(1)}')),
                DataCell(Text('${forecast['temp_mean'].toStringAsFixed(1)}')),
                DataCell(Text('${forecast['humidity_avg'].toStringAsFixed(0)}')),
                DataCell(Text('${forecast['windspeed_avg'].toStringAsFixed(1)}')),
                DataCell(Text('${forecast['pressure_avg'].toStringAsFixed(0)}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'rain':
        return Colors.blue;
      case 'overcast':
        return Colors.grey;
      case 'cloudy':
        return Colors.blueGrey;
      default:
        return Colors.grey.shade600;
    }
  }
}