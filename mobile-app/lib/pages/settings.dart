import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utility/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedUnit = 'Celsius';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 24),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          _buildSettingsCard(
            context,
            children: [
              _buildTemperatureUnitTile(context),
              _buildDarkModeTile(context, themeProvider),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsCard(
            context,
            children: [
              _buildInfoTile(context, 'About', Icons.info_outline),
              _buildInfoTile(context, 'Privacy Policy', Icons.privacy_tip_outlined),
              _buildInfoTile(context, 'Terms of Service', Icons.description_outlined),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTemperatureUnitTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.thermostat_outlined),
      title: const Text('Temperature Unit'),
      subtitle: Text(_selectedUnit),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showTemperatureUnitDialog(context),
    );
  }

  Widget _buildDarkModeTile(
      BuildContext context, ThemeProvider themeProvider) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('Dark Mode'),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.toggleTheme(value);
        },
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Handle navigation to info pages
      },
    );
  }

  void _showTemperatureUnitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Temperature Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Celsius'),
                value: 'Celsius',
                groupValue: _selectedUnit,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedUnit = value;
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Fahrenheit'),
                value: 'Fahrenheit',
                groupValue: _selectedUnit,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedUnit = value;
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
