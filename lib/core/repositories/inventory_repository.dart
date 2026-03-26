import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/inventory_adjustment.dart';
// import '../models/waste_record.dart';

class InventoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db async => await _dbHelper.database;

  // RF 23: Stock valorado
  Future<List<Map<String, dynamic>>> getValuedStock() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT p.*, (p.costo * p.stock_actual) as valor_total 
      FROM productos p ORDER BY valor_total DESC
    ''');
    return results;
  }

  // RF 24-25: Registrar ajuste de inventario
  Future<int> registerAdjustment(InventoryAdjustment adj) async {
    final db = await _db;
    return await db.transaction((txn) async {
      await txn.insert('ajustes_inventario', adj.toMap());
      final multiplier = adj.type == AdjustmentType.positive ? 1 : -1;
      await txn.rawUpdate(
        'UPDATE productos SET stock_actual = stock_actual + ? WHERE id = ?',
        [adj.cantidad * multiplier, adj.productoId],
      );
      return 1;
    });
  }

  // RF 29: Reporte de inventario
  Future<Map<String, dynamic>> getInventoryReport() async {
    final db = await _db;
    final products = await db.query('productos');
    final totalProducts = products.length;
    final totalStock = products.fold(0, (s, p) => s + (p['stock_actual'] as int));
    final totalValue = products.fold(0.0, (s, p) => s + ((p['costo'] as num) * (p['stock_actual'] as int)));
    final lowStock = products.where((p) => (p['stock_actual'] as int) <= (p['stock_minimo'] as int)).length;
    
    return {
      'totalProductos': totalProducts,
      'totalStock': totalStock,
      'valorTotal': totalValue,
      'alertasStock': lowStock,
      'productos': products,
    };
  }

  // RF 30: Movimientos por producto (simplificado)
  Future<List<Map<String, dynamic>>> getProductMovements(int productId) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT 'venta' as tipo, cantidad, precio_unitario, fecha 
      FROM venta_detalles WHERE producto_id = ?
    ''', [productId]);
  }

  // RF 33: Compras por proveedor (placeholder)
  Future<Map<String, dynamic>> getPurchasesBySupplier(int supplierId) async {
    return {'proveedor_id': supplierId, 'productos': [], 'totalInversion': 0.0};
  }
}
