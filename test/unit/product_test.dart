import 'package:flutter_test/flutter_test.dart';
import 'package:nova_aden/core/models/product.dart';

void main() {
  group('Pruebas Unitarias - Entidad Product (nova-ADEN)', () {

    test('1. Crear producto con campos válidos', () {
      final product = Product(
        id: 1,                    // ← Cambiado a int (según tu modelo)
        nombre: 'Café molido 1kg',
        codigo: 'CAF001',
        costo: 320.50,
        precioVenta: 580.00,
        stockActual: 45,
      );

      expect(product.id, equals(1));
      expect(product.nombre, equals('Café molido 1kg'));
      expect(product.stockActual, greaterThan(0));
      expect(product.precioVenta, greaterThan(product.costo));
    });

    test('2. Validación de stock insuficiente', () {
      final product = Product(
        id: 2,
        nombre: 'Arroz',
        codigo: 'ARR001',
        costo: 150.0,
        precioVenta: 250.0,
        stockActual: 8,
      );

      bool puedeVender = product.stockActual >= 20;

      expect(puedeVender, isFalse);
    });

    test('3. Producto con stock mínimo correcto', () {
      final product = Product(
        id: 3,
        nombre: 'Azúcar',
        codigo: 'AZU001',
        costo: 80.0,
        precioVenta: 120.0,
        stockActual: 5,
      );

      expect(product.stockActual, lessThan(10)); // ejemplo de alerta de stock bajo
    });

  });
}
