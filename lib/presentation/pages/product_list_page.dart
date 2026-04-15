import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    try {
      setState(() => _isLoading = true);
      _products = await _productRepo.getAllProducts();
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Error: $e'), backgroundColor: Colors.black),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await _productRepo.deleteProduct(productId);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Producto eliminado'), backgroundColor: Colors.black),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
        );
      }
    }
  }

  void _showDeleteConfirmation(int productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Eliminar "$productName"?'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _productRepo.deleteProduct(productId);
                  Navigator.pop(ctx);
                },
                child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final filteredList = _products.where((p) {
      return p.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return Scaffold(backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Inventario'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
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
                      ? const Center(child: Text('No hay productos'))
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (ctx, i) {
                            final p = filteredList[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.black,
                                  child: const Icon(Icons.inventory_2, color: Colors.white),
                                ),
                                title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Código: ${p.codigo} | \$${p.precioVenta.toStringAsFixed(2)}'),
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                    const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showProductForm(product: p);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(p.id!, p.nombre);
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
