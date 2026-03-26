import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db async => await _dbHelper.database;

  Future<int> createSale(int? clienteId, List<SaleLine> lines, double total, double paidAmount, double pendingAmount, String? notes) async {
    final db = await _db;
    return await db.transaction((txn) async {
      // Insertar venta con datos de pago
      final ventaId = await txn.insert('ventas', {
        'cliente_id': clienteId,
        'fecha': DateTime.now().toIso8601String(),
        'total': total,
        'monto_pagado': paidAmount,
        'monto_pendiente': pendingAmount,
        'notas_credito': notes,
        'es_fiado': pendingAmount > 0 ? 1 : 0,
      });
      
      // Insertar líneas y actualizar stock
      for (final line in lines) {
        await txn.insert('venta_detalles', {
          'venta_id': ventaId,
          'producto_id': line.productoId,
          'cantidad': line.cantidad,
          'precio_unitario': line.precioUnitario,
          'subtotal': (line.subtotal as num).toDouble(),
        });
        await txn.rawUpdate(
          'UPDATE productos SET stock_actual = stock_actual - ? WHERE id = ?',
          [line.cantidad, line.productoId],
        );
      }
      return ventaId;
    });
  }

  Future<List<Sale>> getAllSales() async {
    final db = await _db;
    final results = await db.query('ventas', orderBy: 'fecha DESC');
    return results.map((m) => Sale.fromMap(m)).toList();
  }

  // RF 20: Listar ventas del día
  Future<List<Sale>> getTodaySales() async {
    final db = await _db;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    
    final results = await db.query(
      'ventas',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'fecha DESC',
    );
    return results.map((m) => Sale.fromMap(m)).toList();
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await _db;
    final results = await db.query('ventas', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Sale.fromMap(results.first);
  }

  Future<double> getTotalIngresos() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COALESCE(SUM(total), 0) as total FROM ventas');
    final value = result.first['total'];
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }
}
