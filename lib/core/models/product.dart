class Product {
  final int id;
  final String nombre;
  final String? codigo;
  final String? categoria;
  final double costo;
  final double precioVenta;
  final int stockActual;
  final int stockMinimo;
  final String? unidadMedida;
  final bool esFavorito;
  // estaActivo removido
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  Product({
    required this.id,
    required this.nombre,
    this.codigo,
    this.categoria,
    required this.costo,
    required this.precioVenta,
    required this.stockActual,
    this.stockMinimo = 5,
    this.unidadMedida = 'unidad',
    this.esFavorito = false,
    // removido
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'categoria': categoria,
      'costo': costo,
      'precio_venta': precioVenta,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'unidad_medida': unidadMedida,
      'es_favorito': esFavorito ? 1 : 0,
      // removido
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      codigo: map['codigo'] as String?,
      categoria: map['categoria'] as String?,
      costo: (map['costo'] as num?)?.toDouble() ?? 0.0,
      precioVenta: (map['precio_venta'] as num?)?.toDouble() ?? 0.0,
      stockActual: (map['stock_actual'] as int?) ?? 0,
      stockMinimo: (map['stock_minimo'] as int?) ?? 5,
      unidadMedida: map['unidad_medida'] as String? ?? 'unidad',
      esFavorito: (map['es_favorito'] as int?) == 1,
      // removido
      fechaRegistro: map['fecha_registro'] != null 
          ? DateTime.tryParse(map['fecha_registro'] as String) 
          : null,
      fechaActualizacion: map['fecha_actualizacion'] != null 
          ? DateTime.tryParse(map['fecha_actualizacion'] as String) 
          : null,
    );
  }

  Product copyWith({
    int? id,
    String? nombre,
    String? codigo,
    String? categoria,
    double? costo,
    double? precioVenta,
    int? stockActual,
    int? stockMinimo,
    String? unidadMedida,
    bool? esFavorito,
    bool? estaActivo,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      categoria: categoria ?? this.categoria,
      costo: costo ?? this.costo,
      precioVenta: precioVenta ?? this.precioVenta,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      esFavorito: esFavorito ?? this.esFavorito,
      estaActivo: estaActivo ?? this.estaActivo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
    );
  }
}
