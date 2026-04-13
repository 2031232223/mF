import '../database/database_helper.dart';
import '../models/supplier.dart';

class SupplierRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createSupplier(Supplier supplier) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'proveedores',
      {
        'nombre': supplier.nombre,
        'ci_identidad': supplier.ciIdentidad,
        'telefono': supplier.telefono,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> updateSupplier(int id, Supplier supplier) async {
    final db = await _dbHelper.database;
    return await db.update(
      'proveedores',
      {
        'nombre': supplier.nombre,
        'ci_identidad': supplier.ciIdentidad,
        'telefono': supplier.telefono,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('proveedores', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await _dbHelper.database;
    final results = await db.query('proveedores', orderBy: 'nombre ASC');
    return results.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<Supplier?> getSupplierById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('proveedores', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Supplier.fromMap(results.first);
  }

  Future<List<Supplier>> searchSuppliers(String query) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'proveedores',
      where: 'nombre LIKE ? OR ci_identidad LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return results.map((m) => Supplier.fromMap(m)).toList();
  }
}
