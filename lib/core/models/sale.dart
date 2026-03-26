class Sale {
  final int? id;
  final int? clienteId;
  final String fecha;
  final double total;
  final double montoPagado;
  final double montoPendiente;
  final String? notasCredito;
  final bool esFiado;

  Sale({
    this.id,
    this.clienteId,
    required this.fecha,
    required this.total,
    this.montoPagado = 0.0,
    this.montoPendiente = 0.0,
    this.notasCredito,
    this.esFiado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'fecha': fecha,
      'total': total,
      'monto_pagado': montoPagado,
      'monto_pendiente': montoPendiente,
      'notas_credito': notasCredito,
      'es_fiado': esFiado ? 1 : 0,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int?,
      fecha: map['fecha'] as String,
      total: (map['total'] as num).toDouble(),
      montoPagado: (map['monto_pagado'] as num?)?.toDouble() ?? 0.0,
      montoPendiente: (map['monto_pendiente'] as num?)?.toDouble() ?? 0.0,
      notasCredito: map['notas_credito'] as String?,
      esFiado: (map['es_fiado'] as int?) == 1,
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
