import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/theme_provider.dart';
import 'core/database/database_helper.dart';
import 'presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ INICIALIZAR BASE DE DATOS ANTES DE CUALQUIER WIDGET
  await DatabaseHelper.instance.database;
  print('✅ Base de datos inicializada correctamente');
  
  FlutterError.onError = (details) {
    print('❌ Error: ${details.exception}');
    FlutterError.presentError(details);
  };

  runApp(const NovaAdenApp());
}

class NovaAdenApp extends StatelessWidget {
  const NovaAdenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Nova ADEN',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            darkTheme: themeProvider.darkThemeData,
            themeMode: themeProvider.themeMode,
            home: const SplashPage(),
            
            // Manejo mejorado de errores
            errorBuilder: (context, exception) {
              return Scaffold(
                backgroundColor: Colors.red[50],
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        "Error al cargar: ${exception.toString().split('.').last}",
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).popAndPushNamed('/'),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
