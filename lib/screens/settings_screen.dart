import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SwitchListTile(
        title: const Text('Dark Mode'),
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.toggleTheme(value);
        },
      ),
    );
  }
}
