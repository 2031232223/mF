import 'package:flutter/material.dart';
import '../../core/models/supplier.dart';
import '../../core/repositories/supplier_repository.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _repo = SupplierRepository();
  List<Supplier> _suppliers = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _suppliers = await _repo.getAllSuppliers();
    setState(() => _loading = false);
  }

  Future<void> _deleteSupplier(int id) async {
    try {
      await _repo.deleteSupplier(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Proveedor eliminado'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSupplierForm({Supplier? supplier}) {
    final nombreCtrl = TextEditingController(text: supplier?.nombre ?? '');
    final contactoCtrl = TextEditingController(text: supplier?.contacto ?? '');
    final telefonoCtrl = TextEditingController(text: supplier?.telefono ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    supplier == null ? '➕ Nuevo Proveedor' : '✏️ Editar Proveedor',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactoCtrl,
                decoration: const InputDecoration(labelText: 'Contacto', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (nombreCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('⚠️ El nombre es requerido'), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    try {
                      final newSupplier = Supplier(
                        id: supplier?.id,
                        nombre: nombreCtrl.text.trim(),
                        contacto: contactoCtrl.text.trim(),
                        telefono: telefonoCtrl.text.trim(),
                      );
                      if (supplier == null) {
                        await _repo.createSupplier(newSupplier);
                      } else {
                        await _repo.updateSupplier(supplier.id!, newSupplier);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(supplier == null ? '✅ Proveedor creado' : '✅ Proveedor actualizado'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(ctx);
                        _load();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: Text(
                    supplier == null ? 'CREAR PROVEEDOR' : 'ACTUALIZAR PROVEEDOR',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedor...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _suppliers.where((s) => s.nombre.toLowerCase().contains(_search.text.toLowerCase())).length,
                    itemBuilder: (ctx, i) {
                      final s = _suppliers.where((sup) => sup.nombre.toLowerCase().contains(_search.text.toLowerCase())).toList()[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.brown, child: const Icon(Icons.business, color: Colors.white)),
                          title: Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.contacto != null && s.contacto!.isNotEmpty) Text('👤 ${s.contacto}'),
                              if (s.telefono != null && s.telefono!.isNotEmpty) Text('📞 ${s.telefono}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showSupplierForm(supplier: s)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSupplier(s.id!)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}
