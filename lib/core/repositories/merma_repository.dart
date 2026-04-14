import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class MermaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // RF 24-25: Registrar ajuste de inventario
  Future<int> registerInventoryAdjustment({
    required int productId,
    required int quantity,
    required bool isPositive,
    required String reason,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // Registrar merma
      final mermaId = await txn.insert('mermas', {
        'producto_id': productId,
        'cantidad': quantity,
        'tipo': isPositive ? 'ajuste_positivo' : 'ajuste_negativo',
        'motivo': reason,
        'notas': notes,
        'fecha': DateTime.now().toIso8601String(),
      });

      // Actualizar stock
      await txn.rawUpdate(
        'UPDATE productos SET stock_actual = stock_actual ${isPositive ? '+' : '-'} ? WHERE id = ?',
        [quantity, productId],
      );

      return mermaId;
    });
  }

  // RF 26: Registrar merma masiva
  Future<int> registerBulkMerma({
    required List<Map<String, dynamic>> items,
    required String motivo,
    String? notas,
  }) async {
    final db = await _dbHelper.database;
    int count = 0;

    await db.transaction((txn) async {
      for (var item in items) {
        await txn.insert('mermas', {
          'producto_id': item['producto_id'],
          'cantidad': item['cantidad'],
          'tipo': 'merma',
          'motivo': motivo,
          'notas': notas,
          'fecha': DateTime.now().toIso8601String(),
        });

        await txn.rawUpdate(
          'UPDATE productos SET stock_actual = stock_actual - ? WHERE id = ?',
          [item['cantidad'] as int, item['producto_id'] as int],
        );
        count++;
      }
    });

    return count;
  }

  // RF 60: Registrar merma por vencimiento
  Future<int> registerExpirationMerma({
    required int productId,
    required int quantity,
    required DateTime fechaVencimiento,
    String? notas,
  }) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      final mermaId = await txn.insert('mermas', {
        'producto_id': productId,
        'cantidad': quantity,
        'tipo': 'vencimiento',
        'motivo': 'Producto vencido',
        'notas': notas ?? 'Vencimiento: ${fechaVencimiento.toString().split(' ').first}',
        'fecha': DateTime.now().toIso8601String(),
        'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      });

      await txn.rawUpdate(
        'UPDATE productos SET stock_actual = stock_actual - ? WHERE id = ?',
        [quantity, productId],
      );

      return mermaId;
    });
  }

  // RF 61: Obtener motivos de merma personalizados
  Future<List<String>> getMermaReasons() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT motivo FROM mermas 
      WHERE motivo IS NOT NULL AND motivo != ''
      ORDER BY motivo
    ''');
    return result.map((row) => row['motivo'] as String).toList();
  }

  // RF 61: Agregar motivo personalizado
  Future<void> addCustomReason(String reason) async {
    final db = await _dbHelper.database;
    await db.insert('config', {
      'key': 'merma_motivo_$reason',
      'value': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // RF 28: Listar mermas con filtros
  Future<List<Map<String, dynamic>>> listMermas({
    DateTime? startDate,
    DateTime? endDate,
    String? tipo,
    int? productId,
  }) async {
    final db = await _dbHelper.database;
    
    List<String> whereClauses = [];
    List<dynamic> args = [];

    if (startDate != null) {
      whereClauses.add('fecha >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('fecha <= ?');
      args.add(endDate.toIso8601String());
    }
    if (tipo != null) {
      whereClauses.add('tipo = ?');
      args.add(tipo);
    }
    if (productId != null) {
      whereClauses.add('producto_id = ?');
      args.add(productId);
    }

    final where = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    return await db.rawQuery('''
      SELECT m.*, p.nombre as producto_nombre, p.codigo as producto_codigo
      FROM mermas m
      LEFT JOIN productos p ON m.producto_id = p.id
      $where
      ORDER BY m.fecha DESC
    ''', args);
  }

  // RF 28: Resumen de mermas
  Future<Map<String, dynamic>> getMermaSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    List<String> whereClauses = [];
    List<dynamic> args = [];

    if (startDate != null) {
      whereClauses.add('fecha >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('fecha <= ?');
      args.add(endDate.toIso8601String());
    }

    final where = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_mermas,
        SUM(cantidad) as total_cantidad,
        tipo,
        motivo
      FROM mermas
      $where
      GROUP BY tipo, motivo
    ''', args);

    return {
      'byType': result,
      'total': result.fold<int>(0, (sum, r) => sum + (r['total_mermas'] as int? ?? 0)),
    };
  }

  // RF 60: Productos próximos a vencer
  Future<List<Map<String, dynamic>>> getProductsExpiringSoon({int days = 30}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().add(Duration(days: days));
    
    return await db.rawQuery('''
      SELECT * FROM productos 
      WHERE fecha_vencimiento IS NOT NULL 
        AND fecha_vencimiento <= ?
        AND stock_actual > 0
      ORDER BY fecha_vencimiento ASC
    ''', [cutoffDate.toIso8601String()]);
  }
}
