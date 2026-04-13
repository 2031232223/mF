import '../database/database_helper.dart';
import '../models/sale.dart';
import 'product_repository.dart';

class SaleRepository {
  final ProductRepository _productRepo = ProductRepository();

  Future<int> createSale(
    int? clienteId,
    List<SaleLine> saleLines,
    double total,
    double montoPagado,
    double montoPendiente,
    String? notasCredito,
    String moneda,
    double tasaCambio,
  ) async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      return await db.transaction((txn) async {
        int? ventaId;
        
        // Insertar venta principal
        ventaId = await txn.insert('ventas', {
          'cliente_id': clienteId,
          'fecha': DateTime.now().toIso8601String(),
          'total': total,
          'monto_pagado': montoPagado,
          'monto_pendiente': montoPendiente,
          'notas_credito': notasCredito,
          'es_fiado': montoPendiente > 0 ? 1 : 0,
          'moneda': moneda,
          'tasa_cambio': tasaCambio,
        });

        // Insertar líneas de venta en detalle_ventas
        for (var line in saleLines) {
          await txn.insert('detalle_ventas', {
            'venta_id': ventaId,
            'producto_id': line.productoId,
            'cantidad': line.cantidad,
            'precio_unitario': line.precioUnitario,
            'subtotal': line.subtotal,
          });

          // Actualizar stock
          await _productRepo.updateProductStock(line.productoId, line.cantidad);
        }

        return ventaId;
      });
    } catch (e) {
      print('❌ Error en createSale: $e');
      rethrow;
    }
  }

  Future<List<Sale>> getAllSales() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('ventas', orderBy: 'fecha DESC');
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Sale.fromMap(maps.first);
  }

  Future<List<SaleLine>> getSaleLines(int ventaId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detalle_ventas',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
    );
    return maps.map((m) => SaleLine.fromMap(m)).toList();
  }

  Future<void> updateSale(Sale sale) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'ventas',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<void> deleteSale(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'ventas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Sale>> getTodaySales() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final maps = await db.query(
      'ventas',
      where: 'fecha >= ? AND fecha < ?',
      whereArgs: [today.toIso8601String(), tomorrow.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getTop10Products() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT 
        p.id,
        p.nombre,
        p.codigo,
        SUM(dv.cantidad) as total_vendido,
        SUM(dv.subtotal) as total_ingresos
      FROM detalle_ventas dv
      INNER JOIN productos p ON dv.producto_id = p.id
      GROUP BY p.id, p.nombre, p.codigo
      ORDER BY total_vendido DESC
      LIMIT 10
    ''');
    return result;
  }

  // ✅ CORREGIDO: Manejo seguro de valores nulos para evitar toStringAsFixed(null)
  Future<Map<String, dynamic>> getProfitReport() async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      // ✅ Evitar null -> usar operador ?? para asignar 0.0
      final ingresosResult = await db.rawQuery(
        'SELECT SUM(total) as total FROM ventas',
      );
      final totalIngresos = (ingresosResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final costoResult = await db.rawQuery('''
        SELECT SUM(dv.cantidad * p.costo) as total_costo
        FROM detalle_ventas dv
        INNER JOIN productos p ON dv.producto_id = p.id
        WHERE p.costo IS NOT NULL
      ''');
      
      // ✅ Evitar null -> usar operador ?? para asignar 0.0
      final totalCosto = (costoResult.first['total_costo'] as num?)?.toDouble() ?? 0.0;
      
      final gananciaNeta = totalIngresos - totalCosto;
      // ✅ Calcular margen solo si totalIngresos > 0 para evitar división por cero
      final margenPorcentaje = totalIngresos > 0 ? (gananciaNeta / totalIngresos) * 100 : 0.0;

      return {
        'totalIngresos': totalIngresos,
        'totalCosto': totalCosto,
        'gananciaNeta': gananciaNeta,
        'margenPorcentaje': margenPorcentaje,
      };
    } catch (e) {
      print('Error al obtener reporte de ganancias: $e');
      // Retorna ceros seguros en caso de falla crítica
      return {
        'totalIngresos': 0.0,
        'totalCosto': 0.0,
        'gananciaNeta': 0.0,
        'margenPorcentaje': 0.0,
      };
    }
  }
}
