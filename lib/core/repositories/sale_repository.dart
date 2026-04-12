import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/product.dart';
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
    
    return await db.transaction((txn) async {
      // Insertar venta principal
      final ventaId = await txn.insert('ventas', {
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

      // Insertar líneas de venta
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
}
