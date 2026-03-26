import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db async => await _dbHelper.database;

  Future<int> createSale(int? clienteId, List<SaleLine> lines) async {
    final db = await _db;
    return await db.transaction((txn) async {
      // Insertar venta
      final ventaId = await txn.insert('ventas', {
        'cliente_id': clienteId,
        'fecha': DateTime.now().toIso8601String(),
        'total': lines.fold(0.0, (s, l) => s + l.subtotal),
      });
      
      // Insertar líneas
      for (final line in lines) {
        await txn.insert('venta_detalles', {
          'venta_id': ventaId,
          'producto_id': line.productoId,
          'cantidad': line.cantidad,
          'precio_unitario': line.precioUnitario,
          'subtotal': line.subtotal,
        });
        
        // Actualizar stock del producto
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

  Future<Sale?> getSaleById(int id) async {
    final db = await _db;
    final results = await db.query('ventas', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Sale.fromMap(results.first);
  }

  Future<double> getTotalIngresos() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COALESCE(SUM(total), 0) as total FROM ventas');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
