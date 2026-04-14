import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('productos', product.toMap());
  }

  Future<List<Product>> getAllProducts({bool onlyActive = true}) async {
    final db = await _dbHelper.database;
    String where = onlyActive ? 'esta_activo = 1' : '';
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: where.isEmpty ? null : where,
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      'productos',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  // RF 74: Archivar producto (soft delete)
  Future<void> archiveProduct(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'productos',
      {'esta_activo': 0, 'fecha_actualizacion': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // RF 74: Reactivar producto archivado
  Future<void> unarchiveProduct(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'productos',
      {'esta_activo': 1, 'fecha_actualizacion': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // RF 44: Marcar producto como favorito
  Future<void> toggleFavorite(int id) async {
    final db = await _dbHelper.database;
    final product = await getProductById(id);
    if (product != null) {
      await db.update(
        'productos',
        {'es_favorito': product.esFavorito ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // RF 44: Obtener productos favoritos
  Future<List<Product>> getFavoriteProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'es_favorito = 1 AND esta_activo = 1',
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  // RF 73: Duplicar producto
  Future<int> duplicateProduct(int id) async {
    final product = await getProductById(id);
    if (product == null) throw Exception('Producto no encontrado');
    
    final newProduct = product.copyWith(
      id: 0,
      nombre: '${product.nombre} (Copia)',
      codigo: '${product.codigo}_COPY',
      fechaRegistro: null,
      fechaActualizacion: DateTime.now(),
    );
    
    return await createProduct(newProduct);
  }

  // RF 36: Cambio masivo de precios por porcentaje
  Future<int> bulkPriceUpdate({
    required double percentage,
    List<int>? productIds,
    String? categoria,
  }) async {
    final db = await _dbHelper.database;
    
    String where = '';
    List<dynamic> args = [];
    
    if (productIds != null && productIds.isNotEmpty) {
      where = 'id IN (${List.filled(productIds.length, '?').join(',')})';
      args.addAll(productIds);
    } else if (categoria != null) {
      where = 'categoria = ?';
      args.add(categoria);
    }
    
    if (where.isNotEmpty) {
      where = 'WHERE $where';
    }
    
    final result = await db.rawQuery('''
      UPDATE productos 
      SET precio_venta = precio_venta * ?,
          fecha_actualizacion = ?
      $where
    ''', [(1 + percentage / 100), DateTime.now().toIso8601String(), ...args]);
    
    return result.changes;
  }

  // RF 36: Cambio masivo de precios por valor fijo
  Future<int> bulkPriceUpdateByValue({
    required double value,
    bool isAddition = true,
    List<int>? productIds,
  }) async {
    final db = await _dbHelper.database;
    
    String where = '';
    List<dynamic> args = [];
    
    if (productIds != null && productIds.isNotEmpty) {
      where = 'WHERE id IN (${List.filled(productIds.length, '?').join(',')})';
      args.addAll(productIds);
    }
    
    final operator = isAddition ? '+' : '-';
    final result = await db.rawQuery('''
      UPDATE productos 
      SET precio_venta = precio_venta $operator ?,
          fecha_actualizacion = ?
      $where
    ''', [value, DateTime.now().toIso8601String(), ...args]);
    
    return result.changes;
  }

  // RF 42: Obtener categorías únicas
  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT categoria 
      FROM productos 
      WHERE categoria IS NOT NULL AND categoria != ''
      ORDER BY categoria
    ''');
    return result.map((row) => row['categoria'] as String).toList();
  }

  // RF 71: Obtener unidades de medida únicas
  Future<List<String>> getUnidadesMedida() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT unidad_medida 
      FROM productos 
      WHERE unidad_medida IS NOT NULL AND unidad_medida != ''
      ORDER BY unidad_medida
    ''');
    return result.map((row) => row['unidad_medida'] as String).toList();
  }

  // RF 42: Productos por categoría
  Future<List<Product>> getProductsByCategory(String categoria) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'categoria = ? AND esta_activo = 1',
      whereArgs: [categoria],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  // RF 5: Productos con stock bajo
  Future<List<Product>> getLowStockProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'stock_actual <= stock_minimo AND esta_activo = 1',
      orderBy: 'stock_actual ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  // RF 23: Stock valorado total
  Future<double> getTotalValuedStock() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(stock_actual * costo) as total 
      FROM productos 
      WHERE esta_activo = 1
    ''');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // RF 50: Calcular costo promedio ponderado
  Future<double> calculateWeightedAverageCost(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(cantidad * costo_unitario) as totalCosto,
        SUM(cantidad) as totalCantidad
      FROM compra_detalles
      WHERE producto_id = ?
    ''', [productId]);
    
    if (result.isNotEmpty && result.first['totalCantidad'] != null) {
      final totalCosto = (result.first['totalCosto'] as num).toDouble();
      final totalCantidad = (result.first['totalCantidad'] as num).toDouble();
      if (totalCantidad > 0) {
        return totalCosto / totalCantidad;
      }
    }
    return 0.0;
  }

  // Búsqueda de productos
  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: '(nombre LIKE ? OR codigo LIKE ?) AND esta_activo = 1',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  // Actualizar stock
  Future<void> updateStock(int id, int quantity, {bool isAddition = true}) async {
    final db = await _dbHelper.database;
    final product = await getProductById(id);
    if (product != null) {
      final newStock = isAddition 
          ? product.stockActual + quantity 
          : product.stockActual - quantity;
      await db.update(
        'productos',
        {
          'stock_actual': newStock,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
