import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/utils/csv_exporter.dart';

class ProductListPage extends StatefulWidget {
  final VoidCallback? onStatsChanged;
  const ProductListPage({super.key, this.onStatsChanged});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _repo = ProductRepository();
  List<Product> _products = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _products = await _repo.getAllProducts();
    setState(() => _loading = false);
  }

  Future<void> _deleteProduct(int id) async {
    bool? confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmar Eliminación'),
      content: const Text('¿Está seguro que desea eliminar este producto?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
      ],
    ));
    if (confirm == true) {
      await _repo.deleteProduct(id);
      _load();
      if (widget.onStatsChanged != null) widget.onStatsChanged!();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Eliminado')));
    }
  }

  Future<void> _toggleFavorite(Product p) async {
    final updated = Product(id: p.id, nombre: p.nombre, codigo: p.codigo, costo: p.costo, precioVenta: p.precioVenta, stockActual: p.stockActual, stockMinimo: p.stockMinimo, categoria: p.categoria, esFavorito: !p.esFavorito, stockCritico: p.stockCritico, margenGanancia: p.margenGanancia, unidadMedida: p.unidadMedida, activo: p.activo, notas: p.notas);
    await _repo.updateProduct(p.id!, updated);
    _load();
  }

  void _showProductForm({Product? product}) {
    final nombreCtrl = TextEditingController(text: product?.nombre ?? '');
    final codigoCtrl = TextEditingController(text: product?.codigo ?? '');
    final precioCtrl = TextEditingController(text: product?.precioVenta.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stockActual.toString() ?? '0');
    final stockMinCtrl = TextEditingController(text: product?.stockMinimo.toString() ?? '5');
    final unidadCtrl = TextEditingController(text: product?.unidadMedida ?? 'UND');
    final costoCtrl = TextEditingController(text: product?.costo?.toString() ?? '');
    
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (context, setModalState) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(product == null ? 'Nuevo Producto' : 'Editar Producto', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]),
        const Divider(),
        TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: 'Nombre *', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100])),
        const SizedBox(height: 12),
        TextField(controller: codigoCtrl, decoration: InputDecoration(labelText: 'Código *', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100])),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: unidadCtrl, decoration: InputDecoration(labelText: 'Unidad Medida', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: stockMinCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Stock Mínimo', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: costoCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Costo', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: precioCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Precio Venta *', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Stock Actual', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100])),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () async {
          if (nombreCtrl.text.isEmpty || codigoCtrl.text.isEmpty || precioCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete campos obligatorios'))); return; }
          try {
            final newProduct = Product(id: product?.id, nombre: nombreCtrl.text.trim(), codigo: codigoCtrl.text.trim(), costo: double.tryParse(costoCtrl.text), precioVenta: double.parse(precioCtrl.text), stockActual: int.tryParse(stockCtrl.text) ?? 0, stockMinimo: int.tryParse(stockMinCtrl.text) ?? 5, unidadMedida: unidadCtrl.text.trim().isEmpty ? 'UND' : unidadCtrl.text.trim(), esFavorito: product?.esFavorito ?? false, activo: product?.activo ?? true);
            if (product == null) await _repo.createProduct(newProduct); else await _repo.updateProduct(product.id!, newProduct);
            if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(product == null ? '✅ Creado' : '✅ Actualizado'), backgroundColor: Colors.green)); Navigator.pop(ctx); _load(); if (widget.onStatsChanged != null) widget.onStatsChanged!(); }
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'))); }
        }, icon: const Icon(Icons.save), label: Text(product == null ? 'CREAR' : 'GUARDAR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white))),
      ]),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _products.where((p) => p.nombre.toLowerCase().contains(_search.text.toLowerCase())).toList();
    return Scaffold(appBar: AppBar(title: const Text('Inventario'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      floatingActionButton: FloatingActionButton(onPressed: () => _showProductForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _search, decoration: InputDecoration(hintText: 'Buscar...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]), onChanged: (v) => setState(() {}))),
        Expanded(child: filteredList.isEmpty ? const Center(child: Text('No hay productos registrados')) : ListView.builder(itemCount: filteredList.length, itemBuilder: (ctx, i) {
          final p = filteredList[i];
          return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: ListTile(
            leading: CircleAvatar(backgroundColor: p.esFavorito ? Colors.amber : Colors.blue, child: Icon(p.esFavorito ? Icons.star : Icons.inventory_2, color: Colors.white)),
            title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Stock: ${p.stockActual} ${p.unidadMedida} | \$${p.precioVenta.toStringAsFixed(2)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(p.esFavorito ? Icons.star : Icons.star_border, color: p.esFavorito ? Colors.amber : Colors.grey), onPressed: () => _toggleFavorite(p)),
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showProductForm(product: p)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(p.id!)),
            ]),
          ));
        })),
      ]),
    );
  }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
}
