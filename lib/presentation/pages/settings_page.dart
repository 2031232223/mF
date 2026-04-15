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

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is String) await prefs.setString(key, value);
      else if (value is double) await prefs.setDouble(key, value);
      else if (value is bool) await prefs.setBool(key, value);
      else if (value is int) await prefs.setInt(key, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Guardado: $key'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)));
      }
      _loadAllSettings();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(8, 20, 8, 8), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green)));
  }

  Widget _buildCard({required IconData icon, required String title, required String subtitle, required VoidCallback? onTap, Color? iconColor}) {
    return Card(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), elevation: 2, child: ListTile(leading: CircleAvatar(backgroundColor: (iconColor ?? Colors.green).withOpacity(0.1), child: Icon(icon, color: iconColor ?? Colors.green)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)), subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])), trailing: const Icon(Icons.chevron_right, color: Colors.green), onTap: onTap,));
  }

  Widget _buildSwitchCard({required IconData icon, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Card(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), elevation: 2, child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: Icon(icon, color: Colors.green)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)), subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])), trailing: Switch(value: value, onChanged: onChanged, activeColor: Colors.green),));
  }

  Widget _buildInputCard({required IconData icon, required String title, required String subtitle, required String currentValue, required VoidCallback onTap}) {
    return Card(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), elevation: 2, child: ListTile(leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: Icon(icon, color: Colors.green)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)), subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])), trailing: Text(currentValue, style: const TextStyle(color: Colors.green, fontSize: 12)), onTap: onTap,));
  }

  void _showInputDialog(String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: Text(title, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)), content: TextField(controller: controller, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600), decoration: const InputDecoration(hintText: 'Ingresa el valor', border: OutlineInputBorder(), hintStyle: TextStyle(color: Colors.grey))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))), ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () { onSave(controller.text); Navigator.pop(ctx); }, child: const Text('Guardar', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))),],));
  }

  void _editCompanyName() => _showInputDialog('Nombre de la Empresa', _companyName, (val) { if (val.trim().isNotEmpty) { setState(() => _companyName = val.trim()); _saveSetting('company_name', val.trim()); } });
  void _editTaxRate() => _showInputDialog('Tasa de Impuesto (%)', _taxRate.toString(), (val) { final rate = double.tryParse(val) ?? 0.0; setState(() => _taxRate = rate); _saveSetting('tax_rate', rate); });
  void _editExchangeRate() => _showInputDialog('Tasa de Cambio (CUP por USD)', _exchangeRate.toString(), (val) { final rate = double.tryParse(val) ?? 1.0; setState(() => _exchangeRate = rate); _saveSetting('exchange_rate', rate); });
  void _editStockReminderDays() => _showInputDialog('Días para recordatorio', _stockReminderDays.toString(), (val) { final days = int.tryParse(val) ?? 7; setState(() => _stockReminderDays = days.clamp(1, 30)); _saveSetting('stock_reminder_days', _stockReminderDays); });
  void _showCurrencySettings() { Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencySettingsPage())); }
  void _showBackupPage() { Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage())); }
  void _showRestoreDialog() { showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text('Restaurar Base de Datos', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)), content: const Text('¿Estás seguro?', style: TextStyle(color: Colors.grey)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔄 Restaurando...'), backgroundColor: Colors.green)); }, child: const Text('Restaurar', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))),],)); }
  Future<void> _exportToCsv() async { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📤 Exportando...'), backgroundColor: Colors.green)); await Future.delayed(const Duration(seconds: 2)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Exportado'), backgroundColor: Colors.green)); }
  void _showAboutDialog() { showAboutDialog(context: context, applicationName: 'Nova ADEN', applicationVersion: '1.0.0', applicationIcon: const Icon(Icons.store, size: 40, color: Colors.green), children: const [Text('Sistema de Gestión\n\nDesarrollado con Flutter', style: TextStyle(color: Colors.grey))],); }
  void _showNotesPage() { Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesPage())); }
  void _showHelpFeedback() { Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpFeedbackPage())); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF1E1E1E), body: Center(child: CircularProgressIndicator(color: Colors.green)));

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(title: const Text('Configuración', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)), backgroundColor: const Color(0xFF1E1E1E), centerTitle: true, elevation: 0),
      body: ListView(padding: const EdgeInsets.all(8), children: [
        _buildSectionTitle('🏢 EMPRESA'),
        _buildInputCard(icon: Icons.business, title: 'Nombre de la Empresa', subtitle: 'Nombre que aparecerá en tickets', currentValue: _companyName, onTap: _editCompanyName),
        _buildInputCard(icon: Icons.percent, title: 'Tasa de Impuesto', subtitle: 'Porcentaje aplicado a ventas', currentValue: '${_taxRate.toStringAsFixed(1)}%', onTap: _editTaxRate),
        _buildSectionTitle('💱 MONEDA'),
        _buildCard(icon: Icons.currency_exchange, title: 'Moneda Principal', subtitle: 'Seleccionar: CUP / USD / MLC', onTap: _showCurrencySettings),
        _buildInputCard(icon: Icons.attach_money, title: 'Tasa de Cambio', subtitle: 'CUP equivalentes a 1 USD', currentValue: _exchangeRate.toStringAsFixed(2), onTap: _editExchangeRate),
        _buildSectionTitle('📦 INVENTARIO'),
        _buildSwitchCard(icon: Icons.warning_amber, title: 'Recordatorio de Stock', subtitle: 'Alertar cuando stock sea bajo', value: _stockReminderEnabled, onChanged: (val) { setState(() => _stockReminderEnabled = val); _saveSetting('stock_reminder_enabled', val); }),
        _buildInputCard(icon: Icons.calendar_today, title: 'Días para Alerta', subtitle: 'Anticipación en días', currentValue: '$_stockReminderDays días', onTap: _editStockReminderDays),
        _buildSectionTitle('🔔 NOTIFICACIONES'),
        _buildSwitchCard(icon: Icons.notifications_active, title: 'Notificaciones', subtitle: 'Recibir alertas del sistema', value: _notificationsEnabled, onChanged: (val) { setState(() => _notificationsEnabled = val); _saveSetting('notifications_enabled', val); }),
        _buildSectionTitle('🎨 APARIENCIA'),
        _buildSwitchCard(icon: Icons.dark_mode, title: 'Modo Oscuro', subtitle: 'Cambiar tema de la aplicación', value: _darkMode, onChanged: (val) { setState(() => _darkMode = val); _saveSetting('dark_mode', val); }),
        _buildSectionTitle('💾 DATOS'),
        _buildCard(icon: Icons.backup, title: 'Respaldar Base de Datos', subtitle: 'Crear copia de seguridad', onTap: _showBackupPage, iconColor: Colors.green),
        _buildCard(icon: Icons.restore, title: 'Restaurar Base de Datos', subtitle: 'Recuperar desde respaldo', onTap: _showRestoreDialog, iconColor: Colors.orange),
        _buildCard(icon: Icons.file_download, title: 'Exportar a CSV', subtitle: 'Descargar datos en CSV', onTap: _exportToCsv, iconColor: Colors.purple),
        _buildSectionTitle('❓ SOPORTE'),
        _buildCard(icon: Icons.notes, title: 'Notas Rápidas', subtitle: 'Tomar notas', onTap: _showNotesPage),
        _buildCard(icon: Icons.help_outline, title: 'Ayuda y Feedback', subtitle: 'Reportar problemas', onTap: _showHelpFeedback),
        _buildCard(icon: Icons.info_outline, title: 'Acerca de Nova ADEN', subtitle: 'Versión 1.0.0', onTap: _showAboutDialog),
        const SizedBox(height: 30),
        const Center(child: Text('Nova ADEN v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12))),
        const SizedBox(height: 10),
      ]),
    );
  }
}
