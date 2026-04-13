import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'clientes',
      {
        'nombre': customer.nombre,
        'carnet_identidad': customer.carnetIdentidad,
        'telefono': customer.telefono,
        'es_habitual': customer.esHabitual ? 1 : 0,
        'fecha_registro': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> updateCustomer(int id, Customer customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'clientes',
      {
        'nombre': customer.nombre,
        'carnet_identidad': customer.carnetIdentidad,
        'telefono': customer.telefono,
        'es_habitual': customer.esHabitual ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;
    final results = await db.query('clientes', orderBy: 'nombre ASC');
    return results.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('clientes', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Customer.fromMap(results.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'clientes',
      where: 'nombre LIKE ? OR carnet_identidad LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return results.map((m) => Customer.fromMap(m)).toList();
  }
}
