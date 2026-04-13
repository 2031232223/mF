import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db async => await _dbHelper.database;

  Future<int> createProduct(Product p) async {
    final db = await _db;
    return await db.insert('productos', p.toMap());
  }

  Future<int> updateProduct(int id, Product p) async {
    final db = await _db;
    return await db.update('productos', p.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await _db;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await _db;
    final results = await db.query('productos', orderBy: 'nombre ASC');
    return results.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await _db;
    final results = await db.query('productos', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<List<Product>> searchProducts(String q) async {
    final db = await _db;
    final results = await db.query('productos',
        where: 'nombre LIKE ? OR codigo LIKE ?',
        whereArgs: ['%$q%', '%$q%']);
    return results.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await _db;
    final results = await db.query('productos',
        where: 'stockActual <= stockMinimo');
    return results.map((m) => Product.fromMap(m)).toList();
  }

  // RF 10: Actualizar costo promedio ponderado
  Future<void> updateCostoPromedio(int productId, double nuevoCosto, int nuevaCantidad) async {
    final db = await _db;
    final product = await getProductById(productId);
    if (product != null) {
      final stockActual = product.stockActual;
      final costoActual = product.costo ?? 0.0;
      final totalStock = stockActual + nuevaCantidad;
      if (totalStock > 0) {
        final nuevoCostoPromedio = ((stockActual * costoActual) + (nuevaCantidad * nuevoCosto)) / totalStock;
        await db.update('productos', {'costo': nuevoCostoPromedio}, where: 'id = ?', whereArgs: [productId]);
      }
    }
  }

  // RF 40: Obtener cantidad de productos con stock bajo
  Future<int> getLowStockCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM productos WHERE stockActual <= stockMinimo',
    );
    return result.first['count'] as int? ?? 0;
  }

  // RF 40: Obtener total de productos
  Future<int> getTotalProducts() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM productos WHERE activo = 1');
    return result.first['count'] as int? ?? 0;
  }

  // RF 23: Consultar stock valorado
  Future<Map<String, dynamic>> getStockValorado() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(stockActual * costo) as valorTotal, SUM(stockActual * precioVenta) as valorVenta FROM productos WHERE activo = 1',
    );
    return {
      'valorCosto': (result.first['valorTotal'] as num?)?.toDouble() ?? 0.0,
      'valorVenta': (result.first['valorVenta'] as num?)?.toDouble() ?? 0.0,
      'gananciaPotencial': ((result.first['valorVenta'] as num?)?.toDouble() ?? 0.0) - ((result.first['valorTotal'] as num?)?.toDouble() ?? 0.0),
    };
  }

  // RF 62: Reporte de rotación de productos
  Future<List<Map<String, dynamic>>> getRotacionProductos({int dias = 30}) async {
    final db = await _db;
    final fechaLimite = DateTime.now().subtract(Duration(days: dias));
    return await db.rawQuery(
      '''SELECT p.id, p.nombre, p.codigo,
      SUM(CASE WHEN vd.cantidad > 0 THEN vd.cantidad ELSE 0 END) as vendidas,
      p.stockActual
      FROM productos p
      LEFT JOIN venta_detalles vd ON p.id = vd.producto_id
      LEFT JOIN ventas v ON vd.venta_id = v.id AND v.fecha >= ?
      WHERE p.activo = 1
      GROUP BY p.id, p.nombre, p.codigo, p.stockActual
      ORDER BY vendidas DESC''',
      [fechaLimite.toIso8601String()],
    );
  }

  // RF 63: Reporte de margen por producto
  Future<List<Map<String, dynamic>>> getMargenPorProducto() async {
    final db = await _db;
    return await db.rawQuery(
      '''SELECT id, nombre, codigo, costo, precioVenta,
      ((precioVenta - COALESCE(costo, 0)) / NULLIF(precioVenta, 0)) * 100 as margenPorcentaje,
      (precioVenta - COALESCE(costo, 0)) as margenAbsoluto,
      stockActual
      FROM productos WHERE activo = 1
      ORDER BY margenPorcentaje DESC''',
    );
  }

  // RF 71, 73, 74
  Future<void> cambiarUnidadMedida(int productId, String nuevaUnidad) async {
    final db = await _db;
    await db.update('productos', {'unidadMedida': nuevaUnidad}, where: 'id = ?', whereArgs: [productId]);
  }

  Future<int> duplicarProducto(int productId) async {
    final p = await getProductById(productId);
    if (p != null) {
      return await createProduct(Product(id: null, nombre: '${p.nombre} (Copia)', codigo: '${p.codigo}-COPY', costo: p.costo ?? 0.0, precioVenta: p.precioVenta, stockActual: 0, stockMinimo: p.stockMinimo, unidadMedida: p.unidadMedida ?? 'und', activo: true));
    }
    return -1;
  }

  Future<void> archivarProducto(int productId, bool activo) async {
    final db = await _db;
    await db.update('productos', {'activo': activo ? 1 : 0}, where: 'id = ?', whereArgs: [productId]);
  }

  // RF 36
  Future<int> actualizarPreciosMasivo(List<int> ids, double porc, bool aumento) async {
    final db = await _db;
    int count = 0;
    for (var id in ids) {
      final p = await getProductById(id);
      if (p != null) {
        final nuevo = aumento ? p.precioVenta * (1 + porc / 100) : p.precioVenta * (1 - porc / 100);
        await db.update('productos', {'precioVenta': nuevo}, where: 'id = ?', whereArgs: [id]);
        count++;
      }
    }
    return count;
  }

  // [NUEVO] Método requerido por SaleRepository para actualizar stock tras una venta
  Future<void> updateProductStock(int productId, int cantidad) async {
    final db = await _db;
    final product = await getProductById(productId);
    if (product == null) throw Exception('Producto no encontrado');
    
    final nuevoStock = product.stockActual - cantidad;
    if (nuevoStock < 0) throw Exception('Stock insuficiente para producto ID $productId');
    
    await db.update(
      'productos',
      {'stockActual': nuevoStock, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}
