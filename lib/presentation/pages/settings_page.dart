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
  String _language = 'Español';

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
          _buildSwitchTile(
            icon: widget.isDark ? Icons.light_mode : Icons.dark_mode,
            title: widget.isDark ? 'Modo Claro' : 'Modo Oscuro',
            subtitle: 'Cambiar tema de la aplicación',
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
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Notificaciones',
            subtitle: 'Alertas de stock bajo',
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
          ),
          _buildSwitchTile(
            icon: Icons.backup_table,
            title: 'Respaldo Automático',
            subtitle: 'Diario a las 23:59',
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
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
            const Text('Sistema de Gestión Comercial'),
            const SizedBox(height: 8),
            const Text('Desarrollado con Flutter & Dart'),
            const SizedBox(height: 16),
            const Text('© 2024 Todos los derechos reservados.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
