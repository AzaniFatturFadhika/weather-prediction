import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/loginpage.dart';
import 'pages/registration.dart';
import 'pages/home.dart';
import 'pages/settings.dart';
import 'pages/profile.dart';
import 'pages/otp.dart';
import 'utility/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      home: const SplashScreen(),
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFF121212),
        // Further customizations for dark theme
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/reg': (context) => const RegistrationPage(),
        '/home': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/profile': (context) => const ProfilePage(),
        '/otp': (context) => const OtpPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // After 1 seconds, navigate to the login page
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
