import 'dart:async';
import 'dart:ui'; // ✅ Importación necesaria para Flutter bajo nivel
import 'presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/theme_provider.dart';
import 'presentation/pages/home_page.dart';

void main() {
  // 1. Inicializar Flutter primero (CRÍTICO para plugins y DB)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Manejo global de errores para que no cierre la app sin aviso
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // 3. Ejecutar la app con Provider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const NovaAdenApp(),
    ),
  );
}

class NovaAdenApp extends StatelessWidget {
  const NovaAdenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Nova ADEN',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: const SplashPage(),
          // Intercepta errores de UI para mostrarlos en pantalla
          builder: (context, child) {
            ErrorWidget.builder = (details) {
              return MaterialApp(
                home: Scaffold(
                  backgroundColor: Colors.red[50],
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text("Error Fatal", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.red)),
                            child: SelectableText("${details.exception}", style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            };
            return child!;
          },
        );
      },
    );
  }
}
