import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/utils/pdf_generator.dart';
import 'product_form_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _productRepo = ProductRepository();
  List<Product> _products = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    _products = await _productRepo.getAllProducts();
    setState(() => _isLoading = false);
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await _productRepo.deleteProduct(product.id!);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Producto eliminado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ NUEVA FUNCIÓN DE EXPORTACIÓN A PDF
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Nova ADEN - Inventario de Productos', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Código', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Stock', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Precio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ]),
                  ..._products.map((p) => pw.TableRow(children: [
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(p.nombre)),
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(p.codigo)),
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(p.stockActual.toString())),
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('\$${p.precioVenta.toStringAsFixed(2)}')),
                  ])),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final file = File('$path/inventario_nova_aden.pdf');
      await file.writeAsBytes(await pdf.save());
      
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Inventario Nova ADEN');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ PDF exportado y compartido'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al exportar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ DIÁLOGO DE ELIMINACIÓN CORREGIDO (SÍ/NO)
  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Eliminar este producto?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportToPDF),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No hay productos registrados'))
                    : ListView.builder(
                        itemCount: _products.where((p) => p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).length,
                        itemBuilder: (ctx, i) {
                          final filtered = _products.where((p) => p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                          final p = filtered[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: p.stockActual > 0 ? Colors.blue : Colors.grey,
                                child: Icon(Icons.inventory_2, color: Colors.white),
                              ),
                              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Stock: ${p.stockActual} UND | \$${p.precioVenta.toStringAsFixed(2)}'),
                              trailing: PopupMenuButton(
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormPage(product: p))).then((_) => _loadProducts());
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(p);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormPage())).then((_) => _loadProducts()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
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
