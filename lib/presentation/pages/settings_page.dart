import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/models/product.dart';

class SettingsPage extends StatefulWidget {
  final Function()? onToggleTheme;
  final bool isDark;
  const SettingsPage({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _productRepo = ProductRepository();
  bool _loading = false;
  
  // RF 35: Monedas
  String _currency = 'CUP';
  double _mlcRate = 120.0;
  
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
      _currency = prefs.getString('currency') ?? 'CUP';
      _mlcRate = prefs.getDouble('mlc_rate') ?? 120.0;
      _defaultStockMinimo = prefs.getInt('stock_minimo_default') ?? 5;
      _defaultStockCritico = prefs.getInt('stock_critico_default') ?? 2;
    });
  }

  Future<void> _saveCurrencySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _currency);
    await prefs.setDouble('mlc_rate', _mlcRate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Configuración de moneda guardada'), backgroundColor: Colors.green),
      );
    }
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

  // RF 38: Respaldar manualmente
  Future<void> _createBackup() async {
    setState(() => _loading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = '${directory.path}/nova_aden_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final products = await _productRepo.getAllProducts();
      final backupData = {
        'version': AppConstants.appVersion,
        'fecha': DateTime.now().toIso8601String(),
        'productos': products.map((p) => p.toMap()).toList(),
        'configuracion': {
          'moneda': _currency,
          'tasa_mlc': _mlcRate,
          'stock_minimo': _defaultStockMinimo,
          'stock_critico': _defaultStockCritico,
        },
      };
      
      final file = File(backupPath);
      await file.writeAsString(jsonEncode(backupData));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Respaldo creado: ${file.path.split('/').last}'), 
            backgroundColor: Colors.green, 
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  // RF 39: Restaurar desde respaldo
  Future<void> _restoreBackup() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('♻️ Restaurar Respaldo'),
        content: const Text('Esta acción reemplazará los datos actuales. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // En producción: usar file picker para seleccionar archivo
              setState(() => _loading = true);
              await Future.delayed(const Duration(seconds: 2));
              setState(() => _loading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔄 Restauración completada (simulada)'), backgroundColor: Colors.blue),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // RF 45: Tema oscuro/claro
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🌙 Tema Oscuro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Switch(value: widget.isDark, onChanged: (_) => widget.onToggleTheme?.call()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // RF 35: Configuración de Monedas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💱 Moneda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Moneda principal', border: OutlineInputBorder()),
                    value: _currency,
                    items: const [
                      DropdownMenuItem(value: 'CUP', child: Text('🇨🇺 Peso Cubano (CUP)')),
                      DropdownMenuItem(value: 'MLC', child: Text('💳 MLC')),
                      DropdownMenuItem(value: 'USD', child: Text('🇺🇸 Dólar (USD)')),
                    ],
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                  if (_currency == 'CUP') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Tasa MLC: '),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '120.0'),
                            onChanged: (v) => _mlcRate = double.tryParse(v) ?? 120.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    onPressed: _saveCurrencySettings,
                    icon: const Icon(Icons.save),
                    label: const Text('GUARDAR MONEDA'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  )),
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
          
          // RF 37-39: Respaldos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💾 Respaldos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('📅 Respaldos automáticos', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Diario a las 23:59'),
                      Switch(value: true, onChanged: (v) {}),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('📥 Respaldo manual', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createBackup,
                          icon: const Icon(Icons.backup),
                          label: const Text('CREAR RESPALDO'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _restoreBackup,
                          icon: const Icon(Icons.restore),
                          label: const Text('RESTAURAR'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('📁 /Documents/nova_aden_backup_*.json', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Información de la app (SIN contar RF)
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
