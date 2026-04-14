import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class CsvRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // RF 47: Exportar productos a CSV
  Future<String> exportProductsToCsv() async {
    try {
      final db = await _dbHelper.database;
      final products = await db.query('productos');
      
      final buffer = StringBuffer();
      // Encabezados
      buffer.writeln('id,nombre,codigo,categoria,costo,precio_venta,stock_actual,stock_minimo,unidad_medida,es_favorito,esta_activo');
      
      // Datos
      for (var p in products) {
        buffer.writeln(
          '${p['id']},'
          '"${p['nombre']}",'
          '"${p['codigo'] ?? ''}",'
          '"${p['categoria'] ?? ''}",'
          '${p['costo']},'
          '${p['precio_venta']},'
          '${p['stock_actual']},'
          '${p['stock_minimo']},'
          '"${p['unidad_medida'] ?? 'unidad'}",'
          '${p['es_favorito']},'
          '${p['esta_activo']}'
        );
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final csvDir = Directory('${dir.path}/NovaADEN/Exports');
      if (!await csvDir.exists()) {
        await csvDir.create(recursive: true);
      }
      
      final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: .]'), '-');
      final filePath = '${csvDir.path}/productos_$dateStr.csv';
      
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      return filePath;
    } catch (e) {
      throw Exception('Error exportando productos: $e');
    }
  }

  // RF 47: Exportar ventas a CSV
  Future<String> exportSalesToCsv() async {
    try {
      final db = await _dbHelper.database;
      final sales = await db.query('ventas', orderBy: 'fecha DESC');
      
      final buffer = StringBuffer();
      buffer.writeln('id,cliente_id,total,total_cup,descuento,fecha,moneda,tasa_cambio,es_fiado,monto_pagado,monto_pendiente');
      
      for (var s in sales) {
        buffer.writeln(
          '${s['id']},'
          '${s['cliente_id'] ?? ''},'
          '${s['total']},'
          '${s['total_cup']},'
          '${s['descuento']},'
          '${s['fecha']},'
          '${s['moneda']},'
          '${s['tasa_cambio']},'
          '${s['es_fiado']},'
          '${s['monto_pagado']},'
          '${s['monto_pendiente']}'
        );
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final csvDir = Directory('${dir.path}/NovaADEN/Exports');
      if (!await csvDir.exists()) {
        await csvDir.create(recursive: true);
      }
      
      final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: .]'), '-');
      final filePath = '${csvDir.path}/ventas_$dateStr.csv';
      
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      return filePath;
    } catch (e) {
      throw Exception('Error exportando ventas: $e');
    }
  }

  // RF 47: Exportar clientes a CSV
  Future<String> exportCustomersToCsv() async {
    try {
      final db = await _dbHelper.database;
      final customers = await db.query('clientes');
      
      final buffer = StringBuffer();
      buffer.writeln('id,nombre,carnet_identidad,telefono,es_habitual,fecha_registro');
      
      for (var c in customers) {
        buffer.writeln(
          '${c['id']},'
          '"${c['nombre']}",'
          '"${c['carnet_identidad'] ?? ''}",'
          '"${c['telefono'] ?? ''}",'
          '${c['es_habitual']},'
          '${c['fecha_registro'] ?? ''}'
        );
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final csvDir = Directory('${dir.path}/NovaADEN/Exports');
      if (!await csvDir.exists()) {
        await csvDir.create(recursive: true);
      }
      
      final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: .]'), '-');
      final filePath = '${csvDir.path}/clientes_$dateStr.csv';
      
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      return filePath;
    } catch (e) {
      throw Exception('Error exportando clientes: $e');
    }
  }

  // RF 46: Importar productos desde CSV
  Future<int> importProductsFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Archivo no encontrado');
      }

      final lines = await file.readAsLines();
      if (lines.isEmpty) {
        throw Exception('Archivo vacío');
      }

      final db = await _dbHelper.database;
      int importedCount = 0;

      // Saltar encabezado
      for (var i = 1; i < lines.length; i++) {
        try {
          final values = _parseCsvLine(lines[i]);
          if (values.length >= 6) {
            await db.insert('productos', {
              'nombre': values[1],
              'codigo': values[2],
              'categoria': values[3],
              'costo': double.tryParse(values[4]) ?? 0.0,
              'precio_venta': double.tryParse(values[5]) ?? 0.0,
              'stock_actual': int.tryParse(values[6]) ?? 0,
              'stock_minimo': int.tryParse(values[7]) ?? 5,
              'unidad_medida': values[8],
              'es_favorito': int.tryParse(values[9]) ?? 0,
              'esta_activo': int.tryParse(values[10]) ?? 1,
              'fecha_registro': DateTime.now().toIso8601String(),
            });
            importedCount++;
          }
        } catch (e) {
          print('Error importando línea $i: $e');
        }
      }

      return importedCount;
    } catch (e) {
      throw Exception('Error importando productos: $e');
    }
  }

  // Analizar línea CSV
  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    values.add(current.toString());

    return values;
  }

  // RF 34: Exportar cualquier listado genérico a CSV
  Future<String> exportGenericToCsv({
    required String tableName,
    required List<String> columns,
    required String fileName,
  }) async {
    try {
      final db = await _dbHelper.database;
      final data = await db.query(tableName);
      
      final buffer = StringBuffer();
      // Encabezados
      buffer.writeln(columns.join(','));
      
      // Datos
      for (var row in data) {
        final values = columns.map((c) {
          final value = row[c]?.toString() ?? '';
          return value.contains(',') ? '"$value"' : value;
        }).join(',');
        buffer.writeln(values);
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final csvDir = Directory('${dir.path}/NovaADEN/Exports');
      if (!await csvDir.exists()) {
        await csvDir.create(recursive: true);
      }
      
      final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: .]'), '-');
      final filePath = '${csvDir.path}/${fileName}_$dateStr.csv';
      
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      return filePath;
    } catch (e) {
      throw Exception('Error exportando $tableName: $e');
    }
  }
}
