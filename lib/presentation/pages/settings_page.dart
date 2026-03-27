import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import './currency_settings_page.dart';
import './stock_alerts_page.dart';
import './backup_page.dart';

class SettingsPage extends StatefulWidget {
  final Function()? onToggleTheme;
  final bool isDark;
  const SettingsPage({super.key, this.onToggleTheme, this.isDark = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🌙 Apariencia (Tema)
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.purple, child: const Icon(Icons.palette, color: Colors.white)),
              title: const Text('Apariencia', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(widget.isDark ? 'Modo oscuro activado' : 'Modo claro activado'),
              trailing: Switch(value: widget.isDark, onChanged: (_) => widget.onToggleTheme?.call()),
            ),
          ),
          const SizedBox(height: 12),
          
          // 💱 Moneda
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue, child: const Icon(Icons.attach_money, color: Colors.white)),
              title: const Text('Moneda', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Configurar CUP/MLC/USD'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencySettingsPage())),
            ),
          ),
          const SizedBox(height: 12),
          
          // 🔔 Alertas de Stock
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.orange, child: const Icon(Icons.warning_amber, color: Colors.white)),
              title: const Text('Alertas de Stock', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Configurar mínimos y críticos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockAlertsPage())),
            ),
          ),
          const SizedBox(height: 12),
          
          // 💾 Respaldos
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green, child: const Icon(Icons.backup, color: Colors.white)),
              title: const Text('Respaldos', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Crear y restaurar copias'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupPage())),
            ),
          ),
          const SizedBox(height: 12),
          
          // ℹ️ Acerca de
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.grey, child: const Icon(Icons.info, color: Colors.white)),
              title: const Text('Acerca de Nova ADEN', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Versión ${AppConstants.appVersion}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog(context: context, builder: (_) => const AboutDialog()),
            ),
          ),
        ],
      ),
    );
  }
}

// Diálogo Acerca de (Minimalista)
class AboutDialog extends StatelessWidget {
  const AboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova ADEN', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_bag, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text('Versión ${AppConstants.appVersion}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('🇨🇺 Desarrollado en Cuba'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}
