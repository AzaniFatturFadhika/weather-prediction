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

String _latitude = '';
String _longitude = '';

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double rating = 0.0;
  TextEditingController searchController = TextEditingController();
  Timer? _autoRefreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  dynamic userInfo;

  Future<void> fetchUserInfo() async {
    final response = await http
        .get(Uri.parse('$myDomain/userInfo?username=$myUsername'));
    if (response.statusCode == 200) {
      setState(() {
        userInfo = json.decode(response.body)['records'];
      });
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  dynamic weatherSummaryStatus = "";
  List<dynamic> weatherData = [];

 Future<void> fetchWeatherData() async {
  final response = await http
      .get(Uri.parse('$myDomain/weather-data/get/last'));

  if (response.statusCode == 200) {
    setState(() {
      // PERUBAHAN PENTING ADA DI SINI:
      // 1. Hapus ['records'] karena di gambar preview tidak ada key 'records'.
      // 2. Bungkus json.decode(...) dengan kurung siku [ ... ]
      //    Ini trik agar Object {...} berubah jadi List berisi 1 item [{...}]
      //    supaya logika weatherData[0] di bawah tetap jalan.
      weatherData = [json.decode(response.body)];
    });

    // Cek apakah data berhasil masuk (panjang list harusnya 1)
    if (weatherData.isNotEmpty) {
      // Ambil item pertama (index 0), lalu cek key 'isRaining'
      // Di gambar preview terlihat 'isRaining': 0
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
  } else {
    throw Exception('Failed to load weather data');
  }
}

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = 'Latitude: ${position.latitude}';
        _longitude = 'Longitude: ${position.longitude}';
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('My Location'),
            content: Text('$_latitude\n$_longitude'),
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
    // Auto-refresh data setiap 30 detik
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([
      fetchWeatherData(),
      fetchUserInfo(),
    ]);
    setState(() {
      _isLoading = false;
    });
    _animationController.forward(from: 0.0);
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      children: <Widget>[
                        const SizedBox(height: 8.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Search for cities',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onChanged: (value) {
                              // Handle search logic here
                            },
                          ),
                        ),
                const SizedBox(height: 8.0),
                if (weatherData.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    color: Colors.black.withOpacity(0.0),
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoBox("Temperature", '${weatherData[0]['temp']}',
                            Icons.thermostat),
                        const SizedBox(width: 8.0),
                        _buildInfoBox("Humidity",
                            "${weatherData[0]['humidity']}%", Icons.opacity),
                        const SizedBox(width: 8.0),
                        _buildInfoBox(
                            "Light Intensity",
                            "${weatherData[0]['lightIntensity']} Lux",
                            Icons.lightbulb),
                      ],
                    ),
                  ),
                const SizedBox(height: 8.0),
                if (weatherData.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    color: Colors.black.withOpacity(0.0),
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoBox("Air Pressure", "1012 hPa", Icons.compress),
                        const SizedBox(width: 8.0),
                        _buildInfoBox(
                            "Wind Speed",
                            "${weatherData[0]['windSpeed']} m/s",
                            Icons.wind_power),
                        const SizedBox(width: 8.0),
                        _buildInfoBox("Rain", "5 mm", Icons.beach_access),
                      ],
                    ),
                  ),
                const SizedBox(height: 8.0),
                _buildCircularSummary(),
                const SizedBox(height: 16.0),
                _buildSevenDayForecastTable(),
              ],
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            if (userInfo != null)
              DrawerHeader(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${userInfo[0]['username']}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${userInfo[0]['email']}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: 50.0,
              height: 50.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, size: 30.0),
                    onPressed: () {
                      launch(
                          'https://play.google.com/store/games?hl=en_US&gl=US&pli=1');
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 50.0,
              height: 60.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.location_on, size: 30.0),
                    onPressed: () {
                      _getCurrentLocation();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 60.0,
              height: 60.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.star, size: 30.0),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Rating'),
                            content: RatingBar.builder(
                              initialRating: rating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 40.0,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (value) {
                                setState(() {
                                  rating = value;
                                });
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  print('User Rating: $rating');
                                  Navigator.pop(context);
                                },
                                child: const Text('Submit'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String value, IconData iconData) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Icon(iconData, color: Colors.white, size: 30.0),
            const SizedBox(height: 4.0),
            Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularSummary() {
    return Container(
      width: 180.0,
      height: 180.0,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Summary",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Icon(
                weatherSummaryStatus == "Sunny"
                    ? Icons.wb_sunny
                    : Icons.umbrella,
                color: Colors.white,
                size: 30.0),
            const SizedBox(height: 4.0),
            Text(
              weatherSummaryStatus,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> weatherData2 = [
    {
      'date': '2024-05-08',
      'maxTemp': 28,
      'minTemp': 20,
      'rain': 5,
      'humidity': 60,
    },
    {
      'date': '2024-05-09',
      'maxTemp': 27,
      'minTemp': 19,
      'rain': 2,
      'humidity': 55,
    },
    {
      'date': '2024-05-09',
      'maxTemp': 27,
      'minTemp': 19,
      'rain': 2,
      'humidity': 55,
    },
    // Add more days as needed
  ];

  Widget _buildSevenDayForecastTable() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Weather Forecast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          SizedBox(
            width: 10,
            height: 200,
            child: DataTable(
            columns: const [
              DataColumn(
                  label: Text('Date', style: TextStyle(color: Colors.white,fontSize: 12))),
              DataColumn(
                  label:
                      Text('Max Temp', style: TextStyle(color: Colors.white,fontSize: 12))),
              DataColumn(
                  label:
                      Text('Min Temp', style: TextStyle(color: Colors.white,fontSize: 12))),
              DataColumn(
                  label: Text('Rain', style: TextStyle(color: Colors.white,fontSize: 12))),
              // DataColumn(label: Text('Humidity', style: TextStyle(color: Colors.white))),
            ],
            rows: weatherData2.map<DataRow>((record) {
              return DataRow(
                cells: [
                  DataCell(Text('${record['date']}',
                      style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${record['maxTemp']}',
                      style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${record['minTemp']}',
                      style: const TextStyle(color: Colors.white))),
                  DataCell(Text('${record['rain']} mm',
                      style: const TextStyle(color: Colors.white))),
                  // DataCell(Text('${record['humidity']}%',
                  //     style: TextStyle(color: Colors.white))),
                ],
              );
            }).toList(),
          ),
    ),
        ],
      ),
    );
  }


}
