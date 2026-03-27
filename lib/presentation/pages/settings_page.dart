import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/repositories/product_repository.dart';

class SettingsPage extends StatefulWidget {
  final ThemeProvider? themeProvider;
  const SettingsPage({super.key, this.themeProvider});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _productRepo = ProductRepository();
  bool _loading = false;
  
  // RF 41: Alertas de stock
  int _defaultStockMinimo = 5;
  int _defaultStockCritico = 2;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultStockMinimo = prefs.getInt('stock_minimo_default') ?? 5;
      _defaultStockCritico = prefs.getInt('stock_critico_default') ?? 2;
    });
  }

  Future<void> _saveStockSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stock_minimo_default', _defaultStockMinimo);
    await prefs.setInt('stock_critico_default', _defaultStockCritico);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Alertas de stock configuradas'), backgroundColor: Colors.green),
      );
    }
  }

  // RF 45: Toggle tema
  void _toggleTheme() {
    widget.themeProvider?.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeProvider?.isDark ?? false;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // RF 45: Tema oscuro/claro
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🌙 Tema Oscuro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Switch(value: isDark, onChanged: (_) => _toggleTheme()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(isDark ? 'Modo oscuro activado' : 'Modo claro activado', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // RF 41: Alertas de stock
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔔 Alertas de Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Stock mínimo: '),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          controller: TextEditingController(text: '$_defaultStockMinimo'),
                          onChanged: (v) => _defaultStockMinimo = int.tryParse(v) ?? 5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Stock crítico: '),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          controller: TextEditingController(text: '$_defaultStockCritico'),
                          onChanged: (v) => _defaultStockCritico = int.tryParse(v) ?? 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    onPressed: _saveStockSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('GUARDAR ALERTAS'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Información de la app (SIN mencionar RF)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ℹ️ Acerca de Nova ADEN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('📱 ${AppConstants.appName}'),
                  Text('🔖 Versión: ${AppConstants.appVersion}'),
                  Text('🇨🇺 Desarrollado en Cuba'),
                  const SizedBox(height: 12),
                  const Text(
                    'Sistema de gestión comercial offline-first para pequeños y medianos negocios.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Gestión de inventario\n• Punto de venta\n• Compras y proveedores\n• Reportes y análisis\n• Respaldos y exportación',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
