import 'package:flutter/material.dart';
import '../../core/models/supplier.dart';
import '../../core/repositories/supplier_repository.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});
  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> with SingleTickerProviderStateMixin {
  final _supplierRepo = SupplierRepository();
  List<Supplier> _suppliers = [];
  bool _isLoading = true;
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _nombreCtrl.dispose();
    _ciCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _suppliers = await _supplierRepo.getAllSuppliers();
    setState(() => _isLoading = false);
  }

  Future<void> _saveSupplier() async {
    if (_nombreCtrl.text.isEmpty || _ciCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Nombre y CI obligatorios')));
      return;
    }
    try {
      await _supplierRepo.createSupplier(Supplier(
        nombre: _nombreCtrl.text.trim(),
        ciIdentidad: _ciCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
      ));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Guardado en BD'), backgroundColor: Colors.green));
      _nombreCtrl.clear(); _ciCtrl.clear(); _telefonoCtrl.clear();
      _loadData();
      _tabController.animateTo(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteSupplier(Supplier s) async {
    if (await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Eliminar'), content: Text('¿Eliminar a ${s.nombre}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí'))],
    )) == true) {
      await _supplierRepo.deleteSupplier(s.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores'), centerTitle: true),
      body: Column(
        children: [
          TabBar(controller: _tabController, tabs: const [Tab(text: '📋 Lista'), Tab(text: '➕ Nuevo')]),
          Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(controller: _tabController, children: [_buildList(), _buildForm()])),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _tabController.animateTo(1), child: const Icon(Icons.add)),
    );
  }

  Widget _buildList() {
    final filtered = _suppliers.where((s) => s.nombre.toLowerCase().contains(_searchCtrl.text.toLowerCase())).toList();
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(hintText: 'Buscar...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100]),
          onChanged: (v) => setState(() {}),
        )),
        Expanded(child: filtered.isEmpty ? const Center(child: Text('Vacío')) : ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final s = filtered[i];
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.store)),
              title: Text(s.nombre), subtitle: Text('${s.ciIdentidad} • ${s.telefono}'),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSupplier(s)),
            ));
          },
        )),
      ],
    );
  }

  Widget _buildForm() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _nombreCtrl, decoration: InputDecoration(filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100], labelText: 'Nombre *', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: _ciCtrl, decoration: InputDecoration(filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100], labelText: 'Carnet de Identidad', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: _telefonoCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100], labelText: 'Teléfono', border: OutlineInputBorder())),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _saveSupplier, icon: const Icon(Icons.save), label: const Text('GUARDAR PROVEEDOR'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white))),
    ]));
  }
}
