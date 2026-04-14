class Sale {
  final int id;
  final int? clienteId;
  final double total;
  final double totalCup;
  final double descuento;
  final double subtotal;
  final DateTime fecha;
  final String? metodoPago;
  final String moneda;
  final double tasaCambio;
  final bool esFiado;
  final double montoPagado;
  final double montoPendiente;
  final String? notasCredito;
  final DateTime? createdAt;

  Sale({
    required this.id,
    this.clienteId,
    required this.total,
    this.totalCup = 0.0,
    this.descuento = 0.0,
    this.subtotal = 0.0,
    required this.fecha,
    this.metodoPago,
    this.moneda = 'CUP',
    this.tasaCambio = 1.0,
    this.esFiado = false,
    this.montoPagado = 0.0,
    this.montoPendiente = 0.0,
    this.notasCredito,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'total': total,
      'total_cup': totalCup,
      'descuento': descuento,
      'subtotal': subtotal,
      'fecha': fecha.toIso8601String(),
      'metodo_pago': metodoPago,
      'moneda': moneda,
      'tasa_cambio': tasaCambio,
      'es_fiado': esFiado ? 1 : 0,
      'monto_pagado': montoPagado,
      'monto_pendiente': montoPendiente,
      'notas_credito': notasCredito,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int,
      clienteId: map['cliente_id'] as int?,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      totalCup: (map['total_cup'] as num?)?.toDouble() ?? 0.0,
      descuento: (map['descuento'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      fecha: DateTime.tryParse(map['fecha'] as String) ?? DateTime.now(),
      metodoPago: map['metodo_pago'] as String?,
      moneda: map['moneda'] as String? ?? 'CUP',
      tasaCambio: (map['tasa_cambio'] as num?)?.toDouble() ?? 1.0,
      esFiado: (map['es_fiado'] as int?) == 1,
      montoPagado: (map['monto_pagado'] as num?)?.toDouble() ?? 0.0,
      montoPendiente: (map['monto_pendiente'] as num?)?.toDouble() ?? 0.0,
      notasCredito: map['notas_credito'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) 
          : null,
    );
  }
}

class SaleLine {
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  SaleLine({
    required this.productoId,
    this.productoNombre = '',
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }

  factory SaleLine.fromMap(Map<String, dynamic> map) {
    return SaleLine(
      productoId: map['producto_id'] as int,
      productoNombre: map['producto_nombre'] as String? ?? map['nombre'] as String? ?? 'Producto',
      cantidad: map['cantidad'] as int,
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
