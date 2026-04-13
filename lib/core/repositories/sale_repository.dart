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

        for (var line in saleLines) {
          await txn.insert('detalle_ventas', {
            'venta_id': ventaId,
            'producto_id': line.productoId,
            'cantidad': line.cantidad,
            'precio_unitario': line.precioUnitario,
            'subtotal': line.subtotal,
          });

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
    await db.delete('ventas', where: 'id = ?', whereArgs: [id]);
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

  // ✅ MÉTODO NUEVO: Registrar pago parcial/total de fiado (RF 57 + 18)
  Future<bool> registrarPagoFiado(int ventaId, double montoPagado, String notas) async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final saleMap = await db.rawQuery('SELECT * FROM ventas WHERE id = ?', [ventaId]);
      if (saleMap.isEmpty) throw Exception('Venta no encontrada');
      
      final venta = Sale.fromMap(saleMap.first);
      final pendienteRestante = venta.montoPendiente - montoPagado;
      
      if (pendienteRestante < 0) {
        throw Exception('Pago excede monto pendiente');
      }

      await db.update(
        'ventas',
        {
          'monto_pagado': venta.montoPagado + montoPagado,
          'monto_pendiente': pendienteRestante.abs(),
          'notas_credito': notas.isNotEmpty 
              ? '${venta.notasCredito ?? ''}\nPago registrado: $notas' 
              : venta.notasCredito,
          'fecha': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [ventaId],
      );

      return pendienteRestante == 0;
    } catch (e) {
      print('Error pagando fiado: $e');
      return false;
    }
  }

  // ✅ MÉTODO NUEVO: Obtener deudas pendientes (RF 58)
  Future<List<Sale>> getDeudasPendientes() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT v.*, c.nombre as cliente_nombre
      FROM ventas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      WHERE v.es_fiado = 1 AND v.monto_pendiente > 0
      ORDER BY v.fecha DESC
    ''');
    
    return result.map((m) => Sale.fromMap(m)).toList();
  // ✅ MÉTODO NUEVO: Flujo de caja (RF 64
Future<Map<String, dynamic>> getFlujoDeCaja(DateTime start, DateTime end) async {
  final db = await DatabaseHelper.instance.database;
  final salesResult = await db.rawQuery(
    'SELECT DATE(v.fecha) as fecha, SUM(CASE WHEN v.moneda = "CUP" THEN v.total ELSE 0 END) as cup FROM ventas v WHERE v.fecha BETWEEN ? AND ? GROUP BY DATE(v.fecha)',
    [start.toIso8601String(), end.toIso8601String()]
  );
  
  return {
    'ventas': salesResult,
    'costos': <Map<String, dynamic>>[],
  };
}
  // ✅ MÉTODO MEJORADO: Rotación de productos (RF 62)
  Future<List<Map<String, dynamic>>> getRotacionProductos() async {
    final db = await DatabaseHelper.instance.database;
    
    return await db.rawQuery('''
      SELECT 
        p.nombre,
        p.codigo,
        COUNT(dv.id) as veces_vendido,
        SUM(dv.cantidad) as total_cantidad,
        SUM(dv.subtotal) as total_ingresos,
        CAST(COUNT(dv.id) AS FLOAT) / 30 as promedio_dia
      FROM productos p
      LEFT JOIN detalle_ventas dv ON dv.producto_id = p.id
      WHERE p.activo = 1
      GROUP BY p.id
      ORDER BY promedio_dia DESC
      LIMIT 10
    ''');
  }

  // ✅ MÉTODO MEJORADO: Margen por producto (RF 63)
  Future<List<Map<String, dynamic>>> getMargenPorProducto() async {
    final db = await DatabaseHelper.instance.database;
    
    return await db.rawQuery('''
      SELECT 
        p.id,
        p.nombre,
        p.costo,
        p.precio_venta,
        (p.precio_venta - p.costo) as margen_unidad,
        ((p.precio_venta - p.costo) / p.precio_venta * 100) as porcentaje_margen
      FROM productos p
      WHERE p.activo = 1 AND p.costo IS NOT NULL
      ORDER BY porcentaje_margen DESC
    ''');
  }

  // ✅ MÉTODO CORREGIDO: Reporte de ganancias (sin errores null)
  Future<Map<String, dynamic>> getProfitReport() async {
    final db = await DatabaseHelper.instance.database;
    
    try {
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
      
      final totalCosto = (costoResult.first['total_costo'] as num?)?.toDouble() ?? 0.0;
      
      final gananciaNeta = totalIngresos - totalCosto;
      final margenPorcentaje = totalIngresos > 0 ? (gananciaNeta / totalIngresos) * 100 : 0.0;

      return {
        'totalIngresos': totalIngresos,
        'totalCosto': totalCosto,
        'gananciaNeta': gananciaNeta,
        'margenPorcentaje': margenPorcentaje,
      };
    } catch (e) {
      print('Error al obtener reporte de ganancias: $e');
      return {
        'totalIngresos': 0.0,
        'totalCosto': 0.0,
        'gananciaNeta': 0.0,
        'margenPorcentaje': 0.0,
      };
    }
  }
}
