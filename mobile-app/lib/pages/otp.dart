import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'variables.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController otpController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    Future<void> sendOTP(String email) async {
      try {
        final Uri url = Uri.parse('$myDomain/generate_otp/?email=$email');
        final http.Response response = await http.get(url);

        if (response.statusCode == 200) {
          print('OTP sent successfully.');
          // Optionally, you can navigate to the OTP verification page here
        } else {
          print('Failed to send OTP. Error: ${response.body}');
        }
      } catch (error) {
        print('Error sending OTP: $error');
      }
    }

    return Scaffold(
      body: Container(

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: otpController,
                decoration: InputDecoration(
                  labelText: "OTP",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () {
                  sendOTP(emailController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  elevation: 5.0,
                ),
                child: const Text('Send OTP'),
              ),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () {
                  // Validate and process OTP
                  // You can add your logic here
                },
                style: ElevatedButton.styleFrom(
                  elevation: 5.0,
                ),
                child: const Text('Verify OTP'),
              ),
              const SizedBox(height: 8.0),
              TextButton(
                onPressed: () {
                  // Add navigation to the registration page if needed
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(),
                child: const Text(
                  'Back to Registration',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
