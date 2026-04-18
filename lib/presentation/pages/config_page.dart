import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  bool _isDarkMode = false;
  String _companyName = 'Nova ADEN';
  String _taxRate = '0.0';
  String _currency = 'CUP';
  String _exchangeRate = '1.00';
  bool _stockAlert = false;
  int _alertDays = 7;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final config = await db.query('config');
      if (mounted) {
        setState(() {
          _companyName = config.firstWhere((c) => c['key'] == 'nombre_empresa', orElse: () => {'value': 'Nova ADEN'})['value'].toString();
          _taxRate = config.firstWhere((c) => c['key'] == 'tasa_impuesto', orElse: () => {'value': '0.0'})['value'].toString();
          _currency = config.firstWhere((c) => c['key'] == 'moneda_principal', orElse: () => {'value': 'CUP'})['value'].toString();
          _exchangeRate = config.firstWhere((c) => c['key'] == 'tasa_cambio', orElse: () => {'value': '1.00'})['value'].toString();
          _stockAlert = config.firstWhere((c) => c['key'] == 'alerta_stock', orElse: () => {'value': '0'})['value'] == '1';
          _alertDays = int.tryParse(config.firstWhere((c) => c['key'] == 'dias_alerta', orElse: () => {'value': '7'})['value'].toString()) ?? 7;
        });
      }
    } catch (e) {
      print('Error loading config: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tema Claro/Oscuro
            _buildSection('🎨 APARIENCIA', isDark),
            _buildTile(
              icon: isDark ? Icons.dark_mode : Icons.light_mode,
              title: 'Modo Oscuro',
              subtitle: isDark ? 'Tema oscuro activado' : 'Tema claro activado',
              isDark: isDark,
              trailing: Switch(
                value: _isDarkMode,
                activeColor: Colors.blue,
                onChanged: (v) {
                  setState(() => _isDarkMode = v);
                  // Aquí iría la lógica para cambiar el tema global
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(v ? 'Modo oscuro activado' : 'Modo claro activado')),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Empresa
            _buildSection('🏢 EMPRESA', isDark),
            _buildEditableTile('Nombre de la Empresa', _companyName, isDark, (v) => _companyName = v),
            _buildEditableTile('Tasa de Impuesto (%)', _taxRate, isDark, (v) => _taxRate = v, keyboardType: TextInputType.number),
            
            const SizedBox(height: 24),
            
            // Moneda
            _buildSection('💵 MONEDA', isDark),
            _buildDropdownTile('Moneda Principal', _currency, ['CUP', 'USD', 'MLC'], isDark, (v) => _currency = v!),
            _buildEditableTile('Tasa de Cambio', _exchangeRate, isDark, (v) => _exchangeRate = v, keyboardType: TextInputType.number),
            
            const SizedBox(height: 24),
            
            // Inventario
            _buildSection('📦 INVENTARIO', isDark),
            _buildTile(
              icon: Icons.warning,
              title: 'Recordatorio de Stock',
              subtitle: 'Alertar cuando stock sea bajo',
              isDark: isDark,
              trailing: Switch(
                value: _stockAlert,
                activeColor: Colors.orange,
                onChanged: (v) => setState(() => _stockAlert = v),
              ),
            ),
            _buildEditableTile('Días para Alerta', '$_alertDays', isDark, (v) => _alertDays = int.tryParse(v) ?? 7, keyboardType: TextInputType.number),
            
            const SizedBox(height: 24),
            
            // Acerca de
            _buildSection('ℹ️ ACERCA DE', isDark),
            _buildInfoTile('Versión', '1.0.0', isDark),
            _buildInfoTile('Desarrollador', 'Nova ADEN Team', isDark),
            _buildInfoTile('Año', '2026', isDark),
            
            const SizedBox(height: 32),
            
            // Botón Guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('GUARDAR CONFIGURACIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _saveConfig,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String title, required String subtitle, required bool isDark, Widget? trailing}) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
        trailing: trailing,
      ),
    );
  }

  Widget _buildEditableTile(String title, String value, bool isDark, Function(String) onChanged, {TextInputType? keyboardType}) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.edit, color: Colors.blue),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: TextField(
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: value,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTile(String title, String value, List<String> options, bool isDark, Function(String?) onChanged) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.blue),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
        trailing: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? Colors.grey[900] : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, bool isDark) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.info, color: Colors.blue),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        trailing: Text(value, style: TextStyle(color: Colors.grey[400])),
      ),
    );
  }

  Future<void> _saveConfig() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('config', {'value': _companyName}, where: "key = 'nombre_empresa'");
      await db.update('config', {'value': _taxRate}, where: "key = 'tasa_impuesto'");
      await db.update('config', {'value': _currency}, where: "key = 'moneda_principal'");
      await db.update('config', {'value': _exchangeRate}, where: "key = 'tasa_cambio'");
      await db.update('config', {'value': _stockAlert ? '1' : '0'}, where: "key = 'alerta_stock'");
      await db.update('config', {'value': '$_alertDays'}, where: "key = 'dias_alerta'");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Configuración guardada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
