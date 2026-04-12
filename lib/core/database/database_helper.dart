import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nova_aden.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // ✅ Aumentamos versión para forzar migración
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  void _createDB(Database db, int version) async {
    // Tabla: Configuración
    await db.execute('''
      CREATE TABLE config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        value TEXT,
        updated_at TEXT
      )
    ''');

    // Tabla: Clientes
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        carnet_identidad TEXT,
        telefono TEXT,
        created_at TEXT
      )
    ''');

    // Tabla: Proveedores (CON ci_identidad)
    await db.execute('''
      CREATE TABLE proveedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        ci_identidad TEXT,
        telefono TEXT,
        created_at TEXT
      )
    ''');

    // Tabla: Productos (HU_GP - Gestionar Producto)
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        codigo TEXT UNIQUE NOT NULL,
        costo REAL,
        precio_venta REAL NOT NULL,
        stock_actual INTEGER DEFAULT 0,
        stock_minimo INTEGER DEFAULT 0,
        categoria TEXT,
        es_favorito INTEGER DEFAULT 0,
        stock_critico INTEGER,
        margen_ganancia REAL,
        unidad_medida TEXT DEFAULT 'UND',
        activo INTEGER DEFAULT 1,
        notas TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Tabla: Ventas (HU_RV - Registrar Venta)
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER,
        total REAL NOT NULL,
        total_cup REAL,
        fecha TEXT NOT NULL,
        metodo_pago TEXT,
        moneda TEXT DEFAULT 'CUP',
        tasa_cambio REAL DEFAULT 1.0,
        es_fiado INTEGER DEFAULT 0,
        pagado REAL DEFAULT 0,
        pendiente REAL DEFAULT 0,
        descuento REAL DEFAULT 0,
        created_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');

    // Tabla: Detalles de Venta
    await db.execute('''
      CREATE TABLE venta_detalles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES ventas (id),
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    // Tabla: Compras
    await db.execute('''
      CREATE TABLE compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proveedor_id INTEGER,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        created_at TEXT,
        FOREIGN KEY (proveedor_id) REFERENCES proveedores (id)
      )
    ''');

    // Tabla: Ventas Pausadas
    await db.execute('''
      CREATE TABLE ventas_pausadas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        fecha_creacion TEXT,
        cliente_id INTEGER,
        productos TEXT,
        total REAL
      )
    ''');

    // Índices para mejor rendimiento
    await db.execute('CREATE INDEX idx_productos_codigo ON productos (codigo)');
    await db.execute('CREATE INDEX idx_ventas_fecha ON ventas (fecha)');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migración de versión 1 a 2: Agregar ci_identidad a proveedores
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE proveedores ADD COLUMN ci_identidad TEXT');
      } catch (e) {
        print('Columna ya existe o error: $e');
      }
    }
  }

  // Método para actualizar configuración
  Future<void> updateConfig(String key, dynamic value) async {
    final db = await database;
    await db.insert(
      'config',
      {'key': key, 'value': value.toString(), 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
