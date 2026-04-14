import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final ProductRepository _productRepo = ProductRepository();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  List<String> _categories = ['Todos'];
  bool _showFavoritesOnly = false;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _products = await _productRepo.getAllProducts(onlyActive: !_showArchived);
      _categories = ['Todos', ...await _productRepo.getCategories()];
      _applyFilters();
    } catch (e) {
      print('Error cargando productos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((p) {
        if (_showFavoritesOnly && !p.esFavorito) return false;
        if (_selectedCategory != 'Todos' && p.categoria != _selectedCategory) return false;
        if (_searchQuery.isNotEmpty && 
            !p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !(p.codigo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'bulk') _showBulkPriceDialog();
              if (value == 'categories') _showCategoriesDialog();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'bulk', child: Text('📊 Cambio Masivo de Precios')),
              const PopupMenuItem(value: 'categories', child: Text('📁 Gestionar Categorías')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFilterBar(),
          
          // Lista de productos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('No hay productos'))
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (ctx, i) => _buildProductCard(_filteredProducts[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey[900] 
          : Colors.grey[100],
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) {
                    _selectedCategory = value!;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_showFavoritesOnly ? Icons.favorite : Icons.favorite_border),
                color: _showFavoritesOnly ? Colors.red : Colors.grey,
                onPressed: () {
                  _showFavoritesOnly = !_showFavoritesOnly;
                  _applyFilters();
                },
              ),
              IconButton(
                icon: Icon(_showArchived ? Icons.visibility_off : Icons.visibility),
                color: _showArchived ? Colors.orange : Colors.grey,
                onPressed: () {
                  _showArchived = !_showArchived;
                  _loadProducts();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.stockActual <= product.stockMinimo ? Colors.red : Colors.green,
          child: Text('${product.stockActual}', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(product.nombre)),
            if (product.esFavorito) const Icon(Icons.favorite, color: Colors.red, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categoría: ${product.categoria ?? "Sin categoría"}'),
            Text('\$${product.precioVenta.toStringAsFixed(2)} | Stock: ${product.stockActual} ${product.unidadMedida ?? "unid"}'),
            if (product.stockActual <= product.stockMinimo)
              const Text('⚠️ Stock bajo', style: TextStyle(color: Colors.red, fontSize: 11)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _showEditProductDialog(product);
            if (value == 'duplicate') _duplicateProduct(product);
            if (value == 'favorite') _toggleFavorite(product);
            if (value == 'archive') _archiveProduct(product);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('✏️ Editar')),
            const PopupMenuItem(value: 'duplicate', child: Text('📋 Duplicar')),
            PopupMenuItem(
              value: 'favorite',
              child: Text(product.esFavorito ? '💔 Quitar favorito' : '❤️ Marcar favorito'),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Text(product.estaActivo ? '📦 Archivar' : '♻️ Reactivar'),
            ),
          ],
        ),
      ),
    );
  }

  // RF 36: Diálogo de cambio masivo de precios
  void _showBulkPriceDialog() {
    final percentageCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String method = 'percentage';
    String scope = 'all';
    String selectedCategory = _categories.length > 1 ? _categories[1] : 'Todos';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cambio Masivo de Precios'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'percentage', label: Text('Porcentaje %')),
                    ButtonSegment(value: 'value', label: Text('Valor fijo \$')),
                  ],
                  selected: {method},
                  onSelectionChanged: (v) => setDialogState(() => method = v.first),
                ),
                const SizedBox(height: 16),
                if (method == 'percentage')
                  TextField(
                    controller: percentageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Porcentaje (%)', prefixText: '+/- '),
                  )
                else
                  TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor (\$)', prefixText: '+/- \$ '),
                  ),
                const SizedBox(height: 16),
                const Text('Aplicar a:'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Todos')),
                    ButtonSegment(value: 'category', label: Text('Categoría')),
                  ],
                  selected: {scope},
                  onSelectionChanged: (v) => setDialogState(() => scope = v.first),
                ),
                if (scope == 'category' && _categories.length > 1) ...[
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: _categories.where((c) => c != 'Todos').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setDialogState(() => selectedCategory = v!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  int affected = 0;
                  if (method == 'percentage') {
                    final percentage = double.tryParse(percentageCtrl.text) ?? 0;
                    affected = await _productRepo.bulkPriceUpdate(
                      percentage: percentage,
                      categoria: scope == 'category' ? selectedCategory : null,
                    );
                  } else {
                    final value = double.tryParse(valueCtrl.text) ?? 0;
                    affected = await _productRepo.bulkPriceUpdateByValue(value: value);
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ \$affected productos actualizados')),
                    );
                    _loadProducts();
                  }
                } catch (e) {
                  print('Error: $e');
                }
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  // RF 73: Duplicar producto
  Future<void> _duplicateProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicar Producto'),
        content: Text('¿Duplicar "${product.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Duplicar')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _productRepo.duplicateProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto duplicado')),
          );
          _loadProducts();
        }
      } catch (e) {
        print('Error duplicando: $e');
      }
    }
  }

  // RF 44: Toggle favorito
  Future<void> _toggleFavorite(Product product) async {
    try {
      await _productRepo.toggleFavorite(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(product.esFavorito ? '💔 Quitado de favoritos' : '❤️ Agregado a favoritos')),
        );
        _loadProducts();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // RF 74: Archivar producto
  Future<void> _archiveProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.estaActivo ? 'Archivar Producto' : 'Reactivar Producto'),
        content: Text(product.estaActivo 
            ? '¿Archivar "${product.nombre}"? No se mostrará en ventas.'
            : '¿Reactivar "${product.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(product.estaActivo ? 'Archivar' : 'Reactivar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (product.estaActivo) {
          await _productRepo.archiveProduct(product.id);
        } else {
          await _productRepo.unarchiveProduct(product.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(product.estaActivo ? '📦 Producto archivado' : '♻️ Producto reactivado')),
          );
          _loadProducts();
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  void _showAddProductDialog() {
    // Implementación similar a la página de productos existente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usa la página de Inventario para agregar productos')),
    );
  }

  void _showEditProductDialog(Product product) {
    // Implementación similar a la página de productos existente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usa la página de Inventario para editar productos')),
    );
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Categorías'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.where((c) => c != 'Todos').map((c) => ListTile(
            title: Text(c),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Implementar eliminación de categoría
              },
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
