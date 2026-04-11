import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/utils/csv_exporter.dart';
import 'package:file_picker/file_picker.dart';

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
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _products = await _repo.getAllProducts();
    setState(() => _loading = false);
    if (widget.onStatsChanged != null) widget.onStatsChanged!();
  }

  Future<void> _deleteProduct(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Eliminar este producto?'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Actualizar', onPressed: _load),
          IconButton(icon: const Icon(Icons.file_download), tooltip: 'Exportar CSV', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exportar: Función no implementada aún")))),
          IconButton(icon: const Icon(Icons.file_upload), tooltip: 'Importar CSV', onPressed: _importProductsCsv),
        ]
      ),
    );
    if (confirm == true) {
      await _repo.deleteProduct(id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Eliminado')));
    }
  }

  Future<void> _toggleActive(Product p) async {
    final updated = Product(
      id: p.id, nombre: p.nombre, codigo: p.codigo, costo: p.costo, precioVenta: p.precioVenta,
      stockActual: p.stockActual, stockMinimo: p.stockMinimo, categoria: p.categoria,
      esFavorito: p.esFavorito, stockCritico: p.stockCritico, margenGanancia: p.margenGanancia,
      unidadMedida: p.unidadMedida, activo: !p.activo, notas: p.notas,
    );
    await _repo.updateProduct(p.id!, updated);
    _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.activo ? '✅ Archivado' : '✅ Reactivado')));
  }

  // ✅ FUNCIÓN CORREGIDA Y AGREGADA AQUÍ
  Future<void> _toggleFavorite(Product p) async {
    final updated = Product(
      id: p.id, nombre: p.nombre, codigo: p.codigo, costo: p.costo, precioVenta: p.precioVenta,
      stockActual: p.stockActual, stockMinimo: p.stockMinimo, categoria: p.categoria,
      esFavorito: !p.esFavorito, stockCritico: p.stockCritico, margenGanancia: p.margenGanancia,
      unidadMedida: p.unidadMedida, activo: p.activo, notas: p.notas,
    );
    await _repo.updateProduct(p.id!, updated);
    _load();
  }

  Future<void> _duplicateProduct(Product p) async {
    try {
      final newProduct = Product(
        id: null, nombre: '${p.nombre} (Copia)', codigo: '${p.codigo}-COPY', costo: p.costo,
        precioVenta: p.precioVenta, stockActual: 0, stockMinimo: p.stockMinimo, categoria: p.categoria,
        esFavorito: false, stockCritico: p.stockCritico, margenGanancia: p.margenGanancia,
        unidadMedida: p.unidadMedida, activo: true, notas: p.notas,
      );
      await _repo.createProduct(newProduct);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Duplicado'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }

  Future<void> _importProductsCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.first.path!);
      final lines = await file.readAsLines();
      int imported = 0, errors = 0;
      for (var i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        try {
          final cols = lines[i].split(',');
          if (cols.length < 4) continue;
          final prod = Product(
            id: null,
            nombre: cols[0].replaceAll('"', '').trim(),
            codigo: cols[1].replaceAll('"', '').trim(),
            costo: double.tryParse(cols[2].replaceAll('"', '').trim()),
            precioVenta: double.tryParse(cols[3].replaceAll('"', '').trim()) ?? 0.0,
            stockActual: int.tryParse(cols[4].replaceAll('"', '').trim()) ?? 0,
            stockMinimo: int.tryParse(cols[5].replaceAll('"', '').trim()) ?? 5,
            categoria: cols.length > 6 ? cols[6].replaceAll('"', '').trim() : null,
            esFavorito: false, activo: true, unidadMedida: 'UND', notas: null, stockCritico: 0, margenGanancia: 0.0,
          );
          await _repo.createProduct(prod);
          imported++;
        } catch (e) { errors++; }
      }
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Importados: $imported | Errores: $errors'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showProductForm({Product? product}) {
    final nombreCtrl = TextEditingController(text: product?.nombre ?? '');
    final codigoCtrl = TextEditingController(text: product?.codigo ?? '');
    final precioCtrl = TextEditingController(text: product?.precioVenta.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stockActual.toString() ?? '0');
    final stockMinCtrl = TextEditingController(text: product?.stockMinimo.toString() ?? '5');
    final unidadCtrl = TextEditingController(text: product?.unidadMedida ?? 'UND');
    final costoCtrl = TextEditingController(text: product?.costo?.toString() ?? '');
    final categoriaCtrl = TextEditingController(text: product?.categoria ?? '');
    final notasCtrl = TextEditingController(text: product?.notas ?? '');

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(product == null ? 'Nuevo Producto' : 'Editar Producto', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: 'Nombre *', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100])),
                  const SizedBox(height: 12),
                  TextField(controller: codigoCtrl, decoration: InputDecoration(labelText: 'Código *', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100])),
                  const SizedBox(height: 12),
                  TextField(controller: categoriaCtrl, decoration: InputDecoration(labelText: 'Categoría', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100])),
                  const SizedBox(height: 12),
                  
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('💡 Sugerencia de Precio (Margen 30%)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Costo: \$${costoCtrl.text.isNotEmpty ? costoCtrl.text : '0.00'}'),
                            ElevatedButton(
                              onPressed: () {
                                final cost = double.tryParse(costoCtrl.text) ?? 0;
                                if (cost > 0) {
                                  final suggested = cost * 1.30; 
                                  // ✅ CORRECCIÓN: .text = en lugar de .setText()
                                  precioCtrl.text = suggested.toStringAsFixed(2);
                                  setModalState(() {});
                                }
                              },
                              child: const Text('Calcular'),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(child: TextField(controller: unidadCtrl, decoration: InputDecoration(labelText: 'Unidad Medida', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: stockMinCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Stock Mínimo', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: costoCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Costo', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: precioCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Precio Venta *', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]))),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Stock Actual', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100])),
                  const SizedBox(height: 16),
                  const Text('Notas adicionales:', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(controller: notasCtrl, maxLines: 2, decoration: InputDecoration(border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100])),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty || codigoCtrl.text.isEmpty || precioCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete campos obligatorios')));
                  return;
                }
                try {
                  final catVal = categoriaCtrl.text.trim().isNotEmpty ? categoriaCtrl.text.trim() : null;
                  final unitVal = unidadCtrl.text.trim().isNotEmpty ? unidadCtrl.text.trim() : 'UND';
                  final newProduct = Product(
                    id: product?.id,
                    nombre: nombreCtrl.text.trim(),
                    codigo: codigoCtrl.text.trim(),
                    costo: double.tryParse(costoCtrl.text),
                    precioVenta: double.parse(precioCtrl.text),
                    stockActual: int.tryParse(stockCtrl.text) ?? 0,
                    stockMinimo: int.tryParse(stockMinCtrl.text) ?? 5,
                    unidadMedida: unitVal,
                    categoria: catVal,
                    esFavorito: product?.esFavorito ?? false,
                    activo: product?.activo ?? true,
                    notas: notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                    stockCritico: product?.stockCritico ?? 0,
                    margenGanancia: product?.margenGanancia ?? 0.0,
                  );
                  if (product == null) await _repo.createProduct(newProduct);
                  else await _repo.updateProduct(product.id!, newProduct);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(product == null ? '✅ Creado' : '✅ Actualizado'), backgroundColor: Colors.green));
                    Navigator.pop(ctx);
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
                }
              },
              icon: const Icon(Icons.save),
              label: Text(product == null ? 'CREAR' : 'GUARDAR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _products.where((p) {
      if (!_showInactive && !p.activo) return false;
      return p.nombre.toLowerCase().contains(_search.text.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'), 
        centerTitle: true, 
        actions: [
          IconButton(icon: const Icon(Icons.archive), onPressed: () => setState(() => _showInactive = !_showInactive), tooltip: _showInactive ? 'Ocultar inactivos' : 'Mostrar inactivos'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(icon: const Icon(Icons.download), onPressed: () => CsvExporter.exportProducts(_products.map((p) => p.toMap()).toList()), tooltip: 'Exportar CSV'),
          IconButton(icon: const Icon(Icons.upload_file), onPressed: _importProductsCsv, tooltip: 'Importar CSV'),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showProductForm(), child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          controller: _search, 
          decoration: InputDecoration(
            hintText: 'Buscar...', 
            prefixIcon: const Icon(Icons.search), 
            border: const OutlineInputBorder(), 
            filled: true, 
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100]
          ),
          onChanged: (v) => setState(() {}),
        )),
        Expanded(
          child: filteredList.isEmpty ? Center(child: Text(_showInactive ? 'No hay productos' : 'No hay productos activos')) : ListView.builder(
            itemCount: filteredList.length, 
            itemBuilder: (ctx, i) {
              final p = filteredList[i];
              return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: ListTile(
                leading: CircleAvatar(backgroundColor: p.esFavorito ? Colors.amber : (p.activo ? Colors.blue : Colors.grey), child: Icon(p.esFavorito ? Icons.star : Icons.inventory_2, color: Colors.white)),
                title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, decoration: p.activo ? null : TextDecoration.lineThrough)),
                subtitle: Text('Stock: ${p.stockActual} ${p.unidadMedida} | \$${p.precioVenta.toStringAsFixed(2)}${!p.activo ? ' (Inactivo)' : ''}'),
                trailing: PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Editar')])),
                    const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy), SizedBox(width: 8), Text('Duplicar')])),
                    PopupMenuItem(value: 'active', child: Row(children: [Icon(p.activo ? Icons.archive : Icons.unarchive), SizedBox(width: 8), Text(p.activo ? 'Archivar' : 'Reactivar')])),
                    const PopupMenuItem(value: 'favorite', child: Row(children: [Icon(Icons.star_border), SizedBox(width: 8), Text('Favorito')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit': _showProductForm(product: p); break;
                      case 'duplicate': _duplicateProduct(p); break;
                      case 'active': _toggleActive(p); break;
                      case 'favorite': _toggleFavorite(p); break; // ✅ Ahora existe esta función
                      case 'delete': _deleteProduct(p.id!); break;
                    }
                  },
                ),
              ));
            },
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}
