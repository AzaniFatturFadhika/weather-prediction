import 'package:flutter/material.dart';
import '../services/ai_prediction_service.dart';

class SimpleAIPredictionDemo extends StatefulWidget {
  const SimpleAIPredictionDemo({Key? key}) : super(key: key);

  @override
  State<SimpleAIPredictionDemo> createState() => _SimpleAIPredictionDemoState();
}

class _SimpleAIPredictionDemoState extends State<SimpleAIPredictionDemo> {
  Map<String, dynamic>? _dailyData;
  Map<String, dynamic>? _hourlyData;
  bool _loading = false;

  Future<void> _testDailyPrediction() async {
    setState(() {
      _loading = true;
    });

    try {
      final result = await AIPredictionService.predictNextDays(numDays: 3);
      setState(() {
        _dailyData = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _testHourlyPrediction() async {
    setState(() {
      _loading = true;
    });

    try {
      final result = await AIPredictionService.predictTodayHourly(numHours: 12);
      setState(() {
        _hourlyData = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Prediction Demo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _testDailyPrediction,
                    child: const Text('Test Daily Prediction'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _testHourlyPrediction,
                    child: const Text('Test Hourly Prediction'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Daily Results
                      if (_dailyData != null) ...[
                        const Text(
                          'Daily Prediction Results:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _dailyData.toString(),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Hourly Results
                      if (_hourlyData != null) ...[
                        const Text(
                          'Hourly Prediction Results:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _hourlyData.toString(),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}