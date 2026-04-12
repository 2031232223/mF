import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/utils/theme_provider.dart';
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
  bool _showInactive = false;

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

  Future<void> _deleteProduct(int productId) async {
    try {
      await _productRepo.deleteProduct(productId);
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

  // ✅ FUNCIÓN DE EXPORTACIÓN PDF (MINIMAL Y SEGURA)
  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Nova ADEN - Inventario', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Código', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Precio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ]),
                  ..._products.take(50).map((p) => pw.TableRow(children: [
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(p.nombre)),
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(p.codigo)),
                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('\$${p.precioVenta.toStringAsFixed(2)}')),
                  ])),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('Total: ${_products.length} productos', style: pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/inventario_nova_aden.pdf');
      await file.writeAsBytes(await pdf.save());
      
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Inventario Nova ADEN');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ PDF exportado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Exportación: $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  // ✅ DIÁLOGO DE ELIMINACIÓN CON BOTONES SÍ/NO
  void _showDeleteConfirmation(int productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Eliminar "$productName"?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteProduct(productId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  void _showProductForm({Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    ).then((_) => _loadProducts());
  }

  void _toggleActive(Product product) async {
    await _productRepo.toggleActive(product.id!);
    _loadProducts();
  }

  void _toggleFavorite(Product product) async {
    await _productRepo.toggleFavorite(product.id!);
    _loadProducts();
  }

  void _duplicateProduct(Product product) {
    final newProduct = Product(
      nombre: '${product.nombre} (Copia)',
      codigo: '${product.codigo}_COPY',
      costo: product.costo,
      precioVenta: product.precioVenta,
      stockActual: 0,
      stockMinimo: product.stockMinimo,
      categoria: product.categoria,
      esFavorito: false,
      activo: true,
    );
    _showProductForm(product: newProduct);
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _products.where((p) {
      if (!_showInactive && !p.activo) return false;
      return p.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () => setState(() => _showInactive = !_showInactive),
            tooltip: _showInactive ? 'Ocultar inactivos' : 'Mostrar inactivos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToPDF,
            tooltip: 'Exportar PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(child: Text(_showInactive ? 'No hay productos' : 'No hay productos activos'))
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (ctx, i) {
                            final p = filteredList[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: p.esFavorito ? Colors.amber : (p.activo ? Colors.blue : Colors.grey),
                                  child: Icon(p.esFavorito ? Icons.star : Icons.inventory_2, color: Colors.white),
                                ),
                                title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, decoration: p.activo ? null : TextDecoration.lineThrough)),
                                subtitle: Text('Código: ${p.codigo} | \$${p.precioVenta.toStringAsFixed(2)} | Stock: ${p.stockActual}'),
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
                                    PopupMenuItem(value: 'active', child: Text(p.activo ? 'Desactivar' : 'Activar')),
                                    PopupMenuItem(value: 'favorite', child: Text(p.esFavorito ? 'Quitar favorito' : 'Marcar favorito')),
                                    const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                                  ],
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _showProductForm(product: p);
                                        break;
                                      case 'duplicate':
                                        _duplicateProduct(p);
                                        break;
                                      case 'active':
                                        _toggleActive(p);
                                        break;
                                      case 'favorite':
                                        _toggleFavorite(p);
                                        break;
                                      case 'delete':
                                        _showDeleteConfirmation(p.id!, p.nombre);
                                        break;
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
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
