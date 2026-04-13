import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ConfigRepository {
  Future<void> guardarNotaDiaria(String nota) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'config',
        {
          'key': 'nota_diaria_actual',
          'value': nota,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error guardando nota diaria: $e');
    }
  }

  Future<String?> obtenerNotaDiaria() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'config',
        where: 'key = ?',
        whereArgs: ['nota_diaria_actual'],
      );
      return result.isNotEmpty ? result.first['value'] as String? : null;
    } catch (e) {
      print('Error leyendo nota diaria: $e');
      return null;
    }
  }

  Future<void> limpiarNotaDiaria() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'config',
        where: 'key = ?',
        whereArgs: ['nota_diaria_actual'],
      );
    } catch (e) {
      print('Error limpiando nota diaria: $e');
    }
  }
}
