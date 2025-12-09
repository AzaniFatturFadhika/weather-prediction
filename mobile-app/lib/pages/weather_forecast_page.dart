import 'package:flutter/material.dart';
import '../services/ai_prediction_service.dart';

class WeatherForecastPage extends StatefulWidget {
  const WeatherForecastPage({super.key});

  @override
  State<WeatherForecastPage> createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 7)); // Default 7 hari
  List<Map<String, dynamic>> _forecastData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Otomatis load data saat halaman dibuka
    _generateForecast();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _generateForecast(); // Auto refresh saat tanggal berubah
    }
  }

  Future<void> _generateForecast() async {
    setState(() {
      _isLoading = true;
      _forecastData.clear();
    });

    try {
      final int numDays =
          _selectedEndDate.difference(_selectedStartDate).inDays + 1;

      final result = await AIPredictionService.predictDaily(
        day: _selectedStartDate.day,
        month: _selectedStartDate.month,
        year: _selectedStartDate.year,
        numDays: numDays,
      );

      if (result['status'] == 200 && result['data'] != null) {
        final List<dynamic> forecasts = result['data'];
        final List<Map<String, dynamic>> allForecasts = [];

        for (var i = 0; i < forecasts.length; i++) {
          final dayData = forecasts[i];
          final forecastDate = DateTime.parse(dayData['date']);

          allForecasts.add({
            'date': forecastDate,
            'conditions': dayData['conditions'],
            'temp_min': dayData['temp_min'],
            'temp_max': dayData['temp_max'],
            'temp_mean': dayData['temp_mean'],
            'humidity_avg': dayData['humidity_avg'],
            'windspeed_avg': dayData['windspeed_avg'],
            'pressure_avg': dayData['pressure_avg'],
          });
        }
        setState(() {
          _forecastData = allForecasts;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Forecast",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        // Menggunakan Gradient yang sama dengan HomePage
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary
              ],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Tombol back putih
        titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Bagian Pemilih Tanggal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDateSelector(context),
          ),
          const SizedBox(height: 16),
          // List Forecast
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _forecastData.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _forecastData.length,
                        itemBuilder: (context, index) {
                          return _buildForecastCard(context, _forecastData[index]);
                        },
                      )
                    : const Center(
                        child: Text("No forecast data available", style: TextStyle(color: Colors.grey)),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    // Style disesuaikan dengan _buildInfoCard di HomePage
    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Prediction Range",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_month, 
                      size: 18, 
                      color: Theme.of(context).colorScheme.primary
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${_selectedStartDate.day}/${_selectedStartDate.month} - ${_selectedEndDate.day}/${_selectedEndDate.month} ${_selectedEndDate.year}",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(BuildContext context, Map<String, dynamic> data) {
    final date = data['date'] as DateTime;
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    final condition = data['conditions'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
        // Shadow sama dengan HomePage
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Card: Hari, Tanggal, Icon Cuaca Utama
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getConditionColor(condition).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: _getWeatherIcon(condition),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "${date.day}/${date.month}/${date.year}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${((data['temp_mean'] as num?) ?? 0).toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B), // Warna merah dari HomePage
                    ),
                  ),
                  Text(
                    condition,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          // Detail Grid: Menggunakan style mini info card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniInfo(
                context, 
                Icons.water_drop, 
                "${((data['humidity_avg'] as num?) ?? 0).toStringAsFixed(0)}%", 
                const Color(0xFF4ECDC4) // Warna Teal dari HomePage
              ),
              _buildMiniInfo(
                context, 
                Icons.air, 
                "${((data['windspeed_avg'] as num?) ?? 0).toStringAsFixed(1)} m/s", 
                const Color(0xFFAA96DA) // Warna Ungu dari HomePage
              ),
              _buildMiniInfo(
                context, 
                Icons.compress, 
                "${((data['pressure_avg'] as num?) ?? 0).toStringAsFixed(0)} hPa", 
                const Color(0xFF95E1D3) // Warna Light Teal dari HomePage
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mini version of _buildInfoCard from HomePage
  Widget _buildMiniInfo(BuildContext context, IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Color _getConditionColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain')) return const Color(0xFF6C5CE7);
    if (c.contains('sunny') || c.contains('clear')) return Colors.orange;
    return Colors.blueGrey;
  }

  Icon _getWeatherIcon(String condition) {
    final c = condition.toLowerCase();
    IconData iconData;
    Color iconColor;

    if (c.contains('partially cloudy')) {
      iconData = Icons.wb_cloudy;
      iconColor = Colors.grey;
    } else if (c.contains('rain') || c.contains('showers')) {
      iconData = Icons.grain; // atau Icons.umbrella sesuai HomePage
      iconColor = const Color(0xFF6C5CE7); // Deep Purple
    } else if (c.contains('clear') || c.contains('sunny')) {
      iconData = Icons.wb_sunny;
      iconColor = Colors.orange;
    } else if (c.contains('overcast')) {
      iconData = Icons.cloud;
      iconColor = Colors.blueGrey;
    } else {
      iconData = Icons.wb_sunny;
      iconColor = Colors.orange;
    }
    return Icon(iconData, color: iconColor, size: 32);
  }
}