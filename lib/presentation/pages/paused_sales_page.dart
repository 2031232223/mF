import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/database/database_helper.dart';

class PausedSalesPage extends StatefulWidget {
  const PausedSalesPage({super.key});
  @override
  State<PausedSalesPage> createState() => _PausedSalesPageState();
}

class _PausedSalesPageState extends State<PausedSalesPage> {
  List<Map<String, dynamic>> _pausedSales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPausedSales();
  }

  Future<void> _loadPausedSales() async {
    setState(() => _loading = true);
    final db = await DatabaseHelper.instance.database;
    _pausedSales = await db.query('ventas_pausadas', orderBy: 'fecha_creacion DESC');
    setState(() => _loading = false);
  }

  Future<void> _resumeSale(Map<String, dynamic> sale) async {
    Navigator.pop(context, sale);
  }

  Future<void> _deleteSale(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('ventas_pausadas', where: 'id = ?', whereArgs: [id]);
    await _loadPausedSales();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Venta pausada eliminada'), backgroundColor: Colors.black),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas Pausadas'), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _pausedSales.isEmpty
          ? const Center(child: Text('No hay ventas pausadas', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pausedSales.length,
              itemBuilder: (ctx, i) {
                final sale = _pausedSales[i];
                final products = jsonDecode(sale['productos'] as String);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.pause, color: Colors.white)),
                    title: Text(sale['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🕐 ${sale['fecha_creacion'].toString().split('T')[0]}'),
                        Text('📦 ${products.length} productos'),
                        Text('💰 Total: \$${(sale['total'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.play_arrow, color: Colors.green), onPressed: () => _resumeSale(sale)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSale(sale['id'] as int)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
