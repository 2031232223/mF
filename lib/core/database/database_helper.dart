import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nova_aden.db');

    return await openDatabase(
      path,
      version: 2, // Incrementado para migración
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla productos con TODOS los campos nuevos
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        codigo TEXT NOT NULL,
        costo REAL,
        precio_venta REAL NOT NULL,
        stock_actual INTEGER NOT NULL,
        stock_minimo INTEGER NOT NULL,
        categoria TEXT,
        es_favorito INTEGER DEFAULT 0,
        stock_critico INTEGER
      )
    ''');

    // Tabla clientes
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        carnet_identidad TEXT NOT NULL,
        telefono TEXT NOT NULL,
        es_habitual INTEGER DEFAULT 0,
        fecha_registro TEXT
      )
    ''');

    // Tabla proveedores
    await db.execute('''
      CREATE TABLE proveedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        contacto TEXT,
        telefono TEXT
      )
    ''');

    // Tabla compras
    await db.execute('''
      CREATE TABLE compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proveedor_id INTEGER,
        fecha TEXT NOT NULL,
        total REAL NOT NULL
      )
    ''');

    // Tabla compra_detalles
    await db.execute('''
      CREATE TABLE compra_detalles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compra_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        costo_unitario REAL NOT NULL,
        subtotal REAL NOT NULL
      )
    ''');

    // Tabla ventas
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        monto_pagado REAL DEFAULT 0,
        monto_pendiente REAL DEFAULT 0,
        notas_credito TEXT,
        es_fiado INTEGER DEFAULT 0
      )
    ''');

    // Tabla venta_detalles
    await db.execute('''
      CREATE TABLE venta_detalles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL
      )
    ''');

    // Tabla ajustes_inventario
    await db.execute('''
      CREATE TABLE ajustes_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        producto_nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        costo_unitario REAL NOT NULL,
        motivo TEXT,
        fecha TEXT NOT NULL,
        notas TEXT
      )
    ''');

    // Tabla mermas
    await db.execute('''
      CREATE TABLE mermas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        producto_nombre TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        costo_unitario REAL NOT NULL,
        motivo TEXT,
        fecha TEXT NOT NULL,
        notas TEXT
      )
    ''');
  }

  // Migración para bases de datos existentes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar columnas nuevas a productos (si no existen)
      try {
        await db.execute('ALTER TABLE productos ADD COLUMN categoria TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE productos ADD COLUMN es_favorito INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE productos ADD COLUMN stock_critico INTEGER');
      } catch (_) {}
      
      // Agregar columnas a clientes
      try {
        await db.execute('ALTER TABLE clientes ADD COLUMN es_habitual INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE clientes ADD COLUMN fecha_registro TEXT');
      } catch (_) {}
    }
  }
}
