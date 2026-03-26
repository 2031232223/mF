enum WasteReason { damage, expiration, theft, error, other }

class WasteRecord {
  final int? id;
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double costoUnitario;
  final WasteReason reason;
  final String fecha;
  final String? notas;

  WasteRecord({
    this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.costoUnitario,
    required this.reason,
    required this.fecha,
    this.notas,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'producto_id': productoId,
    'producto_nombre': productoNombre,
    'cantidad': cantidad,
    'costo_unitario': costoUnitario,
    'motivo': reason.toString().split('.').last,
    'fecha': fecha,
    'notas': notas,
  };

  factory WasteRecord.fromMap(Map<String, dynamic> m) => WasteRecord(
    id: m['id'] as int?,
    productoId: m['producto_id'] as int,
    productoNombre: m['producto_nombre'] as String,
    cantidad: m['cantidad'] as int,
    costoUnitario: (m['costo_unitario'] as num).toDouble(),
    reason: WasteReason.values.firstWhere(
      (r) => r.toString().endsWith(m['motivo'] as String),
      orElse: () => WasteReason.other,
    ),
    fecha: m['fecha'] as String,
    notas: m['notas'] as String?,
  );

  double get totalLoss => costoUnitario * cantidad;
}
