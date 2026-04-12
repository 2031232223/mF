class Supplier {
  final int? id;
  final String nombre;
  final String ciIdentidad;
  final String telefono;

  Supplier({
    this.id,
    required this.nombre,
    required this.ciIdentidad,
    required this.telefono,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'ci_identidad': ciIdentidad,
      'telefono': telefono,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      ciIdentidad: map['ci_identidad'] as String,
      telefono: map['telefono'] as String,
    );
  }
}
