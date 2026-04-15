import 'package:flutter/material.dart';
import '../../main.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Solo 0.8 segundos
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BottomNavMainPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text('Nova ADEN', style: TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Administrador de Negocios', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 40),
            SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}
