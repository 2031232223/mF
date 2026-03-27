import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'presentation/pages/welcome_page.dart';

void main() {
  runApp(const NovaAdenApp());
}

class NovaAdenApp extends StatefulWidget {
  const NovaAdenApp({super.key});

  @override
  State<NovaAdenApp> createState() => _NovaAdenAppState();
}

class _NovaAdenAppState extends State<NovaAdenApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true, brightness: Brightness.dark),
      themeMode: _themeMode,
      home: WelcomePage(onToggleTheme: _toggleTheme),
    );
  }
}
