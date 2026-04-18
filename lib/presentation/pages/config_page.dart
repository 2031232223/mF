import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/config_repository.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  bool _isDarkMode = false;
  String _companyName = 'Nova ADEN';
  double _taxRate = 0.0;
  int _operationLockDays = 30;
  int _stockAlertThreshold = 5;
  bool _lowStockNotifications = true;
  
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
      await _loadSavedSettings();
      
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
    
    final darkModeResult = await db.query('config', where: 'key = ?', whereArgs: ['modo_oscuro']);
    if (darkModeResult.isNotEmpty) _isDarkMode = (darkModeResult.first['value'] as int? ?? 0) == 1;
    
    final nameResult = await db.query('config', where: 'key = ?', whereArgs: ['nombre_empresa']);
    if (nameResult.isNotEmpty) _companyName = nameResult.first['value'] as String? ?? 'Nova ADEN';
    _empresaController.text = _companyName;
    
    final taxResult = await db.query('config', where: 'key = ?', whereArgs: ['tasa_impuesto']);
    if (taxResult.isNotEmpty) _taxRate = (taxResult.first['value'] as num?)?.toDouble() ?? 0.0;
    _impuestoController.text = _taxRate.toStringAsFixed(1);
    
    final lockResult = await db.query('config', where: 'key = ?', whereArgs: ['dias_bloqueo']);
    if (lockResult.isNotEmpty) _operationLockDays = (lockResult.first['value'] as int? ?? 30);
    _bloquearController.text = _operationLockDays.toString();
    
    final alertResult = await db.query('config', where: 'key = ?', whereArgs: ['alerta_stock']);
    if (alertResult.isNotEmpty) _stockAlertThreshold = (alertResult.first['value'] as int? ?? 5);
    _alertaController.text = _stockAlertThreshold.toString();
    
    final notifResult = await db.query('config', where: 'key = ?', whereArgs: ['notificaciones']);
    if (notifResult.isNotEmpty) _lowStockNotifications = (notifResult.first['value'] as int? ?? 1) == 1;
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('config', {'key': key, 'value': value.toString(), 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionHeader(context, 'General'),
          _buildThemeToggleCard(context),
          _buildCurrencySection(context),
          
          SizedBox(height: 24),
          
          _buildSectionHeader(context, 'Reportes y Operaciones'),
          SizedBox(height: 8),
          _buildReportHeaderSection(context),
          _buildTaxSection(context),
          _buildOperationLockSection(context),
          
          SizedBox(height: 24),
          
          _buildSectionHeader(context, 'Inventario'),
          _buildStockAlertSection(context),
          
          SizedBox(height: 24),
          
          _buildSectionHeader(context, 'Sistema'),
          _buildNotificationsSection(context),
          _buildBackupSection(context),
          _buildDailyNotesSection(context),
          
          SizedBox(height: 24),
          
          _buildAboutSection(context),
          
          if (_isLoading)
            Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          else
            _buildStatsSummary(context),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    if (title.isEmpty) return SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(children: [
      Container(width: 4, height: 24, decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2))),
      SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryColor)),
    ]);
  }

  Widget _buildThemeToggleCard(BuildContext context) {
    return Card(child: SwitchListTile(
      secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: _isDarkMode ? Colors.orange : Colors.cyan),
      title: Text('Modo Claro/Oscuro'),
      subtitle: Text('Cambiar entre temas instantáneamente'),
      value: _isDarkMode,
      onChanged: (value) { setState(() => _isDarkMode = value); _saveSetting('modo_oscuro', value ? 1 : 0); },
    ));
  }

  Widget _buildCurrencySection(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.secondary),
      title: Text('Monedas y Tasas'),
      subtitle: Text('Configurar CUP, MLC, USD'),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showCurrencyDialog(context),
    );
  }

  Widget _buildReportHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.text_fields, color: theme.colorScheme.secondary),
        SizedBox(width: 8),
        Text('Cabecera de Reportes', style: TextStyle(fontWeight: FontWeight.bold)),
            color: Colors.green,
            color: Colors.green,
      ]),
      Divider(height: 16),
      TextField(
        controller: TextEditingController(text: _companyName),
        decoration: InputDecoration(hintText: 'Texto del reporte (ej: Nova ADEN)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        onChanged: (val) => _empresaController.text = val,
      ),
      SizedBox(height: 12),
      ElevatedButton.icon(
        icon: Icon(Icons.save),
        label: Text('Guardar Configuración'),
        onPressed: () {
          setState(() => _companyName = _empresaController.text);
          _saveSetting('nombre_empresa', _companyName);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Guardado correctamente'), backgroundColor: Colors.black));
        },
      ),
    ])));
  }

  Widget _buildTaxSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.local_offer, color: theme.colorScheme.secondary),
        SizedBox(width: 8),
        Text('Impuesto %', style: TextStyle(fontWeight: FontWeight.bold)),
            color: Colors.green,
            color: Colors.green,
      ]),
      Divider(height: 16),
      Row(children: [
        Expanded(child: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Tasa de impuesto en %'),
          onChanged: (val) => _impuestoController.text = val,
          controller: TextEditingController(text: _taxRate.toStringAsFixed(1)),
        )),
        SizedBox(width: 8),
        Text('%'),
      ]),
      SizedBox(height: 12),
      ElevatedButton.icon(
        icon: Icon(Icons.check),
        label: Text('Aplicar Impuestos'),
        onPressed: () {
          setState(() => _taxRate = double.tryParse(_impuestoController.text) ?? 0.0);
          _saveSetting('tasa_impuesto', _taxRate);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Impuestos actualizados'), backgroundColor: Colors.black));
        },
      ),
    ])));
  }

  Widget _buildOperationLockSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.lock_clock, color: Colors.orange),
        SizedBox(width: 8),
        Text('Bloquear operaciones >', style: TextStyle(fontWeight: FontWeight.bold)),
            color: Colors.green,
            color: Colors.green,
      ]),
      Divider(height: 16),
      Row(children: [
        Expanded(child: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Días para bloqueo'),
          onChanged: (val) => _bloquearController.text = val,
          controller: TextEditingController(text: _operationLockDays.toString()),
        )),
        SizedBox(width: 8),
        Text('días'),
      ]),
      SizedBox(height: 12),
      OutlinedButton.icon(
        icon: Icon(Icons.timer),
        label: Text('Activar Bloqueo'),
        onPressed: () {
          setState(() => _operationLockDays = int.tryParse(_bloquearController.text) ?? 30);
          _saveSetting('dias_bloqueo', _operationLockDays);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Bloqueo configurado'), backgroundColor: Colors.black));
        },
      ),
    ])));
  }

  Widget _buildStockAlertSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.red),
        SizedBox(width: 8),
        Text('Alerta de Stock Crítico', style: TextStyle(fontWeight: FontWeight.bold)),
            color: Colors.green,
            color: Colors.green,
      ]),
      Divider(height: 16),
      Row(children: [
        Expanded(child: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Umbral de alerta'),
          onChanged: (val) => _alertaController.text = val,
          controller: TextEditingController(text: _stockAlertThreshold.toString()),
        )),
        SizedBox(width: 8),
        Text('unid.'),
      ]),
      SizedBox(height: 12),
      OutlinedButton.icon(
        icon: Icon(Icons.notifications_active),
        label: Text('Guardar Umbral'),
        onPressed: () {
          setState(() => _stockAlertThreshold = int.tryParse(_alertaController.text) ?? 5);
          _saveSetting('alerta_stock', _stockAlertThreshold);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Umbral establecido'), backgroundColor: Colors.black));
        },
      ),
    ])));
  }

  Widget _buildNotificationsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: SwitchListTile(
      secondary: Icon(Icons.notifications, color: theme.colorScheme.secondary),
      title: Text('Notificaciones'),
      subtitle: Text('Alertas de stock bajo activadas'),
      value: _lowStockNotifications,
      onChanged: (value) { setState(() => _lowStockNotifications = value); _saveSetting('notificaciones', value ? 1 : 0); },
    ));
  }

  Widget _buildBackupSection(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.cloud_upload, color: Theme.of(context).colorScheme.secondary),
      title: Text('Respaldos'),
      subtitle: Text('Crear o restaurar copias'),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: Text('¿Crear respaldo?'),
          content: Text('¿Desea crear una copia de seguridad completa?'),
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
        ));
      },
    );
  }

  Widget _buildDailyNotesSection(BuildContext context) {
    return Card(child: ListTile(
      leading: Icon(Icons.note_add, color: Theme.of(context).colorScheme.secondary),
      title: Text('Notas Diarias'),
      subtitle: Text('Registrar notas del día'),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, '/notes'),
    ));
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      CircleAvatar(radius: 40, backgroundColor: theme.colorScheme.primary, child: Icon(Icons.business, size: 48, color: Colors.white)),
      SizedBox(height: 16),
      Text('nova-ADEN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            color: Colors.green,
            color: Colors.green,
      SizedBox(height: 8),
      Text('Sistema de Gestión Comercial v${_versionApp}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      Divider(height: 24),
      ListTile(leading: Icon(Icons.code, color: theme.colorScheme.secondary, size: 20), title: Text('Versión'), subtitle: Text(_versionApp)),
      ListTile(leading: Icon(Icons.storage, color: theme.colorScheme.secondary, size: 20), title: Text('Base de Datos'), subtitle: Text('SQLite v6 - Sin corrupción')),
      ListTile(leading: Icon(Icons.person, color: theme.colorScheme.secondary, size: 20), title: Text('Autor'), subtitle: Text('2031232223')),
      ListTile(leading: Icon(Icons.event, color: theme.colorScheme.secondary, size: 20), title: Text('Fecha de lanzamiento'), subtitle: Text('Febrero 2026')),
      Divider(height: 24),
      Text('© 2026 nova-ADEN - Todos los derechos reservados', style: TextStyle(fontSize: 12, color: Colors.grey[500]), textAlign: TextAlign.center),
    ])));
  }

  Widget _buildStatsSummary(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Estadísticas del Sistema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            color: Colors.green,
            color: Colors.green,
      Divider(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatItem(context, '💼 Ventas', '${_totalVentas}'),
        _buildStatItem(context, '📦 Productos', '${_totalProductos}'),
        _buildStatItem(context, '👤 Clientes', '${_clientesRegistrados}'),
        _buildStatItem(context, '🏪 Proveedores', '${_proveedoresRegistrados}'),
      ]),
    ])));
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]);
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configurar Monedas'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: Icon(Icons.money), title: Text('CUB'), subtitle: Text('Moneda base'), tileColor: Colors.blue[50], enabled: false),
          ListTile(leading: Icon(Icons.account_balance_wallet), title: Text('MLC'), subtitle: Text('Moneda internacional'), tileColor: Colors.blue[50], enabled: false),
          ListTile(leading: Icon(Icons.currency_bitcoin), title: Text('USD'), subtitle: Text('Divisa extranjera'), tileColor: Colors.blue[50], enabled: false),
          SizedBox(height: 12),
          TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Tasa de cambio CUP/USD'), autofocus: true),
        ]),
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
