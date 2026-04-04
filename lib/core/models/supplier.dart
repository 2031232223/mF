class Supplier {
  final int? id;
  final String nombre;
  final String? contacto;
  final String? telefono;

  Supplier({
    this.id,
    required this.nombre,
    this.contacto,
    this.telefono,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'contacto': contacto,
      'telefono': telefono,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      contacto: map['contacto'] as String?,
      telefono: map['telefono'] as String?,
    );
  }
}
