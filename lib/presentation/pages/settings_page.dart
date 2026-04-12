import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/utils/theme_provider.dart';
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
  // Variables funcionales
  String _companyName = '';
  double _taxRate = 0.0;
  bool _stockReminderEnabled = false;
  int _stockReminderDays = 7;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  // Cargar TODAS las configuraciones automáticamente
  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyName = prefs.getString('company_name') ?? 'Nova ADEN';
      _taxRate = prefs.getDouble('tax_rate') ?? 0.0;
      _stockReminderEnabled = prefs.getBool('stock_reminder_enabled') ?? false;
      _stockReminderDays = prefs.getInt('stock_reminder_days') ?? 7;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  // Guardar configuración automáticamente
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    _loadAllSettings(); // Recargar para actualizar UI
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => Scaffold(
        appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // MODO CLARO/OSCURO
            _buildSwitchCard(
              icon: theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              title: theme.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
              subtitle: 'Cambia entre temas instantáneamente',
              value: theme.isDarkMode,
              onChanged: (_) => theme.toggleTheme(),
            ),
            const SizedBox(height: 24),
            
            // SECCIÓN GENERAL
            _buildSectionTitle('General'),
            _buildSettingsCard(
              icon: Icons.business,
              title: 'Nombre de empresa',
              subtitle: _companyName.isEmpty ? 'Sin configurar' : _companyName,
              onTap: () => _editCompanyName(),
            ),
            _buildSettingsCard(
              icon: Icons.currency_exchange,
              title: 'Monedas y Tasas',
              subtitle: 'Configurar CUP, MLC, USD',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencySettingsPage())),
            ),
            _buildSettingsCard(
              icon: Icons.backup,
              title: 'Respaldos',
              subtitle: 'Crear o restaurar copias',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage())),
            ),
            _buildSettingsCard(
              icon: Icons.note,
              title: 'Notas Diarias',
              subtitle: 'Registrar notas del día',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesPage())),
            ),
            const SizedBox(height: 24),
            
            // SECCIÓN REPORTES Y OPERACIONES
            _buildSectionTitle('Reportes y Operaciones'),
            _buildInputCard(
              icon: Icons.title,
              title: 'Cabecera de Reportes',
              subtitle: 'Texto que aparece en reportes',
              hintText: 'Ej: Mi Negocio S.A.',
              initialValue: 'Nova ADEN - Reporte',
              onSave: (v) {},
            ),
            const SizedBox(height: 12),
            _buildNumberCard(
              icon: Icons.percent,
              title: 'Impuesto %',
              subtitle: 'Impuesto básico para ventas',
              suffix: '%',
              initialValue: _taxRate.toStringAsFixed(1),
              onSave: (v) => _saveSetting('tax_rate', double.tryParse(v) ?? 0.0),
            ),
            const SizedBox(height: 12),
            _buildNumberCard(
              icon: Icons.lock,
              title: 'Bloquear operaciones >',
              subtitle: 'Días para bloquear edición',
              suffix: 'días',
              initialValue: '30',
              onSave: (v) {},
            ),
            const SizedBox(height: 24),
            
            // SECCIÓN INVENTARIO
            _buildSectionTitle('Inventario'),
            _buildNumberCard(
              icon: Icons.warning,
              title: 'Alerta de Stock Crítico',
              subtitle: 'Alertar cuando stock <= valor',
              suffix: 'unid.',
              initialValue: '5',
              onSave: (v) {},
            ),
            const SizedBox(height: 12),
            _buildSwitchCard(
              icon: Icons.inventory_2,
              title: 'Recordatorios de stock',
              subtitle: 'Cada $_stockReminderDays días',
              value: _stockReminderEnabled,
              onChanged: (v) {
                _saveSetting('stock_reminder_enabled', v);
                if (v == true) _showReminderFrequencyDialog();
              },
            ),
            const SizedBox(height: 24),
            
            // SECCIÓN SISTEMA
            _buildSectionTitle('Sistema'),
            _buildSwitchCard(
              icon: Icons.notifications_active,
              title: 'Notificaciones',
              subtitle: 'Alertas de stock bajo',
              value: _notificationsEnabled,
              onChanged: (v) => _saveSetting('notifications_enabled', v),
            ),
            const SizedBox(height: 24),
            _buildSettingsCard(
              icon: Icons.help,
              title: 'Ayuda y Feedback',
              subtitle: 'Preguntas frecuentes y sugerencias',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpFeedbackPage())),
            ),
            _buildSettingsCard(
              icon: Icons.info,
              title: 'Acerca de',
              subtitle: 'Versión 1.0.0',
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGETS AUXILIARES ==========
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSettingsCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ));
  }

  Widget _buildSwitchCard({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool?> onChanged}) {
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 8), child: SwitchListTile(
      secondary: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    ));
  }

  Widget _buildInputCard({required IconData icon, required String title, required String subtitle, required String hintText, required String initialValue, required Function(String) onSave}) {
    final controller = TextEditingController(text: initialValue);
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12))]))]),
      const SizedBox(height: 12),
      TextField(decoration: InputDecoration(hintText: hintText, border: const OutlineInputBorder()), controller: controller, onChanged: onSave),
    ])));
  }

  Widget _buildNumberCard({required IconData icon, required String title, required String subtitle, required String suffix, required String initialValue, required Function(String) onSave}) {
    final controller = TextEditingController(text: initialValue);
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
      SizedBox(width: 100, child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(suffixText: suffix, border: const OutlineInputBorder()), controller: controller, onChanged: onSave)),
    ])));
  }

  // ========== FUNCIONES FUNCIONALES ==========
  void _editCompanyName() {
    final controller = TextEditingController(text: _companyName);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Nombre de empresa'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Ej: Mi Empresa S.A.'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () { Navigator.pop(context); _saveSetting('company_name', controller.text.trim()); }, child: const Text('Guardar')),
      ],
    ));
  }

  void _showReminderFrequencyDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Frecuencia de Recordatorio'),
      content: DropdownButton<int>(
        value: _stockReminderDays,
        isExpanded: true,
        items: [3, 7, 15, 30].map((d) => DropdownMenuItem(value: d, child: Text('$d días'))).toList(),
        onChanged: (newDays) {
          _saveSetting('stock_reminder_days', newDays ?? 7);
          Navigator.pop(context);
        },
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    ));
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Nova ADEN'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Versión: 1.0.0'),
        const SizedBox(height: 8),
        const Text('Administrador de Negocios'),
        const SizedBox(height: 8),
        const Text('Desarrollado con Flutter & Dart'),
        const SizedBox(height: 16),
        const Text('© 2026 Todos los derechos reservados.'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
    ));
  }
}
