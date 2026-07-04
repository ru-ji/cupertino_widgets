import 'package:flutter/material.dart';

class SettingsTabPage extends StatelessWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48),
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text('Notifications', style: TextStyle(fontSize: 18)),
          Divider(),
          Text('Privacy', style: TextStyle(fontSize: 18)),
          Divider(),
          Text('About', style: TextStyle(fontSize: 18)),
          Divider(),
        ],
      ),
    );
  }
}
