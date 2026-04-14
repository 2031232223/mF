import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/product.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createSale(
    int? clienteId,
    List<SaleLine> saleLines,
    double total,
    double montoPagado,
    double montoPendiente,
    String? notasCredito,
    String moneda,
    double tasaCambio, {
    double descuento = 0.0,
  }) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // Insertar venta
      final saleId = await txn.insert('ventas', {
        'cliente_id': clienteId,
        'total': total,
        'total_cup': total * tasaCambio,
        'descuento': descuento,
        'subtotal': total + descuento,
        'fecha': DateTime.now().toIso8601String(),
        'metodo_pago': notasCredito,
        'moneda': moneda,
        'tasa_cambio': tasaCambio,
        'es_fiado': montoPendiente > 0 ? 1 : 0,
        'monto_pagado': montoPagado,
        'monto_pendiente': montoPendiente,
        'notas_credito': notasCredito,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insertar detalles
      for (var line in saleLines) {
        await txn.insert('detalle_ventas', {
          'venta_id': saleId,
          'producto_id': line.productoId,
          'cantidad': line.cantidad,
          'precio_unitario': line.precioUnitario,
          'subtotal': line.subtotal,
        });

        // Actualizar stock
        await txn.rawUpdate(
          'UPDATE productos SET stock_actual = stock_actual - ? WHERE id = ?',
          [line.cantidad, line.productoId],
        );
      }

      return saleId;
    });
  }

  Future<List<Sale>> getAllSales({DateTime? startDate, DateTime? endDate}) async {
    final db = await _dbHelper.database;
    
    String where = '';
    List<dynamic> args = [];
    
    if (startDate != null) {
      where += ' AND fecha >= ?';
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where += ' AND fecha <= ?';
      args.add(endDate.toIso8601String());
    }
    
    final result = await db.rawQuery(
      'SELECT * FROM ventas WHERE 1=1 $where ORDER BY fecha DESC',
      args,
    );
    
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('ventas', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Sale.fromMap(result.first);
  }

  Future<List<SaleLine>> getSaleLines(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'detalle_ventas',
      where: 'venta_id = ?',
      whereArgs: [saleId],
    );
    return result.map((map) => SaleLine.fromMap(map)).toList();
  }

  Future<List<Sale>> getTodaySales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return await getAllSales(startDate: startOfDay, endDate: now);
  }

  Future<List<Sale>> getDeudasPendientes() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'ventas',
      where: 'monto_pendiente > 0',
      orderBy: 'fecha DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<void> registrarPagoFiado(int saleId, double monto) async {
    final db = await _dbHelper.database;
    final sale = await getSaleById(saleId);
    if (sale == null) throw Exception('Venta no encontrada');
    
    final nuevoPendiente = sale.montoPendiente - monto;
    final nuevoPagado = sale.montoPagado + monto;
    
    await db.update(
      'ventas',
      {
        'monto_pagado': nuevoPagado,
        'monto_pendiente': nuevoPendiente > 0 ? nuevoPendiente : 0,
        'es_fiado': nuevoPendiente > 0 ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  // RF 51: Sugerir precio por margen
  Future<double> suggestPriceByMargin(double costo, double margenDeseada) {
    if (costo <= 0) return Future.value(0.0);
    return Future.value(costo * (1 + (margenDeseada / 100)));
  }

  // RF 51: Calcular margen actual de producto
  Future<Map<String, dynamic>> calculateProductMargin(Product product) async {
    final margen = product.precioVenta - product.costo;
    final porcentajeMargen = product.costo > 0 ? (margen / product.costo) * 100 : 0.0;
    
    return {
      'producto': product.nombre,
      'costo': product.costo,
      'precioVenta': product.precioVenta,
      'margen': margen,
      'porcentajeMargen': porcentajeMargen,
      'sugerido20': suggestPriceByMargin(product.costo, 20),
      'sugerido30': suggestPriceByMargin(product.costo, 30),
      'sugerido50': suggestPriceByMargin(product.costo, 50),
    };
  }

  // RF 20: Ventas del día
  Future<Map<String, dynamic>> getTodaySalesSummary() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as cantidad,
        SUM(total) as total,
        SUM(monto_pagado) as pagado,
        SUM(monto_pendiente) as pendiente
      FROM ventas
      WHERE fecha >= ?
    ''', [startOfDay.toIso8601String()]);
    
    if (result.isNotEmpty) {
      return {
        'cantidad': result.first['cantidad'] as int? ?? 0,
        'total': (result.first['total'] as num?)?.toDouble() ?? 0.0,
        'pagado': (result.first['pagado'] as num?)?.toDouble() ?? 0.0,
        'pendiente': (result.first['pendiente'] as num?)?.toDouble() ?? 0.0,
      };
    }
    
    return {'cantidad': 0, 'total': 0.0, 'pagado': 0.0, 'pendiente': 0.0};
  }

  // RF 64: Flujo de caja (ingresos por ventas)
  Future<List<Map<String, dynamic>>> getCashFlowByDate({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        DATE(fecha) as fecha,
        SUM(monto_pagado) as ingresos,
        COUNT(*) as ventas
      FROM ventas
      WHERE fecha >= ? AND fecha <= ? AND es_fiado = 0
      GROUP BY DATE(fecha)
      ORDER BY fecha
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    return result;
  }

  // Eliminar venta (solo si no tiene detalles)
  Future<void> deleteSale(int id) async {
    final db = await _dbHelper.database;
    await db.delete('ventas', where: 'id = ?', whereArgs: [id]);
  }
}
