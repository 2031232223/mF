import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _ventasCount = 0;
  int _productosCount = 0;
  int _proveedoresCount = 0;
  int _clientesCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  // Cargar datos REALES desde base de datos
  Future<void> _loadRealData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Conteos automáticos desde tablas
      final v = await db.rawQuery('SELECT COUNT(*) as c FROM ventas');
      final p = await db.rawQuery('SELECT COUNT(*) as c FROM productos');
      final pr = await db.rawQuery('SELECT COUNT(*) as c FROM proveedores');
      final c = await db.rawQuery('SELECT COUNT(*) as c FROM clientes');

      setState(() {
        _ventasCount = Sqflite.firstIntValue(v) ?? 0;
        _productosCount = Sqflite.firstIntValue(p) ?? 0;
        _proveedoresCount = Sqflite.firstIntValue(pr) ?? 0;
        _clientesCount = Sqflite.firstIntValue(c) ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Widget _statCard({required IconData icon, required String label, required int value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del Negocio'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRealData)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRealData,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    const Text('Indicadores Clave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _statCard(icon: Icons.attach_money, label: 'Ventas Registradas', value: _ventasCount, color: Colors.green),
                    const SizedBox(height: 12),
                    _statCard(icon: Icons.inventory_2, label: 'Productos en Stock', value: _productosCount, color: Colors.orange),
                    const SizedBox(height: 12),
                    _statCard(icon: Icons.store, label: 'Proveedores Activos', value: _proveedoresCount, color: Colors.blue),
                    const SizedBox(height: 12),
                    _statCard(icon: Icons.person, label: 'Clientes Registrados', value: _clientesCount, color: Colors.purple),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('💡 Los datos se actualizan automáticamente al registrar operaciones.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
    );
  }
}
