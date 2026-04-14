import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/config_repository.dart';
import '../../core/widgets/common_dialogs.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  // Variables globales para cada configuración
  bool _isDarkMode = false;           // Control de tema claro/oscuro
  String _companyName = 'Nova ADEN';    // Nombre empresa cabecera reportes
  double _taxRate = 0.0;              // Tasa de impuesto (%)
  int _operationLockDays = 30;        // Días para bloquear edición
  int _stockAlertThreshold = 5;       // Stock crítico mínimo
  bool _lowStockNotifications = true; // Alertas de stock bajo
  
  TextEditingController _empresaController = TextEditingController();
  TextEditingController _impuestoController = TextEditingController();
  TextEditingController _bloquearController = TextEditingController();
  TextEditingController _alertaController = TextEditingController();
  
  int _totalVentas = 0;
  double _ventasTotal = 0.0;
  int _totalProductos = 0;
  int _clientesRegistrados = 0;
  int _proveedoresRegistrados = 0;
  String _versionApp = 'v1.0.0';
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllConfigValues();
  }

  Future<void> _loadAllConfigValues() async {
    setState(() => _isLoading = true);
    try {
      // Cargar valores guardados
      await _loadSavedSettings();
      
      // Cargar estadísticas de BD
      final db = await DatabaseHelper.instance.database;
      final ventasCount = await db.rawQuery('SELECT COUNT(*) as total FROM ventas');
      if (ventasCount.isNotEmpty) _totalVentas = ventasCount.first['total'] as int? ?? 0;
      
      final ventasTotal = await db.rawQuery('SELECT SUM(total) as total FROM ventas WHERE es_fiado = 0');
      if (ventasTotal.isNotEmpty) _ventasTotal = (ventasTotal.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final productosCount = await db.rawQuery('SELECT COUNT(*) as total FROM productos');
      if (productosCount.isNotEmpty) _totalProductos = productosCount.first['total'] as int? ?? 0;
      
      final clientesCount = await db.rawQuery('SELECT COUNT(*) as total FROM clientes');
      if (clientesCount.isNotEmpty) _clientesRegistrados = clientesCount.first['total'] as int? ?? 0;
      
      final proveedoresCount = await db.rawQuery('SELECT COUNT(*) as total FROM proveedores');
      if (proveedoresCount.isNotEmpty) _proveedoresRegistrados = proveedoresCount.first['total'] as int? ?? 0;
    } catch (e) {
      print('Error cargando configuración: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedSettings() async {
    final db = await DatabaseHelper.instance.database;
    
    // Modo oscuro
    final darkModeResult = await db.query('config', where: 'key = ?', whereArgs: ['modo_oscuro']);
    if (darkModeResult.isNotEmpty) _isDarkMode = (darkModeResult.first['value'] as int? ?? 0) == 1;
    
    // Nombre empresa
    final nameResult = await db.query('config', where: 'key = ?', whereArgs: ['nombre_empresa']);
    if (nameResult.isNotEmpty) _companyName = nameResult.first['value'] as String? ?? 'Nova ADEN';
    _empresaController.text = _companyName;
    
    // Tasa impuesto
    final taxResult = await db.query('config', where: 'key = ?', whereArgs: ['tasa_impuesto']);
    if (taxResult.isNotEmpty) _taxRate = (taxResult.first['value'] as num?)?.toDouble() ?? 0.0;
    _impuestoController.text = _taxRate.toStringAsFixed(1);
    
    // Bloquear operaciones
    final lockResult = await db.query('config', where: 'key = ?', whereArgs: ['dias_bloqueo']);
    if (lockResult.isNotEmpty) _operationLockDays = (lockResult.first['value'] as int? ?? 30);
    _bloquearController.text = _operationLockDays.toString();
    
    // Alerta stock
    final alertResult = await db.query('config', where: 'key = ?', whereArgs: ['alerta_stock']);
    if (alertResult.isNotEmpty) _stockAlertThreshold = (alertResult.first['value'] as int? ?? 5);
    _alertaController.text = _stockAlertThreshold.toString();
    
    // Notificaciones
    final notifResult = await db.query('config', where: 'key = ?', whereArgs: ['notificaciones']);
    if (notifResult.isNotEmpty) _lowStockNotifications = (notifResult.first['value'] as int? ?? 1) == 1;
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'config',
      {'key': key, 'value': value.toString(), 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección General
            _buildSectionHeader(context, 'General'),
            _buildThemeToggleCard(context),
            const SizedBox(height: 12),
            _buildCurrencySection(context),
            
            const SizedBox(height: 24),
            
            // Sección Reportes y Operaciones
            _buildSectionHeader(context, 'Reportes y Operaciones'),
            const SizedBox(height: 8),
            _buildReportHeaderSection(context),
            _buildTaxSection(context),
            _buildOperationLockSection(context),
            
            const SizedBox(height: 24),
            
            // Sección Inventario
            _buildSectionHeader(context, 'Inventario'),
            _buildStockAlertSection(context),
            
            const SizedBox(height: 24),
            
            // Sección Sistema
            _buildSectionHeader(context, 'Sistema'),
            _buildNotificationsSection(context),
            _buildBackupSection(context),
            _buildDailyNotesSection(context),
            
            const SizedBox(height: 24),
            
            // Sección Acerca de (NUEVO - Lo que faltaba)
            _buildSectionHeader(context, ''),
            _buildAboutSection(context),
            
            // Estadísticas finales
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildStatsSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    if (title.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      Container(
        width: 4,
        height: 24,
        decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryColor)),
    ]);
  }

  // === TARJETAS INDIVIDUALES ===

  Widget _buildThemeToggleCard(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(Icons.dark_mode, color: _isDarkMode ? Colors.orange : Colors.cyan),
        title: const Text('Modo Claro/Oscuro'),
        subtitle: const Text('Cambiar entre temas instantáneamente'),
        value: _isDarkMode,
        onChanged: (value) {
          setState(() => _isDarkMode = value);
          _saveSetting('modo_oscuro', value ? 1 : 0);
        },
      ),
    );
  }

  Widget _buildCurrencySection(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.attach_money, color: theme.colorScheme.secondary),
      title: const Text('Monedas y Tasas'),
      subtitle: const Text('Configurar CUP, MLC, USD'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showCurrencyDialog(context),
    );
  }

  Widget _buildReportHeaderSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text('Cabecera de Reportes', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16),
          TextField(
            controller: TextEditingController(text: _companyName),
            decoration: InputDecoration(
              hintText: 'Texto del reporte (ej: Nova ADEN)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) => _empresaController.text = val,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _companyName = _empresaController.text);
              _saveSetting('nombre_empresa', _companyName);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Guardado correctamente'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar Configuración'),
          ),
        ]),
      ),
    );
  }

  Widget _buildTaxSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text('Impuesto %', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Tasa de impuesto en %'),
                onChanged: (val) => _impuestoController.text = val,
                controller: TextEditingController(text: _taxRate.toStringAsFixed(1)),
              ),
            ),
            const SizedBox(width: 8),
            Text('%'),
          ]),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _taxRate = double.tryParse(_impuestoController.text) ?? 0.0);
              _saveSetting('tasa_impuesto', _taxRate);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Impuestos actualizados'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Aplicar Impuestos'),
          ),
        ]),
      ),
    );
  }

  Widget _buildOperationLockSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.lock_clock, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Bloquear operaciones >', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Días para bloqueo'),
                onChanged: (val) => _bloquearController.text = val,
                controller: TextEditingController(text: _operationLockDays.toString()),
              ),
            ),
            const SizedBox(width: 8),
            Text('días'),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _operationLockDays = int.tryParse(_bloquearController.text) ?? 30);
              _saveSetting('dias_bloqueo', _operationLockDays);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚠️ Bloqueo configurado'), backgroundColor: Colors.orange),
              );
            },
            icon: const Icon(Icons.timer),
            label: const Text('Activar Bloqueo'),
          ),
        ]),
      ),
    );
  }

  Widget _buildStockAlertSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text('Alerta de Stock Crítico', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Umbral de alerta'),
                onChanged: (val) => _alertaController.text = val,
                controller: TextEditingController(text: _stockAlertThreshold.toString()),
              ),
            ),
            const SizedBox(width: 8),
            Text('unid.'),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _stockAlertThreshold = int.tryParse(_alertaController.text) ?? 5);
              _saveSetting('alerta_stock', _stockAlertThreshold);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Umbral establecido'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Guardar Umbral'),
          ),
        ]),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(Icons.notifications, color: theme.colorScheme.secondary),
        title: const Text('Notificaciones'),
        subtitle: const Text('Alertas de stock bajo activadas'),
        value: _lowStockNotifications,
        onChanged: (value) {
          setState(() => _lowStockNotifications = value);
          _saveSetting('notificaciones', value ? 1 : 0);
        },
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.cloud_upload, color: theme.colorScheme.secondary),
      title: const Text('Respaldos'),
      subtitle: const Text('Crear o restaurar copias'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _confirmBackupAction(context),
    );
  }

  Widget _buildDailyNotesSection(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.note_add, color: theme.colorScheme.secondary),
        title: const Text('Notas Diarias'),
        subtitle: const Text('Registrar notas del día'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, '/notes'), // Redirige a notes_page si existe
      ),
    );
  }

  // === SECCIÓN ACERCA DE (LA QUE FALTABA) ===

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Image.network(
            'https://raw.githubusercontent.com/2031232223/mF/main/assets/logo.png', // O usa un asset local
            width: 80,
            height: 80,
            errorBuilder: (ctx, err, stack) => CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.business, size: 48, color: Colors.white),
            ),
            loadingBuilder: (ctx, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircleAvatar(
                radius: 40,
                child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null 
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : 0.5),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('nova-ADEN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Sistema de Gestión Comercial v${_versionApp}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Divider(height: 24),
          ListTile(
            leading: Icon(Icons.code, color: theme.colorScheme.secondary, size: 20),
            title: const Text('Versión'),
            subtitle: Text(_versionApp),
          ),
          ListTile(
            leading: Icon(Icons.storage, color: theme.colorScheme.secondary, size: 20),
            title: const Text('Base de Datos'),
            subtitle: const Text('SQLite v6 - Sin corrupción'),
          ),
          ListTile(
            leading: Icon(Icons.person, color: theme.colorScheme.secondary, size: 20),
            title: const Text('Autor'),
            subtitle: const Text('2031232223'),
          ),
          ListTile(
            leading: Icon(Icons.event, color: theme.colorScheme.secondary, size: 20),
            title: const Text('Fecha de lanzamiento'),
            subtitle: const Text('Febrero 2026'),
          ),
          const Divider(height: 24),
          Text(
            '© 2026 nova-ADEN - Todos los derechos reservados',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Estadísticas del Sistema', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '💼 Ventas', '${_totalVentas}'),
              _buildStatItem(context, '📦 Productos', '${_totalProductos}'),
              _buildStatItem(context, '👤 Clientes', '${_clientesRegistrados}'),
              _buildStatItem(context, '🏪 Proveedores', '${_proveedoresRegistrados}'),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]);
  }

  // === MÉTODOS DE DIÁLOGOS ===

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Monedas'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.money),
            title: const Text('CUP (Peso Cubano)'),
            subtitle: const Text('Moneda base del sistema'),
            tileColor: Colors.blue[50],
            enabled: false,
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet),
            title: const Text('MLC (Moneda Libremente Convertible)'),
            subtitle: const Text('Moneda internacional'),
            tileColor: Colors.blue[50],
            enabled: false,
          ),
          ListTile(
            leading: Icon(Icons.currency_bitcoin),
            title: const Text('USD (Dólar Americano)'),
            subtitle: const Text('Divisa extranjera'),
            tileColor: Colors.blue[50],
            enabled: false,
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Tasa de cambio CUP/USD'),
            autofocus: true,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Guardar')),
        ],
      ),
    );
  }

  void _confirmBackupAction(BuildContext context) {
    CommonDialogs.showDeleteConfirmation(
      context: context,
      itemName: 'Respaldo',
      message: '¿Desea crear una copia de seguridad completa?',
    ).then((confirmado) {
      if (confirmado == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📤 Creando copia de seguridad...'), backgroundColor: Colors.blue),
        );
      }
    });
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _impuestoController.dispose();
    _bloquearController.dispose();
    _alertaController.dispose();
    super.dispose();
  }
}
