import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ReminderHelper {
  static final ReminderHelper instance = ReminderHelper._init();
  ReminderHelper._init();

  // RF 68: Programar recordatorio de stock
  Future<int> scheduleStockReminder({
    required int productId,
    required String productName,
    required int threshold,
    required bool enabled,
  }) async {
    final db = await DatabaseHelper.instance.database;
    
    return await db.insert('config', {
      'key': 'reminder_stock_$productId',
      'value': {
        'productId': productId,
        'productName': productName,
        'threshold': threshold,
        'enabled': enabled,
        'created_at': DateTime.now().toIso8601String(),
      }.toString(),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // RF 68: Obtener recordatorios activos
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('config', where: 'key LIKE ?', whereArgs: ['reminder_stock_%']);
    
    return result.where((r) {
      final value = r['value'] as String?;
      if (value == null) return false;
      return value.contains('enabled: true');
    }).toList();
  }

  // RF 68: Verificar stock bajo y mostrar alertas
  Future<List<Map<String, dynamic>>> checkLowStock({required int threshold}) async {
    final db = await DatabaseHelper.instance.database;
    
    final result = await db.rawQuery('''
      SELECT id, nombre, stock_actual, stock_minimo
      FROM productos
      WHERE stock_actual <= ? 
      ORDER BY stock_actual ASC
    ''', [threshold]);

    return result;
  }

  // RF 68: Mostrar notificación de stock bajo
  Future<void> showLowStockNotification(List<Map<String, dynamic>> products) async {
    // Nota: Para notificaciones push reales se necesita flutter_local_notifications
    // Esta es una implementación básica que guarda la alerta en la BD
    final db = await DatabaseHelper.instance.database;
    
    await db.insert('config', {
      'key': 'last_low_stock_alert',
      'value': products.toString(),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // RF 68: Eliminar recordatorio
  Future<void> deleteReminder(int productId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('config', where: 'key = ?', whereArgs: ['reminder_stock_$productId']);
  }

  // RF 68: Activar/desactivar recordatorio
  Future<void> toggleReminder(int productId, bool enabled) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('config', where: 'key = ?', whereArgs: ['reminder_stock_$productId']);
    
    if (result.isNotEmpty) {
      await db.update(
        'config',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'key = ?',
        whereArgs: ['reminder_stock_$productId'],
      );
    }
  }

  // RF 41: Verificar alertas de stock configuradas
  Future<int> getStockAlertThreshold() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('config', where: 'key = ?', whereArgs: ['alerta_stock']);
    
    if (result.isNotEmpty) {
      return (result.first['value'] as String?)?.parseInt() ?? 5;
    }
    return 5; // Default
  }
}

extension on String {
  int parseInt() {
    return int.tryParse(this) ?? 0;
  }
}
