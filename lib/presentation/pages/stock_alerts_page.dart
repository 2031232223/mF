import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockAlertsPage extends StatefulWidget {
  const StockAlertsPage({super.key});

  @override
  State<StockAlertsPage> createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage> {
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

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stock_minimo_default', _defaultStockMinimo);
    await prefs.setInt('stock_critico_default', _defaultStockCritico);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Alertas configuradas'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas de Stock'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock Mínimo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Se alertará cuando el stock esté por debajo de este valor', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock mínimo', border: OutlineInputBorder()),
              controller: TextEditingController(text: '$_defaultStockMinimo'),
              onChanged: (v) => _defaultStockMinimo = int.tryParse(v) ?? 5,
            ),
            const SizedBox(height: 32),
            const Text('Stock Crítico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Alerta urgente cuando el stock esté en nivel crítico', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock crítico', border: OutlineInputBorder()),
              controller: TextEditingController(text: '$_defaultStockCritico'),
              onChanged: (v) => _defaultStockCritico = int.tryParse(v) ?? 2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('GUARDAR ALERTAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
