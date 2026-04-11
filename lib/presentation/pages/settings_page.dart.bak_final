import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/utils/theme_provider.dart';
import 'currency_settings_page.dart';
import 'backup_page.dart';
import 'notes_page.dart';
import 'help_feedback_page.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => Scaffold(
        appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSwitchCard(
              icon: theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              title: theme.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
              subtitle: 'Cambia entre temas instantáneamente',
              value: theme.isDarkMode,
              onChanged: (_) => theme.toggleTheme(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'General'),
            _buildSettingsCard(
              context: context,
              icon: Icons.currency_exchange,
              title: 'Monedas y Tasas',
              subtitle: 'Configurar CUP, MLC, USD',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencySettingsPage())),
            ),
            _buildSettingsCard(
              context: context,
              icon: Icons.backup,
              title: 'Respaldos',
              subtitle: 'Crear o restaurar copias',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage())),
            ),
            _buildSettingsCard(
              context: context,
              icon: Icons.note,
              title: 'Notas Diarias',
              subtitle: 'Registrar notas del día',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesPage())),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Reportes y Operaciones'),
            _buildInputCard(
              context: context,
              icon: Icons.title,
              title: 'Cabecera de Reportes',
              subtitle: 'Texto que aparece en reportes',
              hintText: 'Ej: Mi Negocio S.A.',
              initialValue: 'Nova ADEN - Reporte',
              onChanged: (v) {},
            ),
            const SizedBox(height: 12),
            _buildNumberCard(
              context: context,
              icon: Icons.percent,
              title: 'Impuesto %',
              subtitle: 'Impuesto básico para ventas',
              suffix: '%',
              initialValue: '0.0',
              onChanged: (v) {},
            ),
            const SizedBox(height: 12),
            _buildNumberCard(
              context: context,
              icon: Icons.lock,
              title: 'Bloquear operaciones >',
              subtitle: 'Días para bloquear edición',
              suffix: 'días',
              initialValue: '30',
              onChanged: (v) {},
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Inventario'),
            _buildNumberCard(
              context: context,
              icon: Icons.warning,
              title: 'Alerta de Stock Crítico',
              subtitle: 'Alertar cuando stock <= valor',
              suffix: 'unid.',
              initialValue: '5',
              onChanged: (v) {},
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Sistema'),
            _buildSwitchCard(
              icon: Icons.notifications,
              title: 'Notificaciones',
              subtitle: 'Alertas de stock bajo',
              value: true,
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            _buildSettingsCard(
              context: context,
              icon: Icons.help,
              title: 'Ayuda y Feedback',
              subtitle: 'Preguntas frecuentes y sugerencias',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpFeedbackPage())),
            ),
            _buildSettingsCard(
              context: context,
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
    );
  }

  Widget _buildSettingsCard({required BuildContext context, required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ));
  }

  Widget _buildInputCard({required BuildContext context, required IconData icon, required String title, required String subtitle, required String hintText, required String initialValue, required ValueChanged<String> onChanged}) {
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), child: Icon(icon, color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12))]))]),
      const SizedBox(height: 12),
      TextField(decoration: InputDecoration(hintText: hintText, border: const OutlineInputBorder()), controller: TextEditingController(text: initialValue), onChanged: onChanged),
    ])));
  }

  Widget _buildNumberCard({required BuildContext context, required IconData icon, required String title, required String subtitle, required String suffix, required String initialValue, required ValueChanged<String> onChanged}) {
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
      SizedBox(width: 100, child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(suffixText: suffix, border: const OutlineInputBorder()), controller: TextEditingController(text: initialValue), onChanged: onChanged)),
    ])));
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
  // RF 68: Recordatorios de stock
  bool _recordatorioStock = false;
  int _diasRecordatorio = 7;
  // RF 65: Impuestos
  double _impuestoPredeterminado = 0.0;
  // RF 66: Cabecera
  TextEditingController _nombreEmpresaCtrl = TextEditingController();
}
