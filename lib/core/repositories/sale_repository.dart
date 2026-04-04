import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db async => await _dbHelper.database;

  Future<int> createSale(
    int? clienteId,
    List<SaleLine> lines,
    double total,
    double montoPagado,
    double montoPendiente,
    String? notasCredito,
    String moneda,
    double tasaCambio,
  ) async {
    final db = await _db;
    final ventaId = await db.insert('ventas', {
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

    for (var line in lines) {
      await db.insert('venta_detalles', {
        'venta_id': ventaId,
        'producto_id': line.productoId,
        'cantidad': line.cantidad,
        'precio_unitario': line.precioUnitario,
        'subtotal': line.subtotal,
      });

      await db.rawUpdate(
        'UPDATE productos SET stock_actual = stock_actual - ? WHERE id = ?',
        [line.cantidad, line.productoId],
      );
    }

    return ventaId;
  }

  Future<List<Sale>> getTodaySales() async {
    final db = await _db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = await db.query(
      'ventas',
      where: 'fecha >= ?',
      whereArgs: [today.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return results.map((m) => Sale.fromMap(m)).toList();
  }

  Future<List<Sale>> getAllSales() async {
    final db = await _db;
    final results = await db.query('ventas', orderBy: 'fecha DESC');
    return results.map((m) => Sale.fromMap(m)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final results = await db.query(
      'ventas',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return results.map((m) => Sale.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getSaleDetail(int id) async {
    final db = await _db;
    final venta = await db.query('ventas', where: 'id = ?', whereArgs: [id]);
    if (venta.isEmpty) return {};
    
    final detalles = await db.rawQuery('''
      SELECT vd.*, p.nombre as producto_nombre
      FROM venta_detalles vd
      JOIN productos p ON vd.producto_id = p.id
      WHERE vd.venta_id = ?
    ''', [id]);
    
    return {
      'venta': venta.first,
      'detalles': detalles,
    };
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await _db;
    final results = await db.query('ventas', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Sale.fromMap(results.first);
  }

  Future<List<SaleLine>> getSaleLines(int ventaId) async {
    final db = await _db;
    final results = await db.query('venta_detalles', where: 'venta_id = ?', whereArgs: [ventaId]);
    return results.map((m) => SaleLine.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getProfitReport() async {
    final db = await _db;
    final sales = await db.query('ventas');
    final totalIngresos = sales.fold(0.0, (sum, s) => sum + (s['total'] as num).toDouble());
    final ventaDetalles = await db.query('venta_detalles');
    final totalCostos = ventaDetalles.fold(0.0, (sum, vd) => sum + ((vd['precio_unitario'] as num).toDouble() * 0.7));
    final ganancia = totalIngresos - totalCostos;
    final margen = totalIngresos > 0 ? (ganancia / totalIngresos) * 100 : 0.0;
    return {
      'ingresos': totalIngresos,
      'costos': totalCostos,
      'ganancia': ganancia,
      'margen': margen,
      'ventas': sales.length,
    };
  }

  Future<List<Map<String, dynamic>>> getTop10Products() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT p.nombre, p.id, COALESCE(SUM(vd.cantidad), 0) as total_vendido
      FROM venta_detalles vd
      JOIN productos p ON vd.producto_id = p.id
      GROUP BY vd.producto_id, p.nombre
      ORDER BY total_vendido DESC
      LIMIT 10
    ''');
    return results;
  }
}
