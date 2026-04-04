import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencySettingsPage extends StatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  State<CurrencySettingsPage> createState() => _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends State<CurrencySettingsPage> {
  String _currency = 'CUP';
  double _mlcRate = 120.0;
  double _usdRate = 1.0;

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
      _usdRate = prefs.getDouble('usd_rate') ?? 1.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _currency);
    await prefs.setDouble('mlc_rate', _mlcRate);
    await prefs.setDouble('usd_rate', _usdRate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Configuración guardada'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moneda'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Moneda Principal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              value: _currency,
              items: const [
                DropdownMenuItem(value: 'CUP', child: Text('🇨🇺 Peso Cubano (CUP)')),
                DropdownMenuItem(value: 'MLC', child: Text('💳 MLC')),
                DropdownMenuItem(value: 'USD', child: Text('🇺🇸 Dólar (USD)')),
              ],
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 24),
            const Text('Tasas de Cambio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('💳 MLC: 1 MLC = ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '120.0'),
                    controller: TextEditingController(text: _mlcRate.toString()),
                    onChanged: (v) => _mlcRate = double.tryParse(v) ?? 120.0,
                  ),
                ),
                const Text(' CUP'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🇺🇸 USD: 1 USD = ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '1.0'),
                    controller: TextEditingController(text: _usdRate.toString()),
                    onChanged: (v) => _usdRate = double.tryParse(v) ?? 1.0,
                  ),
                ),
                const Text(' CUP'),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
