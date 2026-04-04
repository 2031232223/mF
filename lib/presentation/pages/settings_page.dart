import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_settings_page.dart';
import 'backup_page.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool)? onToggleTheme;
  final bool isDark;
  const SettingsPage({super.key, this.onToggleTheme, required this.isDark});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _autoBackup = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Apariencia'),
          SwitchListTile(
            secondary: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
            title: const Text('Modo Oscuro', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Cambiar tema de la aplicación'),
            value: widget.isDark,
            onChanged: (value) {
              if (widget.onToggleTheme != null) {
                widget.onToggleTheme!(value);
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('General'),
          _buildSettingsTile(
            icon: Icons.currency_exchange,
            title: 'Monedas y Tasas',
            subtitle: 'Configurar CUP, MLC, USD',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencySettingsPage())),
          ),
          _buildSettingsTile(
            icon: Icons.backup,
            title: 'Respaldos',
            subtitle: 'Crear o restaurar copias',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage())),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: Colors.green),
            title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Alertas de stock bajo'),
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.backup_table, color: Colors.orange),
            title: const Text('Respaldo Automático', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Diario a las 23:59'),
            value: _autoBackup,
            onChanged: (value) => setState(() => _autoBackup = value),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Información'),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'Acerca de',
            subtitle: 'Versión 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova ADEN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Versión: 1.0.0'),
            const SizedBox(height: 8),
            const Text('Administrador de Negocio'),
            const SizedBox(height: 8),
            const Text('Desarrollado con Flutter & Dart'),
            const SizedBox(height: 16),
            const Text('© 2026 Todos los derechos reservados.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
