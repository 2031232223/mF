class Sale {
  final int? id;
  final int? clienteId;
  final String fecha;
  final double total;

  Sale({this.id, this.clienteId, required this.fecha, required this.total});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'fecha': fecha,
      'total': total,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int?,
      fecha: map['fecha'] as String,
      total: (map['total'] as num).toDouble(),
    );
  }
}

class SaleLine {
  final int? id;
  final int ventaId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  SaleLine({
    this.id,
    required this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }

  factory SaleLine.fromMap(Map<String, dynamic> map) {
    return SaleLine(
      id: map['id'] as int?,
      ventaId: map['venta_id'] as int,
      productoId: map['producto_id'] as int,
      cantidad: map['cantidad'] as int,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}
