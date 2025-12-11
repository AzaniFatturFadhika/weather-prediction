import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'variables.dart';

class HomePageNew extends StatefulWidget {
  const HomePageNew({super.key});

  @override
  _HomePageNewState createState() => _HomePageNewState();
}

class _HomePageNewState extends State<HomePageNew> {
  bool _isLoading = true;
  Map<String, dynamic>? _currentWeather;
  List<dynamic> _hourlyForecast = [];
  List<dynamic> _dailyForecast = [];
  String _location = "Location";

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch current weather
      final currentResponse = await http.get(
        Uri.parse('$myDomain/weather-data/last?location=$_location'),
      );

      if (currentResponse.statusCode == 200) {
        setState(() {
          _currentWeather = json.decode(currentResponse.body);
        });
      }

      // Fetch hourly forecast (AI prediction)
      final now = DateTime.now();
      final hourlyResponse = await http.post(
        Uri.parse('$myDomain/ai-prediction/hourly'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'day': now.day,
          'month': now.month,
          'year': now.year,
          'hour': now.hour,
          'num_hours': 24,
        }),
      );

      if (hourlyResponse.statusCode == 200) {
        final data = json.decode(hourlyResponse.body);
        setState(() {
          _hourlyForecast = data['data'] ?? [];
        });
      }

      // Fetch daily forecast (AI prediction)
      final dailyResponse = await http.post(
        Uri.parse('$myDomain/ai-prediction/daily'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'day': now.day,
          'month': now.month,
          'year': now.year,
          'num_days': 7,
        }),
      );

      if (dailyResponse.statusCode == 200) {
        final data = json.decode(dailyResponse.body);
        setState(() {
          _dailyForecast = data['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching weather: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5B9FE3),
              Color(0xFF7AB8F5),
              Color(0xFFB8D4F0),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : RefreshIndicator(
                  onRefresh: _fetchWeatherData,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                SizedBox(height: 20),
                                _buildMainWeatherCard(),
                                SizedBox(height: 15),
                                _buildStatsCard(),
                                SizedBox(height: 20),
                                _buildHourlyForecast(),
                                SizedBox(height: 20),
                                _buildOtherCities(),
                                SizedBox(height: 20), // Bottom padding
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _location,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMMM · HH:mm').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              _showMenuOptions(context);
            },
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_vert, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.refresh, color: Color(0xFF4A90E2)),
              title: Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                _fetchWeatherData();
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Color(0xFF4A90E2)),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Color(0xFF4A90E2)),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    final weather = _hourlyForecast.isNotEmpty ? _hourlyForecast[0] : {};
    final temp = weather['temp']?.toStringAsFixed(0) ?? '22';
    final condition = weather['conditions'] ?? 'Mostly Clear';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5A9FE8),
            Color(0xFF7BB5F0),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        temp,
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        '°',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    condition,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Weather Icon - Sun with cloud
              Container(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    // Sun
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.wb_sunny,
                        size: 70,
                        color: Color(0xFFFDB813),
                      ),
                    ),
                    // Cloud
                    Positioned(
                      left: 0,
                      bottom: 10,
                      child: Icon(
                        Icons.cloud,
                        size: 50,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final weather = _hourlyForecast.isNotEmpty ? _hourlyForecast[0] : {};
    final humidity = weather['humidity']?.toStringAsFixed(0) ?? '20';
    final windSpeed = weather['windspeed']?.toStringAsFixed(0) ?? '12';
    final precip = weather['precip']?.toStringAsFixed(0) ?? '30';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              Icons.water_drop_outlined, '$precip%', 'Precipitation'),
          _buildStatItem(Icons.opacity, '$humidity%', 'Humidity'),
          _buildStatItem(Icons.air, '$windSpeed km/h', 'Wind speed'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF7AB5F0), size: 22),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.pushNamed(context, '/forecast');
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '7-Day Forecasts',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hourlyForecast.isEmpty
                ? 6
                : (_hourlyForecast.length > 6 ? 6 : _hourlyForecast.length),
            itemBuilder: (context, index) {
              final forecast =
                  _hourlyForecast.isNotEmpty && index < _hourlyForecast.length
                      ? _hourlyForecast[index]
                      : {};
              final hour = forecast['datetime']
                      ?.toString()
                      .split(' ')[1]
                      ?.substring(0, 5) ??
                  '${9 + index}:00';
              final temp =
                  forecast['temp']?.toStringAsFixed(0) ?? '${22 - index}';
              final condition = forecast['conditions'] ?? 'Clear';
              final isActive = index == 1;

              return Container(
                width: 65,
                margin: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF5A9FE8), Color(0xFF7BB5F0)],
                        )
                      : null,
                  color: isActive ? null : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(30),
                  border: isActive
                      ? null
                      : Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$hour - $temp°C, $condition'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            hour,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            _getWeatherIcon(condition),
                            color: isActive ? Colors.white : Color(0xFFFDB813),
                            size: 26,
                          ),
                          Text(
                            '$temp°',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOtherCities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Other Cities',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Add city feature coming soon!')),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        _buildCityCard('Location', 'Mostly Cloudy', '21'),
      ],
    );
  }

  Widget _buildCityCard(String city, String condition, String temp) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5A9FE8),
            Color(0xFF7BB5F0),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A90E2).withOpacity(0.25),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _location = city;
            });
            _fetchWeatherData();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          condition,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$temp°',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.cloud,
                      color: Colors.white.withOpacity(0.8),
                      size: 30,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('clear') || condition.contains('sunny')) {
      return Icons.wb_sunny;
    } else if (condition.contains('cloud')) {
      return Icons.cloud;
    } else if (condition.contains('rain') || condition.contains('shower')) {
      return Icons.grain;
    } else if (condition.contains('thunder')) {
      return Icons.flash_on;
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return Icons.cloud_queue;
    } else if (condition.contains('snow')) {
      return Icons.ac_unit;
    }
    return Icons.wb_cloudy;
  }
}
