class ProductRotation {
  final int productId;
  final String productName;
  final int totalVendido;
  final double ingresosTotales;
  final DateTime ultimaVenta;

  ProductRotation({
    required this.productId,
    required this.productName,
    required this.totalVendido,
    required this.ingresosTotales,
    required this.ultimaVenta,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'totalVendido': totalVendido,
      'ingresosTotales': ingresosTotales,
      'ultimaVenta': ultimaVenta.toIso8601String(),
    };
  }

  factory ProductRotation.fromMap(Map<String, dynamic> map) {
    return ProductRotation(
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      totalVendido: map['totalVendido'] as int,
      ingresosTotales: (map['ingresosTotales'] as num?)?.toDouble() ?? 0.0,
      ultimaVenta: DateTime.tryParse(map['ultimaVenta'] as String) ?? DateTime.now(),
    );
  }
}

class ProductMargin {
  final int productId;
  final String productName;
  final double costo;
  final double precioVenta;
  final double margen;
  final double porcentajeMargen;

  ProductMargin({
    required this.productId,
    required this.productName,
    required this.costo,
    required this.precioVenta,
    required this.margen,
    required this.porcentajeMargen,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'costo': costo,
      'precioVenta': precioVenta,
      'margen': margen,
      'porcentajeMargen': porcentajeMargen,
    };
  }

  factory ProductMargin.fromMap(Map<String, dynamic> map) {
    final costo = (map['costo'] as num?)?.toDouble() ?? 0.0;
    final precioVenta = (map['precioVenta'] as num?)?.toDouble() ?? 0.0;
    final margen = precioVenta - costo;
    final porcentajeMargen = costo > 0 ? (margen / costo) * 100 : 0.0;

    return ProductMargin(
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      costo: costo,
      precioVenta: precioVenta,
      margen: margen,
      porcentajeMargen: porcentajeMargen,
    );
  }
}

class CashFlow {
  final DateTime fecha;
  final double ingresos;
  final double egresos;
  final double saldo;

  CashFlow({
    required this.fecha,
    required this.ingresos,
    required this.egresos,
    required this.saldo,
  });

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha.toIso8601String(),
      'ingresos': ingresos,
      'egresos': egresos,
      'saldo': saldo,
    };
  }

  factory CashFlow.fromMap(Map<String, dynamic> map) {
    return CashFlow(
      fecha: DateTime.tryParse(map['fecha'] as String) ?? DateTime.now(),
      ingresos: (map['ingresos'] as num?)?.toDouble() ?? 0.0,
      egresos: (map['egresos'] as num?)?.toDouble() ?? 0.0,
      saldo: (map['saldo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
