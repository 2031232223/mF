import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/backup_repository.dart';
import '../../core/widgets/common_dialogs.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupRepository _backupRepo = BackupRepository();
  List<Map<String, dynamic>> _backups = [];
  Map<String, dynamic> _backupInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      _backups = await _backupRepo.listBackups();
      _backupInfo = await _backupRepo.getBackupInfo();
    } catch (e) {
      print('Error cargando respaldos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createManualBackup() async {
    final confirmed = await CommonDialogs.showDeleteConfirmation(
      context: context,
      itemName: 'respaldo manual',
      message: '¿Crear respaldo manual de toda la base de datos?',
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final path = await _backupRepo.createManualBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Respaldo creado: ${path.split('/').last}'),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(String backupPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Restaurar Respaldo'),
        content: const Text(
          'Esto reemplazará TODOS los datos actuales con los del respaldo. ¿Estás seguro?',
        ),
        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await _backupRepo.restoreBackup(backupPath);
      if (mounted) {
        Navigator.pop(context); // Cerrar settings si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Respaldo restaurado exitosamente' : '❌ Error al restaurar'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        if (success) {
          // Reiniciar la app para cargar nuevos datos
          Future.delayed(const Duration(seconds: 2), () {
            // Opcional: reiniciar app
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(String backupPath, String backupName) async {
    final confirmed = await CommonDialogs.showDeleteConfirmation(
      context: context,
      itemName: backupName,
      message: '¿Eliminar este respaldo permanentemente?',
    );

    if (confirmed != true) return;

    try {
      await _backupRepo.deleteBackup(backupPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Respaldo eliminado'), backgroundColor: Colors.black),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
        );
      }
    }
  }

  Future<void> _exportToExternal(String backupPath) async {
    try {
      final newPath = await _backupRepo.moveToExternalStorage(backupPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Respaldo movido a: $newPath'),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldos'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información general
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  
                  // Lista de respaldos
                  Text('Respaldos Disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _backups.isEmpty
                      ? const Center(child: Text('No hay respaldos creados', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _backups.length,
                          itemBuilder: (ctx, i) => _buildBackupCard(_backups[i]),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: Theme.of(context).primaryColor, size: 32),
                const SizedBox(width: 12),
                Text('Información de Respaldos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Total de respaldos', '${_backupInfo['totalBackups'] ?? 0}'),
            _buildInfoRow('Espacio utilizado', '${((_backupInfo['totalSize'] ?? 0) / 1024).toStringAsFixed(2)} KB'),
            _buildInfoRow(
              'Último respaldo',
              _backupInfo['lastBackup'] != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(_backupInfo['lastBackup'] as DateTime)
                  : 'Nunca',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _createManualBackup,
            icon: const Icon(Icons.add),
            label: const Text('Crear Respaldo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loadBackups,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupCard(Map<String, dynamic> backup) {
    final date = backup['date'] as DateTime;
    final size = backup['size'] as int;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backup['type'] == 'Automático' ? Colors.blue : Colors.green,
          child: Icon(backup['type'] == 'Automático' ? Icons.auto_awesome : Icons.folder, color: Colors.white),
        ),
        title: Text(backup['name'] as String),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${backup['type']} • ${DateFormat('dd/MM/yyyy HH:mm').format(date)}'),
            Text('${(size / 1024).toStringAsFixed(2)} KB', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'restore') _restoreBackup(backup['path'] as String);
            if (value == 'export') _exportToExternal(backup['path'] as String);
            if (value == 'delete') _deleteBackup(backup['path'] as String, backup['name'] as String);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'restore', child: Text(' Restaurar')),
            const PopupMenuItem(value: 'export', child: Text('📤 Exportar a externo')),
            const PopupMenuItem(value: 'delete', child: Text('🗑️ Eliminar')),
          ],
        ),
      ),
    );
  }
}
