import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/purchase.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db async => await _dbHelper.database;

  Future<int> createPurchase(int supplierId, List<PurchaseLine> lines) async {
    final db = await _db;
    return await db.transaction((txn) async {
      // Insertar compra
      final compraId = await txn.insert('compras', {
        'proveedor_id': supplierId,
        'fecha': DateTime.now().toIso8601String(),
        'total': lines.fold(0.0, (s, l) => s + ((l.subtotal as num?)?.toDouble() ?? 0.0)),
      });
      
      // Insertar líneas y actualizar productos
      for (final line in lines) {
        await txn.insert('compra_detalles', {
          'compra_id': compraId,
          'producto_id': line.productoId,
          'cantidad': line.cantidad,
          'costo_unitario': (line.costoUnitario as num?)?.toDouble() ?? 0.0,
          'subtotal': (line.subtotal as num?)?.toDouble() ?? 0.0,
        });
        
        // Actualizar producto: stock + costo promedio
        final product = await _getProduct(txn, line.productoId);
        if (product != null) {
          final oldStock = product.stockActual;
          final oldCost = product.costo ?? 0.0;
          final newStock = oldStock + line.cantidad;
          final newCost = ((oldCost * oldStock) + (line.costoUnitario * line.cantidad)) / newStock;
          
          await txn.update('productos', {
            'stock_actual': newStock,
            'costo': (newCost as num?)?.toDouble() ?? oldCost,
            // ✅ ELIMINADOS: unidadMedida y categoria (no existen en Product)
          }, where: 'id = ?', whereArgs: [line.productoId]);
        }
      }
      return compraId;
    });
  }

  Future<Product?> _getProduct(Database txn, int productId) async {
    final results = await txn.query('productos', where: 'id = ?', whereArgs: [productId]);
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<List<Purchase>> getAllPurchases() async {
    final db = await _db;
    final results = await db.query('compras', orderBy: 'fecha DESC');
    return results.map((m) => Purchase.fromMap(m)).toList();
  }

  Future<Purchase?> getPurchaseById(int id) async {
    final db = await _db;
    final results = await db.query('compras', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Purchase.fromMap(results.first);
  }
}
