import 'package:demo1/pages/profile.dart';
import 'package:demo1/pages/settings.dart';
import 'package:demo1/pages/variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePageContent(),
    ProfilePage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weather Station",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
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
        automaticallyImplyLeading: false, // Remove hamburger icon
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double rating = 0.0;
  TextEditingController searchController = TextEditingController();
  Timer? _autoRefreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  dynamic userInfo;

  Future<void> fetchUserInfo() async {
    final response =
        await http.get(Uri.parse('$myDomain/userInfo?username=$myUsername'));
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          userInfo = json.decode(response.body)['records'];
        });
      }
    } else {
      throw Exception('Failed to load user data');
    }
  }

  dynamic weatherSummaryStatus = "";
  List<dynamic> weatherData = [];
  List<dynamic> weatherForecastData = [];

  Future<void> fetchWeatherData() async {
    try {
      final response = await http
          .get(Uri.parse('$myDomain/weather-data/get/last?location=Gazipur'));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            weatherData = [json.decode(response.body)];
          });

          if (weatherData.isNotEmpty) {
            if (weatherData[0]['isRaining'] == 0) {
              setState(() {
                weatherSummaryStatus = "Sunny";
              });
            } else {
              setState(() {
                weatherSummaryStatus = "Raining";
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  Future<void> fetchWeatherForecast() async {
    try {
      final now = DateTime.now();
      final response = await http.get(Uri.parse(
          '$myDomain/weather-data/get-predicted-data?day=${now.day}&month=${now.month}&year=${now.year}'));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            weatherForecastData = json.decode(response.body);
          });
        }
      }
    } catch (e) {
      print('Error fetching weather forecast: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String latitude = 'Latitude: ${position.latitude}';
      String longitude = 'Longitude: ${position.longitude}';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('My Location'),
            content: Text('$latitude\n$longitude'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    await Future.wait([
      fetchWeatherData(),
      fetchUserInfo(),
      fetchWeatherForecast(),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    const SizedBox(height: 8.0),
                    _buildSearchBar(context),
                    const SizedBox(height: 16.0),
                    _buildAIDemoButton(context),
                    const SizedBox(height: 20.0),
                    if (weatherData.isNotEmpty) _buildWeatherRow1(context),
                    const SizedBox(height: 16.0),
                    if (weatherData.isNotEmpty) _buildWeatherRow2(context),
                    const SizedBox(height: 24.0),
                    _buildCircularSummary(context),
                    const SizedBox(height: 24.0),
                    _buildSevenDayForecastTable(context),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: 'Search for cities',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) {
          // Handle search logic here
        },
      ),
    );
  }

  Widget _buildWeatherRow1(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            "Temperature",
            '${weatherData[0]['temp']}°C',
            Icons.thermostat,
            const Color(0xFFFF6B6B),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildInfoCard(
            context,
            "Humidity",
            "${weatherData[0]['humidity']}%",
            Icons.opacity,
            const Color(0xFF4ECDC4),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildInfoCard(
            context,
            "Light",
            "${weatherData[0]['lightIntensity']} Lux",
            Icons.lightbulb,
            const Color(0xFFFFE66D),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherRow2(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            "Air Pressure",
            "${weatherData[0]['airPressure']} hPa",
            Icons.compress,
            const Color(0xFF95E1D3),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildInfoCard(
            context,
            "Wind Speed",
            "${weatherData[0]['windSpeed']} m/s",
            Icons.air,
            const Color(0xFFAA96DA),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildInfoCard(
            context,
            "Rain",
            weatherData[0]['isRaining'] == 0 ? "No Rain" : "Raining",
            Icons.umbrella,
            const Color(0xFF6C5CE7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value,
      IconData iconData, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 28.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularSummary(BuildContext context) {
    return Container(
      width: 200.0,
      height: 200.0,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Summary",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: weatherSummaryStatus == "Sunny"
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                weatherSummaryStatus == "Sunny"
                    ? Icons.wb_sunny
                    : Icons.umbrella,
                color: weatherSummaryStatus == "Sunny"
                    ? Colors.orange
                    : Colors.blue,
                size: 40.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              weatherSummaryStatus,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSevenDayForecastTable(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weather Forecast',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                theme.colorScheme.primary.withOpacity(0.1),
              ),
              columns: [
                DataColumn(
                  label: Text('Date', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Max Temp', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Min Temp', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Conditions', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: weatherForecastData.map<DataRow>((record) {
                return DataRow(
                  cells: [
                    DataCell(Text('${record['date']}', style: textTheme.bodyMedium)),
                    DataCell(Text('${record['tempmax']}°C', style: textTheme.bodyMedium)),
                    DataCell(Text('${record['tempmin']}°C', style: textTheme.bodyMedium)),
                    DataCell(Text('${record['conditions']}', style: textTheme.bodyMedium)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIDemoButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/forecast');
            },
            icon: const Icon(Icons.calendar_view_week),
            label: const Text('Weather Forecast (Date Range)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/ai-demo');
            },
            icon: const Icon(Icons.psychology),
            label: const Text('AI Prediction Demo (Testing)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }
}
