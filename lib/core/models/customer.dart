class Customer {
  final int? id;
  final String nombre;
  final String carnetIdentidad;
  final String telefono;
  // RF 43: Cliente habitual
  final bool esHabitual;
  final DateTime? fechaRegistro;

  Customer({
    this.id,
    required this.nombre,
    required this.carnetIdentidad,
    required this.telefono,
    this.esHabitual = false,
    this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'carnet_identidad': carnetIdentidad,
      'telefono': telefono,
      'es_habitual': esHabitual ? 1 : 0,
      'fecha_registro': fechaRegistro?.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      carnetIdentidad: map['carnet_identidad'] as String,
      telefono: map['telefono'] as String,
      esHabitual: (map['es_habitual'] as int?) == 1,
      fechaRegistro: map['fecha_registro'] != null ? DateTime.parse(map['fecha_registro']) : null,
    );
  }
}
