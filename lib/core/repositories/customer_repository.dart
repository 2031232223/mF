import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerRepository {
  Future<int> createCustomer(String nombre, String? carnetIdentidad, String? telefono) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('clientes', {
      'nombre': nombre,
      'carnet_identidad': carnetIdentidad,
      'telefono': telefono,
      'es_habitual': 0,
      'fecha_registro': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('clientes', orderBy: 'nombre ASC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('clientes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('clientes', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'nombre LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }
}
