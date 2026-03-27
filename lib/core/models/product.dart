class Product {
  final int? id;
  final String nombre;
  final String codigo;
  final double? costo;
  final double precioVenta;
  final int stockActual;
  final int stockMinimo;
  // RF 42: Categoría
  final String? categoria;
  // RF 44: Favorito
  final bool esFavorito;
  // RF 41: Alerta crítica (stock mínimo personalizado)
  final int? stockCritico;

  Product({
    this.id,
    required this.nombre,
    required this.codigo,
    this.costo,
    required this.precioVenta,
    required this.stockActual,
    required this.stockMinimo,
    this.categoria,
    this.esFavorito = false,
    this.stockCritico,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'costo': costo,
      'precio_venta': precioVenta,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'categoria': categoria,
      'es_favorito': esFavorito ? 1 : 0,
      'stock_critico': stockCritico,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      codigo: map['codigo'] as String,
      costo: (map['costo'] as num?)?.toDouble(),
      precioVenta: (map['precio_venta'] as num).toDouble(),
      stockActual: map['stock_actual'] as int,
      stockMinimo: map['stock_minimo'] as int,
      categoria: map['categoria'] as String?,
      esFavorito: (map['es_favorito'] as int?) == 1,
      stockCritico: map['stock_critico'] as int?,
    );
  }

  // RF 41: ¿Stock crítico?
  bool get esStockCritico => stockCritico != null ? stockActual <= stockCritico! : stockActual <= stockMinimo;
}
