import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class CsvExporter {
  // Exportar cualquier lista a CSV
  static Future<String> exportToCsv<T>(
    List<T> items,
    String fileName,
    List<String> headers,
    List<dynamic> Function(T) rowMapper,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    final csvData = [headers, ...items.map(rowMapper)];
    final csvString = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csvString);
    return path;
  }

  // RF 47: Exportar catálogo de productos
  static Future<String> exportProductCatalog(List<Map<String, dynamic>> products) async {
    return exportToCsv(
      products,
      'catalogo_productos_${DateTime.now().millisecondsSinceEpoch}.csv',
      ['ID', 'Nombre', 'Codigo', 'Categoria', 'Costo', 'PrecioVenta', 'Stock', 'StockMinimo', 'Favorito'],
      (p) => [
        p['id'] ?? '', p['nombre'] ?? '', p['codigo'] ?? '', p['categoria'] ?? '',
        p['costo'] ?? 0, p['precio_venta'] ?? 0, p['stock_actual'] ?? 0,
        p['stock_minimo'] ?? 0, (p['es_favorito'] == 1) ? 'Si' : 'No',
      ],
    );
  }

  // RF 46: Importar productos desde CSV (parser)
  static List<Map<String, dynamic>> parseProductCsv(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.length < 2) return [];
    
    final headers = rows[0].map((h) => h.toString().toLowerCase().trim()).toList();
    final products = <Map<String, dynamic>>[];
    
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < headers.length) continue;
      
      final map = <String, dynamic>{};
      for (var j = 0; j < headers.length; j++) {
        map[headers[j]] = row[j];
      }
      products.add(map);
    }
    return products;
  }

  // Alias para exportProducts (compatibilidad)
  static Future<String> exportProducts(List<Map<String, dynamic>> products) async {
    return exportProductCatalog(products);
  }
}
