import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/database/database_helper.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedType = 'sugerencia';
  String _email = '';

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Escribe tu mensaje'), backgroundColor: Colors.black),
      );
      return;
    }

    try {
      // Guardar feedback localmente
      final db = await DatabaseHelper.instance.database;
      await db.insert('config', {
        'key': 'feedback_${DateTime.now().millisecondsSinceEpoch}',
        'value': {
          'type': _selectedType,
          'message': _feedbackController.text,
          'email': _email,
          'date': DateTime.now().toIso8601String(),
        }.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Opción: Abrir cliente de email
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'soporte@novaaden.com',
        query: 'subject=Feedback Nova ADEN - $_selectedType&body=${_feedbackController.text}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Feedback enviado'), backgroundColor: Colors.black),
        );
        _feedbackController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y Feedback'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RF 80: Ayuda contextual
            _buildHelpSection(),
            const SizedBox(height: 24),
            
            // RF 79: Enviar feedback
            _buildFeedbackSection(),
            const SizedBox(height: 24),
            
            // Información de la app
            _buildAppInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 8),
                const Text('Ayuda Contextual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            
            _buildHelpItem(
              Icons.point_of_sale,
              'Punto de Venta',
              'Agrega productos al carrito, selecciona cliente, y confirma la venta. Usa el escáner para códigos de barras.',
            ),
            _buildHelpItem(
              Icons.inventory_2,
              'Inventario',
              'Gestiona productos, categorías, stock. Puedes duplicar, archivar y marcar favoritos.',
            ),
            _buildHelpItem(
              Icons.shopping_cart,
              'Compras',
              'Registra entradas de productos con o sin proveedor. Actualiza stock y costo promedio.',
            ),
            _buildHelpItem(
              Icons.bar_chart,
              'Reportes',
              'Visualiza ventas, márgenes, rotación de productos y flujo de caja con gráficos.',
            ),
            _buildHelpItem(
              Icons.settings,
              'Configuración',
              'Personaliza moneda, impuestos, alertas de stock, respaldos y notas diarias.',
            ),
            
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showQuickTips(),
              icon: const Icon(Icons.lightbulb),
              label: const Text('Ver Consejos Rápidos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.feedback, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 8),
                const Text('Enviar Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            
            const Text('Tipo de mensaje:'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sugerencia', label: Text('💡 Sugerencia')),
                ButtonSegment(value: 'error', label: Text('🐛 Error')),
                ButtonSegment(value: 'consulta', label: Text('❓ Consulta')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (v) => setState(() => _selectedType = v.first),
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje aquí...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.message),
              ),
            ),
            
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => _email = v,
              decoration: InputDecoration(
                hintText: 'Tu email (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _sendFeedback,
                icon: const Icon(Icons.send),
                label: const Text('ENVIAR FEEDBACK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Información de la App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildInfoRow('Versión', '1.0.0'),
            _buildInfoRow('Base de Datos', 'SQLite v6'),
            _buildInfoRow('Autor', '2031232223'),
            _buildInfoRow('Año', '2026'),
            const SizedBox(height: 16),
            const Text(
              '© 2026 Nova ADEN. Todos los derechos reservados.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showQuickTips() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('💡 Consejos Rápidos'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Usa el escáner de código de barras para ventas rápidas'),
              SizedBox(height: 8),
              Text('• Marca productos favoritos para acceso rápido'),
              SizedBox(height: 8),
              Text('• Configura alertas de stock para no quedarte sin productos'),
              SizedBox(height: 8),
              Text('• Haz respaldos manuales antes de operaciones grandes'),
              SizedBox(height: 8),
              Text('• Usa ventas fiadas para clientes de confianza'),
              SizedBox(height: 8),
              Text('• Revisa los reportes de margen para optimizar precios'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }
}
