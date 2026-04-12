import 'package:flutter/material.dart';
import '../../core/models/supplier.dart';
import '../../core/repositories/supplier_repository.dart';
import '../../core/database/database_helper.dart';

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

  // Formulario
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Complete campos obligatorios')));
      return;
    }
    try {
      final supplier = Supplier(
        nombre: _nombreCtrl.text.trim(),
        ciIdentidad: _ciCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
      );
      await _supplierRepo.createSupplier(supplier);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Proveedor registrado'), backgroundColor: Colors.green));
      _nombreCtrl.clear();
      _ciCtrl.clear();
      _telefonoCtrl.clear();
      _loadData();
      _tabController.animateTo(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Proveedor'),
        content: Text('¿Eliminar a ${supplier.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await _supplierRepo.deleteSupplier(supplier.id!);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Eliminado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '📋 Lista'), Tab(text: '➕ Nuevo')],
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [_buildListTab(), _buildFormTab()],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.animateTo(1),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListTab() {
    final filtered = _suppliers.where((s) => 
      s.nombre.toLowerCase().contains(_searchCtrl.text.toLowerCase())
    ).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar proveedor...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
              hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.grey),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No hay proveedores'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final s = filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.store, color: Colors.white)),
                        title: Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s.ciIdentidad} • ${s.telefono}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSupplier(s),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nombreCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre *',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
              hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ciCtrl,
            decoration: InputDecoration(
              labelText: 'Carnet de Identidad',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
              hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
              hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
            onPressed: _saveSupplier,
            icon: const Icon(Icons.save),
            label: const Text('GUARDAR PROVEEDOR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          )),
        ],
      ),
    );
  }
}
