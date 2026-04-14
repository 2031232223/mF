import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/report.dart';

class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // RF 62: Reporte de rotación de productos
  Future<List<ProductRotation>> getProductRotation({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND v.fecha >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND v.fecha <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        p.id as productId,
        p.nombre as productName,
        SUM(dv.cantidad) as totalVendido,
        SUM(dv.subtotal) as ingresosTotales,
        MAX(v.fecha) as ultimaVenta
      FROM productos p
      INNER JOIN detalle_ventas dv ON p.id = dv.producto_id
      INNER JOIN ventas v ON dv.venta_id = v.id
      WHERE v.es_fiado = 0 $whereClause
      GROUP BY p.id, p.nombre
      ORDER BY totalVendido DESC
      LIMIT ?
    ''', [...whereArgs, limit]);

    return result.map((map) => ProductRotation.fromMap(map)).toList();
  }

  // RF 63: Reporte de margen por producto
  Future<List<ProductMargin>> getProductMargin() async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        id as productId,
        nombre as productName,
        costo,
        precio_venta as precioVenta
      FROM productos
      WHERE costo > 0 AND precio_venta > 0
      ORDER BY (precio_venta - costo) DESC
    ''');

    return result.map((map) => ProductMargin.fromMap(map)).toList();
  }

  // RF 64: Reporte de flujo de caja
  Future<List<CashFlow>> getCashFlow({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;
    
    // Ingresos por ventas
    final ingresosResult = await db.rawQuery('''
      SELECT 
        DATE(fecha) as fecha,
        SUM(monto_pagado) as total
      FROM ventas
      WHERE fecha >= ? AND fecha <= ? AND es_fiado = 0
      GROUP BY DATE(fecha)
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Egresos por compras
    final egresosResult = await db.rawQuery('''
      SELECT 
        DATE(fecha) as fecha,
        SUM(total) as total
      FROM compras
      WHERE fecha >= ? AND fecha <= ?
      GROUP BY DATE(fecha)
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    Map<String, CashFlow> cashFlowMap = {};

    // Procesar ingresos
    for (var row in ingresosResult) {
      final fechaStr = row['fecha'] as String;
      final ingresos = (row['total'] as num?)?.toDouble() ?? 0.0;
      cashFlowMap[fechaStr] = CashFlow(
        fecha: DateTime.parse(fechaStr),
        ingresos: ingresos,
        egresos: 0.0,
        saldo: ingresos,
      );
    }

    // Procesar egresos y calcular saldo
    for (var row in egresosResult) {
      final fechaStr = row['fecha'] as String;
      final egresos = (row['total'] as num?)?.toDouble() ?? 0.0;
      
      if (cashFlowMap.containsKey(fechaStr)) {
        final existing = cashFlowMap[fechaStr]!;
        cashFlowMap[fechaStr] = CashFlow(
          fecha: existing.fecha,
          ingresos: existing.ingresos,
          egresos: egresos,
          saldo: existing.ingresos - egresos,
        );
      } else {
        cashFlowMap[fechaStr] = CashFlow(
          fecha: DateTime.parse(fechaStr),
          ingresos: 0.0,
          egresos: egresos,
          saldo: -egresos,
        );
      }
    }

    return cashFlowMap.values.toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  // RF 67: Datos para gráficos de ventas
  Future<Map<String, dynamic>> getSalesChartData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND fecha >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND fecha <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    // Ventas por día
    final dailySales = await db.rawQuery('''
      SELECT 
        DATE(fecha) as fecha,
        COUNT(*) as cantidad,
        SUM(total) as total
      FROM ventas
      WHERE es_fiado = 0 $whereClause
      GROUP BY DATE(fecha)
      ORDER BY fecha
    ''', whereArgs);

    // Ventas por categoría de producto
    final byCategory = await db.rawQuery('''
      SELECT 
        p.categoria,
        COUNT(*) as cantidad,
        SUM(dv.subtotal) as total
      FROM detalle_ventas dv
      INNER JOIN productos p ON dv.producto_id = p.id
      INNER JOIN ventas v ON dv.venta_id = v.id
      WHERE v.es_fiado = 0 $whereClause
      GROUP BY p.categoria
    ''', whereArgs);

    return {
      'dailySales': dailySales,
      'byCategory': byCategory,
    };
  }
}
