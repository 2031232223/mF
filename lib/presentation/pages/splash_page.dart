import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E88E5), Color(0xFF42A5F5), Color(0xFF64B5F6)]),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(width: 140, height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]), child: const Icon(Icons.shopping_bag, size: 72, color: Color(0xFF1565C0))),
              const SizedBox(height: 28),
              const Text('Nova ADEN', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              const Text('Administrador de Negocio', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildDot(0), const SizedBox(width: 12), _buildDot(1), const SizedBox(width: 12), _buildDot(2)]),
              const Spacer(flex: 3),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildBadge('Offline', Icons.cloud_off_outlined), const SizedBox(width: 12), _buildBadge('Seguro', Icons.shield_outlined), const SizedBox(width: 12), _buildBadge('Rápido', Icons.bolt_outlined)]),
              const SizedBox(height: 24),
              const Text('Versión 1.0.0', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text('© 2026 Nova ADEN. Todos los derechos reservados.', style: TextStyle(color: Colors.white54, fontSize: 10)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDot(int i) => TweenAnimationBuilder<double>(tween: Tween(begin: 0.3, end: 1.0), duration: Duration(milliseconds: 600 + (i * 200)), builder: (_, v, __) => Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withOpacity(v), shape: BoxShape.circle)));
  Widget _buildBadge(String t, IconData i) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.25))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 15, color: Colors.white), const SizedBox(width: 5), Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))]));
}
