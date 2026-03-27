import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ProductRepository _repo = ProductRepository();
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _costoController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _stockMinController = TextEditingController();
  final _unidadController = TextEditingController();
  
  Product? _editingProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _codigoController.dispose();
    _costoController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _stockMinController.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    _products = await _repo.getAllProducts();
    _filtered = _products;
    setState(() => _isLoading = false);
  }

  void _filterProducts(String query) {
    setState(() {
      _filtered = _products.where((p) => 
        p.nombre.toLowerCase().contains(query.toLowerCase()) ||
        p.codigo.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  void _clearForm() {
    _nombreController.clear();
    _codigoController.clear();
    _costoController.clear();
    _precioController.clear();
    _stockController.clear();
    _stockMinController.text = '5';
    _unidadController.clear();
    _editingProduct = null;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: _editingProduct?.id,
      nombre: _nombreController.text.trim(),
      codigo: _codigoController.text.trim(),
      costo: double.parse(_costoController.text),
      precioVenta: double.parse(_precioController.text),
      stockActual: int.parse(_stockController.text),
      stockMinimo: int.parse(_stockMinController.text),
      unidadMedida: _unidadController.text.trim(),
    );

    try {
      if (_editingProduct != null) {
        await _repo.updateProduct(_editingProduct!.id!, product);
        _showMessage('✅ Producto actualizado');
      } else {
        await _repo.createProduct(product);
        _showMessage('✅ Producto creado');
      }
      _clearForm();
      _loadProducts();
      Navigator.pop(context);
    } catch (e) {
      _showMessage('❌ Error: $e');
    }
  }

  void _editProduct(Product p) {
    _editingProduct = p;
    _nombreController.text = p.nombre;
    _codigoController.text = p.codigo;
    _costoController.text = p.costo.toString();
    _precioController.text = p.precioVenta.toString();
    _stockController.text = p.stockActual.toString();
    _stockMinController.text = p.stockMinimo.toString();
    _unidadController.text = p.unidadMedida;
    _showFormDialog();
  }

  void _deleteProduct(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Seguro que deseas eliminar "${p.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.deleteProduct(p.id!);
        _showMessage('✅ Producto eliminado');
        _loadProducts();
      } catch (e) {
        _showMessage('❌ Error: $e');
      }
    }
  }

  void _showMessage(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_editingProduct != null ? 'Editar Producto' : 'Nuevo Producto'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _codigoController, decoration: const InputDecoration(labelText: 'Código *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextFormField(controller: _costoController, decoration: const InputDecoration(labelText: 'Costo *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _precioController, decoration: const InputDecoration(labelText: 'Precio Venta *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextFormField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock Actual *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _stockMinController, decoration: const InputDecoration(labelText: 'Stock Mínimo', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextFormField(controller: _unidadController, decoration: const InputDecoration(labelText: 'Unidad Medida', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () { _clearForm(); Navigator.pop(ctx); }, child: const Text('Cancelar')),
          ElevatedButton(onPressed: _saveProduct, child: Text(_editingProduct != null ? 'Actualizar' : 'Guardar')),
        ],
      ),
    );
  }

  List<Product> get _lowStock => _products.where((p) => p.stockActual <= p.stockMinimo).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () async {
            try {
              final products = await ProductRepository().getAllProducts();
              final path = await CsvExporter.exportProducts(products.map((p) => p.toMap()).toList());
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Exportado: $path"), backgroundColor: Colors.green, duration: const Duration(seconds: 5)));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ $e"), backgroundColor: Colors.red));
            }
          }, tooltip: "Exportar a CSV"),
        ],
        title: const Text('Productos'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.warning), onPressed: () => _showLowStock()),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Buscar por nombre o código...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: _filterProducts,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('No hay productos registrados'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = _filtered[i];
                        final lowStock = p.stockActual <= p.stockMinimo;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: lowStock ? Colors.orange : Colors.blue,
                              child: Icon(Icons.inventory_2, color: Colors.white),
                            ),
                            title: Text(p.nombre),
                            subtitle: Text('Código: ${p.codigo} | Stock: ${p.stockActual} | \$${p.precioVenta}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editProduct(p)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(p)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  void _showLowStock() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Stock Bajo'),
        content: SizedBox(
          width: double.maxFinite,
          child: _lowStock.isEmpty
              ? const Text('✅ Todos los productos tienen stock suficiente')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _lowStock.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(_lowStock[i].nombre),
                    subtitle: Text('Stock: ${_lowStock[i].stockActual} / Mín: ${_lowStock[i].stockMinimo}'),
                  ),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }
}
