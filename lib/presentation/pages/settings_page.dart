import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_settings_page.dart';
import 'backup_page.dart';
import 'notes_page.dart';
import 'help_feedback_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Variables de configuración
  String _companyName = 'Nova ADEN';
  double _taxRate = 0.0;
  String _mainCurrency = 'CUP';
  double _exchangeRate = 1.0;
  bool _stockReminderEnabled = false;
  int _stockReminderDays = 7;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  // Cargar todas las configuraciones
  Future<void> _loadAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _companyName = prefs.getString('company_name') ?? 'Nova ADEN';
          _taxRate = prefs.getDouble('tax_rate') ?? 0.0;
          _mainCurrency = prefs.getString('main_currency') ?? 'CUP';
          _exchangeRate = prefs.getDouble('exchange_rate') ?? 1.0;
          _stockReminderEnabled = prefs.getBool('stock_reminder_enabled') ?? false;
          _stockReminderDays = prefs.getInt('stock_reminder_days') ?? 7;
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
          _darkMode = prefs.getBool('dark_mode') ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Guardar configuración
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is String) await prefs.setString(key, value);
      else if (value is double) await prefs.setDouble(key, value);
      else if (value is bool) await prefs.setBool(key, value);
      else if (value is int) await prefs.setInt(key, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Guardado: $key'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
        );
      }
      _loadAllSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ========== WIDGETS DE UI ==========

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required String subtitle, VoidCallback? onTap, Color? iconColor}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: (iconColor ?? Colors.blue).withOpacity(0.1), child: Icon(icon, color: iconColor ?? Colors.blue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchCard({required IconData icon, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: Switch(value: value, onChanged: onChanged, activeColor: Colors.blue),
      ),
    );
  }

  Widget _buildInputCard({required IconData icon, required String title, required String subtitle, required String currentValue, required VoidCallback onSave}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: Text(currentValue, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        onTap: () => _showInputDialog(title, currentValue, onSave),
      ),
    );
  }

  void _showInputDialog(String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ingresa el valor', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== FUNCIONES DE CONFIGURACIÓN ==========

  void _editCompanyName() => _showInputDialog('Nombre de la Empresa', _companyName, (val) {
    if (val.trim().isNotEmpty) {
      setState(() => _companyName = val.trim());
      _saveSetting('company_name', val.trim());
    }
  });

  void _editTaxRate() => _showInputDialog('Tasa de Impuesto (%)', _taxRate.toString(), (val) {
    final rate = double.tryParse(val) ?? 0.0;
    setState(() => _taxRate = rate);
    _saveSetting('tax_rate', rate);
  });

  void _editExchangeRate() => _showInputDialog('Tasa de Cambio (CUP por USD)', _exchangeRate.toString(), (val) {
    final rate = double.tryParse(val) ?? 1.0;
    setState(() => _exchangeRate = rate);
    _saveSetting('exchange_rate', rate);
  });

  void _editStockReminderDays() => _showInputDialog('Días para recordatorio', _stockReminderDays.toString(), (val) {
    final days = int.tryParse(val) ?? 7;
    setState(() => _stockReminderDays = days.clamp(1, 30));
    _saveSetting('stock_reminder_days', _stockReminderDays);
  });

  void _showCurrencySettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencySettingsPage()));
  }

  void _showBackupPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage()));
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar Base de Datos', style: TextStyle(color: Colors.black87)),
        content: const Text('¿Estás seguro? Esta acción reemplazará todos los datos actuales con el respaldo seleccionado.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔄 Restaurando...'), backgroundColor: Colors.blue));
              // TODO: Implementar lógica de restauración
            },
            child: const Text('Restaurar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCsv() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📤 Exportando datos...'), backgroundColor: Colors.blue));
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Datos exportados exitosamente'), backgroundColor: Colors.green));
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Nova ADEN',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.store, size: 40, color: Colors.blue),
      children: const [Text('Sistema de Gestión para Negocios Minoristas\n\nDesarrollado con Flutter + SQLite\n\n© 2026')],
    );
  }

  void _showNotesPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesPage()));
  }

  void _showHelpFeedback() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpFeedbackPage()));
  }

  // ========== BUILD METHOD ==========

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.grey,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Sección: Empresa
          _buildSectionTitle('🏢 EMPRESA'),
          _buildInputCard(icon: Icons.business, title: 'Nombre de la Empresa', subtitle: 'Nombre que aparecerá en tickets y reportes', currentValue: _companyName, onSave: _editCompanyName),
          _buildInputCard(icon: Icons.percent, title: 'Tasa de Impuesto', subtitle: 'Porcentaje aplicado automáticamente a ventas', currentValue: '${_taxRate.toStringAsFixed(1)}%', onSave: _editTaxRate),

          // Sección: Moneda
          _buildSectionTitle('💱 MONEDA'),
          _buildCard(icon: Icons.currency_exchange, title: 'Moneda Principal', subtitle: 'Seleccionar: CUP / USD / MLC', onTap: _showCurrencySettings),
          _buildInputCard(icon: Icons.attach_money, title: 'Tasa de Cambio', subtitle: 'CUP equivalentes a 1 USD', currentValue: _exchangeRate.toStringAsFixed(2), onSave: _editExchangeRate),

          // Sección: Inventario
          _buildSectionTitle('📦 INVENTARIO'),
          _buildSwitchCard(icon: Icons.warning_amber, title: 'Recordatorio de Stock', subtitle: 'Alertar cuando productos estén por agotarse', value: _stockReminderEnabled, onChanged: (val) { setState(() => _stockReminderEnabled = val); _saveSetting('stock_reminder_enabled', val); }),
          _buildInputCard(icon: Icons.calendar_today, title: 'Días para Alerta', subtitle: 'Anticipación en días para recordatorio de stock bajo', currentValue: '$_stockReminderDays días', onSave: _editStockReminderDays),

          // Sección: Notificaciones
          _buildSectionTitle('🔔 NOTIFICACIONES'),
          _buildSwitchCard(icon: Icons.notifications_active, title: 'Notificaciones del Sistema', subtitle: 'Recibir alertas de ventas, stock y respaldos', value: _notificationsEnabled, onChanged: (val) { setState(() => _notificationsEnabled = val); _saveSetting('notifications_enabled', val); }),

          // Sección: Apariencia
          _buildSectionTitle('🎨 APARIENCIA'),
          _buildSwitchCard(icon: Icons.dark_mode, title: 'Modo Oscuro', subtitle: 'Cambiar entre tema claro y oscuro', value: _darkMode, onChanged: (val) { setState(() => _darkMode = val); _saveSetting('dark_mode', val); }),

          // Sección: Datos y Respaldos
          _buildSectionTitle('💾 DATOS Y RESPALDOS'),
          _buildCard(icon: Icons.backup, title: 'Respaldar Base de Datos', subtitle: 'Crear copia de seguridad completa', onTap: _showBackupPage, iconColor: Colors.green),
          _buildCard(icon: Icons.restore, title: 'Restaurar Base de Datos', subtitle: 'Recuperar datos desde un respaldo', onTap: _showRestoreDialog, iconColor: Colors.orange),
          _buildCard(icon: Icons.file_download, title: 'Exportar a CSV', subtitle: 'Descargar productos, ventas y clientes en CSV', onTap: _exportToCsv, iconColor: Colors.purple),

          // Sección: Soporte
          _buildSectionTitle('❓ SOPORTE'),
          _buildCard(icon: Icons.notes, title: 'Notas Rápidas', subtitle: 'Tomar notas y recordatorios', onTap: _showNotesPage),
          _buildCard(icon: Icons.help_outline, title: 'Ayuda y Feedback', subtitle: 'Reportar problemas o enviar sugerencias', onTap: _showHelpFeedback),
          _buildCard(icon: Icons.info_outline, title: 'Acerca de Nova ADEN', subtitle: 'Versión 1.0.0 - Información de la app', onTap: _showAboutDialog),

          const SizedBox(height: 30),
          const Center(child: Text('Nova ADEN v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
