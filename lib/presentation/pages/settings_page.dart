import 'package:flutter/material.dart';
import 'currency_settings_page.dart';
import 'backup_page.dart';
import 'notes_page.dart';
import 'help_feedback_page.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool)? onToggleTheme;
  final bool isDark;
  const SettingsPage({super.key, this.onToggleTheme, required this.isDark});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildSectionTitle('General'),
        _buildCard(icon: Icons.currency_exchange, title: 'Monedas y Tasas', subtitle: 'Configurar CUP, MLC, USD', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencySettingsPage()))),
        _buildCard(icon: Icons.backup, title: 'Respaldos', subtitle: 'Crear o restaurar copias', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage()))),
        _buildCard(icon: Icons.note, title: 'Notas Diarias', subtitle: 'Registrar notas del día', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesPage()))),
        const SizedBox(height: 24),
        _buildSectionTitle('Sistema'),
        SwitchListTile(secondary: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode), title: Text(widget.isDark ? 'Modo Claro' : 'Modo Oscuro'), subtitle: const Text('Cambiar tema'), value: widget.isDark, onChanged: (v) { if (widget.onToggleTheme != null) widget.onToggleTheme!(v); setState(() {}); }),
        SwitchListTile(secondary: const Icon(Icons.notifications), title: const Text('Notificaciones'), subtitle: const Text('Alertas de stock bajo'), value: true, onChanged: (v) {}),
        const SizedBox(height: 24),
        _buildCard(icon: Icons.help, title: 'Ayuda y Feedback', subtitle: 'Preguntas frecuentes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpFeedbackPage()))),
        _buildCard(icon: Icons.info, title: 'Acerca de', subtitle: 'Versión 1.0.0', onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Nova ADEN'), content: const Text('Administrador de Negocio\n© 2026 Todos los derechos reservados.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))]))),
      ]));
  }
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)));
  Widget _buildCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) => Card(elevation: 2, margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), child: Icon(icon, color: Theme.of(context).colorScheme.primary)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}
