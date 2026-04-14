import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';

class BackupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // RF 38: Crear respaldo manual
  Future<String> createManualBackup() async {
    try {
      final db = await _dbHelper.database;
      final backupData = await _exportDatabase(db);
      final backupPath = await _getBackupPath('manual');
      
      // Escribir datos del respaldo
      final file = File(backupPath);
      await file.writeAsString(jsonEncode(backupData));
      
      // RF 76: Comprimir respaldo
      await _compressBackup(backupPath);
      
      return backupPath;
    } catch (e) {
      throw Exception('Error creando respaldo: $e');
    }
  }

  // RF 37: Crear respaldo automático
  Future<String> createAutomaticBackup() async {
    try {
      final db = await _dbHelper.database;
      final backupData = await _exportDatabase(db);
      final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: .]'), '-');
      final backupPath = await _getBackupPath('auto_$dateStr');
      
      final file = File(backupPath);
      await file.writeAsString(jsonEncode(backupData));
      
      await _compressBackup(backupPath);
      
      // Limpiar respaldos antiguos (mantener últimos 5)
      await _cleanupOldBackups();
      
      return backupPath;
    } catch (e) {
      throw Exception('Error creando respaldo automático: $e');
    }
  }

  // RF 39: Restaurar desde respaldo
  Future<bool> restoreBackup(String backupPath) async {
    try {
      // RF 77: Validar integridad primero
      final isValid = await validateBackupIntegrity(backupPath);
      if (!isValid) {
        throw Exception('El respaldo está corrupto o es inválido');
      }

      final db = await _dbHelper.database;
      final file = File(backupPath.endsWith('.zip') 
          ? backupPath.replaceAll('.zip', '.json') 
          : backupPath);
      
      String jsonData;
      if (file.existsSync()) {
        jsonData = await file.readAsString();
      } else {
        // Intentar descomprimir
        await _decompressBackup(backupPath);
        jsonData = await file.readAsString();
      }
      
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;
      
      await db.transaction((txn) async {
        // Limpiar tablas existentes
        await _clearAllTables(txn);
        
        // Restaurar datos
        await _importDatabase(txn, backupData);
      });
      
      return true;
    } catch (e) {
      print('Error restaurando respaldo: $e');
      return false;
    }
  }

  // RF 75: Obtener ruta de carpeta externa para respaldos
  Future<String> getExternalBackupPath() async {
    try {
      // Intentar obtener almacenamiento externo
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final backupDir = Directory('${externalDir.path}/NovaADEN/Backups');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        return backupDir.path;
      }
      
      // Fallback a directorio de la app
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/NovaADEN/Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir.path;
    } catch (e) {
      throw Exception('Error obteniendo ruta externa: $e');
    }
  }

  // RF 75: Mover respaldo a carpeta externa
  Future<String> moveToExternalStorage(String backupPath) async {
    try {
      final externalPath = await getExternalBackupPath();
      final fileName = path.basename(backupPath);
      final newPath = '$externalPath/$fileName';
      
      final file = File(backupPath);
      await file.copy(newPath);
      
      return newPath;
    } catch (e) {
      throw Exception('Error moviendo a almacenamiento externo: $e');
    }
  }

  // RF 76: Comprimir respaldo
  Future<void> _compressBackup(String jsonPath) async {
    try {
      // Nota: Para compresión real se necesita el paquete archive
      // Esta es una implementación simplificada
      final jsonFile = File(jsonPath);
      if (await jsonFile.exists()) {
        // Crear archivo .backup como "comprimido"
        final compressedPath = jsonPath.replaceAll('.json', '.backup');
        await jsonFile.copy(compressedPath);
        // Opcional: eliminar el JSON original
        // await jsonFile.delete();
      }
    } catch (e) {
      print('Error comprimiendo: $e');
    }
  }

  // RF 76: Descomprimir respaldo
  Future<void> _decompressBackup(String compressedPath) async {
    try {
      final compressedFile = File(compressedPath);
      if (await compressedFile.exists()) {
        final jsonPath = compressedPath.replaceAll('.backup', '.json');
        await compressedFile.copy(jsonPath);
      }
    } catch (e) {
      print('Error descomprimiendo: $e');
    }
  }

  // RF 77: Validar integridad del respaldo
  Future<bool> validateBackupIntegrity(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        return false;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validar estructura básica
      if (!data.containsKey('tables')) {
        return false;
      }

      final tables = data['tables'] as Map<String, dynamic>;
      
      // Validar que existan tablas críticas
      final requiredTables = ['productos', 'ventas', 'clientes', 'proveedores'];
      for (var table in requiredTables) {
        if (!tables.containsKey(table)) {
          return false;
        }
      }

      // Validar checksum (si existe)
      if (data.containsKey('checksum')) {
        final storedChecksum = data['checksum'] as String;
        final calculatedChecksum = _calculateChecksum(content);
        if (storedChecksum != calculatedChecksum) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error validando integridad: $e');
      return false;
    }
  }

  // RF 77: Calcular checksum del respaldo
  String _calculateChecksum(String content) {
    // Implementación simple de hash
    int hash = 0;
    for (var i = 0; i < content.length; i++) {
      hash = content.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash.toString();
  }

  // Exportar base de datos a JSON
  Future<Map<String, dynamic>> _exportDatabase(Database db) async {
    final tables = [
      'productos', 'ventas', 'detalle_ventas', 'clientes',
      'proveedores', 'compras', 'compra_detalles', 'mermas',
      'config', 'ventas_pausadas'
    ];

    final data = <String, dynamic>{
      'version': '1.0',
      'date': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{}
    };

    for (var table in tables) {
      try {
        final rows = await db.query(table);
        data['tables'][table] = rows;
      } catch (e) {
        print('Tabla $table no existe o error: $e');
        data['tables'][table] = [];
      }
    }

    // Agregar checksum
    data['checksum'] = _calculateChecksum(jsonEncode(data['tables']));

    return data;
  }

  // Importar datos desde JSON
  Future<void> _importDatabase(Transaction txn, Map<String, dynamic> data) async {
    final tables = data['tables'] as Map<String, dynamic>;

    for (var entry in tables.entries) {
      final tableName = entry.key;
      final rows = entry.value as List<dynamic>;

      for (var row in rows) {
        try {
          await txn.insert(tableName, row as Map<String, dynamic>);
        } catch (e) {
          print('Error insertando en $tableName: $e');
        }
      }
    }
  }

  // Limpiar todas las tablas
  Future<void> _clearAllTables(Transaction txn) async {
    final tables = [
      'ventas_pausadas', 'mermas', 'compra_detalles', 'compras',
      'detalle_ventas', 'ventas', 'clientes', 'proveedores', 'productos', 'config'
    ];

    for (var table in tables) {
      try {
        await txn.delete(table);
      } catch (e) {
        print('Error limpiando tabla $table: $e');
      }
    }
  }

  // Obtener ruta de respaldo
  Future<String> _getBackupPath(String type) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/NovaADEN/Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    final dateStr = DateTime.now().toString().replaceAll(RegExp(r'[: .]'), '-');
    return '${backupDir.path}/backup_${type}_$dateStr.json';
  }

  // Limpiar respaldos antiguos (mantener últimos 5)
  Future<void> _cleanupOldBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/NovaADEN/Backups');
      
      if (await backupDir.exists()) {
        final files = await backupDir.list().toList();
        final backups = files
            .where((f) => f.path.contains('backup_auto'))
            .toList();
        
        backups.sort((a, b) => b.path.compareTo(a.path));
        
        // Eliminar todos excepto los 5 más recientes
        if (backups.length > 5) {
          for (var i = 5; i < backups.length; i++) {
            await File(backups[i].path).delete();
          }
        }
      }
    } catch (e) {
      print('Error limpiando respaldos: $e');
    }
  }

  // Listar respaldos disponibles
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/NovaADEN/Backups');
      
      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      final backups = <Map<String, dynamic>>[];

      for (var file in files) {
        if (file is File && (file.path.endsWith('.json') || file.path.endsWith('.backup'))) {
          final stat = await file.stat();
          backups.add({
            'path': file.path,
            'name': path.basename(file.path),
            'size': stat.size,
            'date': stat.modified,
            'type': file.path.contains('auto') ? 'Automático' : 'Manual',
          });
        }
      }

      backups.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      return backups;
    } catch (e) {
      print('Error listando respaldos: $e');
      return [];
    }
  }

  // Eliminar respaldo
  Future<void> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Error eliminando respaldo: $e');
    }
  }

  // Obtener información del sistema para respaldo
  Future<Map<String, dynamic>> getBackupInfo() async {
    final backups = await listBackups();
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/NovaADEN/Backups');
    
    int totalSize = 0;
    if (await backupDir.exists()) {
      final files = await backupDir.list().toList();
      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    }

    return {
      'totalBackups': backups.length,
      'totalSize': totalSize,
      'lastBackup': backups.isNotEmpty ? backups.first['date'] : null,
      'externalPath': await getExternalBackupPath(),
    };
  }
}
