import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _rotationData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Estadísticas generales
      final totalProductos = await db.rawQuery('SELECT COUNT(*) as count FROM productos');
      final totalVentas = await db.rawQuery('SELECT COUNT(*) as count FROM ventas');
      final ventasHoy = await db.rawQuery(
        "SELECT COUNT(*) as count FROM ventas WHERE DATE(fecha) = DATE('now')"
      );
      final ingresosHoy = await db.rawQuery(
        "SELECT SUM(total) as total FROM ventas WHERE DATE(fecha) = DATE('now')"
      );
      
      // TOP 10 productos más vendidos
      final topProducts = await db.rawQuery('''
        SELECT p.nombre, p.codigo, SUM(d.cantidad) as total_vendido,
               SUM(d.subtotal) as total_ingresos
        FROM detalle_ventas d
        JOIN productos p ON d.producto_id = p.id
        GROUP BY d.producto_id
        ORDER BY total_vendido DESC
        LIMIT 10
      ''');
      
      // Rotación por producto (ventas / stock promedio)
      final rotation = await db.rawQuery('''
        SELECT p.nombre, p.stock_actual, 
               COALESCE(SUM(d.cantidad), 0) as ventas_periodo,
               CASE 
                 WHEN p.stock_actual > 0 
                 THEN COALESCE(SUM(d.cantidad), 0) * 1.0 / p.stock_actual 
                 ELSE 0 
               END as rotacion
        FROM productos p
        LEFT JOIN detalle_ventas d ON p.id = d.producto_id
        GROUP BY p.id
        ORDER BY rotacion DESC
        LIMIT 10
      ''');
      
      if (mounted) {
        setState(() {
          _stats = {
            'totalProductos': totalProductos.first['count'] ?? 0,
            'totalVentas': totalVentas.first['count'] ?? 0,
            'ventasHoy': ventasHoy.first['count'] ?? 0,
            'ingresosHoy': double.tryParse(ingresosHoy.first['total']?.toString() ?? '0') ?? 0,
          };
          _topProducts = topProducts;
          _rotationData = rotation;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjetas de estadísticas
                  _buildStatsGrid(isDark),
                  const SizedBox(height: 24),
                  
                  // TOP 10 Productos
                  _buildSectionTitle('🏆 Top 10 Productos Más Vendidos', isDark),
                  _buildTopProductsCard(isDark),
                  const SizedBox(height: 24),
                  
                  // Rotación por Producto
                  _buildSectionTitle('📊 Rotación por Producto', isDark),
                  _buildRotationCard(isDark),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('📦', 'Productos', '${_stats['totalProductos']}', Colors.blue, isDark),
        _buildStatCard('🛒', 'Ventas Totales', '${_stats['totalVentas']}', Colors.green, isDark),
        _buildStatCard('📅', 'Ventas Hoy', '${_stats['ventasHoy']}', Colors.orange, isDark),
        _buildStatCard('💰', 'Ingresos Hoy', '\$${_stats['ingresosHoy'].toStringAsFixed(2)}', Colors.purple, isDark),
      ],
    );
  }

  Widget _buildStatCard(String icon, String label, String value, Color color, bool isDark) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTopProductsCard(bool isDark) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: _topProducts.isEmpty
        ? const Padding(padding: EdgeInsets.all(16), child: Text('Sin datos de ventas'))
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topProducts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _topProducts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                ),
                title: Text(item['nombre']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Código: ${item['codigo'] ?? 'N/A'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item['total_vendido']} unid.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('\$${double.tryParse(item['total_ingresos']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0'}', 
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildRotationCard(bool isDark) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: _rotationData.isEmpty
        ? const Padding(padding: EdgeInsets.all(16), child: Text('Sin datos de rotación'))
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rotationData.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _rotationData[index];
              final rotation = double.tryParse(item['rotacion']?.toString() ?? '0') ?? 0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: rotation > 1 ? Colors.green : Colors.orange,
                  child: const Icon(Icons.trending_up, color: Colors.white, size: 18),
                ),
                title: Text(item['nombre']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Stock: ${item['stock_actual']} | Ventas: ${item['ventas_periodo']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rotation > 1 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rotation.toStringAsFixed(2)}x',
                    style: TextStyle(
                      color: rotation > 1 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
