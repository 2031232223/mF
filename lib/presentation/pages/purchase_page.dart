import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/models/supplier.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/supplier_repository.dart';
import 'supplier_page.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  int? _selectedSupplierId;
  String? _selectedSupplierName;
  final ProductRepository _productRepo = ProductRepository();
  final SupplierRepository _supplierRepo = SupplierRepository();
  
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  final Map<int, Map<String, dynamic>> _cart = {};
  bool _isQuickPurchase = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _products = await _productRepo.getAllProducts();
    _suppliers = await _supplierRepo.getAllSuppliers();
    setState(() => _isLoading = false);
  }

  void _addToCart(Product product) {
    if (product.id == null) return;
    setState(() {
      _cart[product.id!] = {
        'cantidad': (_cart[product.id!]?['cantidad'] ?? 0) + 1,
        'costoUnitario': product.costo ?? product.precioVenta,
      };
    });
  }

  void _increaseQty(int productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!['cantidad'] = (_cart[productId]!['cantidad'] ?? 0) + 1;
      }
    });
  }

  void _decreaseQty(int productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!['cantidad'] = (_cart[productId]!['cantidad'] ?? 1) - 1;
        if (_cart[productId]!['cantidad'] <= 0) _cart.remove(productId);
      }
    });
  }

  double get _cartTotal {
    return _cart.values.fold(0.0, (sum, item) {
      return sum + (item['cantidad'] * item['costoUnitario']);
    });
  }

  Future<void> _confirmPurchase() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Agrega productos al carrito'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (!_isQuickPurchase && _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Selecciona un proveedor'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      
      final purchaseId = await db.insert('compras', {
        'proveedor_id': _isQuickPurchase ? null : _selectedSupplier?.id,
        'fecha': DateTime.now().toIso8601String(),
        'total': _cartTotal,
      });
      
      for (var entry in _cart.entries) {
        final productId = entry.key;
        final item = entry.value;
        final cantidad = item['cantidad'] as int;
        final costoUnitario = item['costoUnitario'] as double;
        
        await db.insert('compra_detalles', {
          'compra_id': purchaseId,
          'producto_id': productId,
          'cantidad': cantidad,
          'precio_unitario': costoUnitario,
          'subtotal': cantidad * costoUnitario,
        });
        
        await db.rawUpdate(
          'UPDATE productos SET stock_actual = stock_actual + ?, costo = ? WHERE id = ?',
          [cantidad, costoUnitario, productId],
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Compra registrada'), backgroundColor: Colors.green),
      );
      
      setState(() => _cart.clear());
      _loadData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Compra rápida:'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isQuickPurchase,
                            onChanged: (v) => setState(() => _isQuickPurchase = v),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SupplierPage()),
                          );
                          // ✅ RECARGAR PROVEEDORES después de crear uno nuevo
                          if (result != null && mounted) {
                            await _loadData();
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.add_business),
                        label: const Text('Nuevo'),
                      ),
                    ],
                  ),
                ),

                if (!_isQuickPurchase)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<Supplier?>(
                      decoration: InputDecoration(
                        labelText: 'Proveedor *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
                      ),
                      // ✅ Items del dropdown
                      items: [
                        const DropdownMenuItem<Supplier?>(
                          value: null,
                          child: Text('Seleccionar proveedor'),
                        ),
                        ..._suppliers.map((supplier) {
                          return DropdownMenuItem<Supplier?>(
                            value: supplier,
                            child: Text(supplier.nombre),
                          );
                        }).toList(),
                      ],
                      // ✅ Valor seleccionado
                      value: _selectedSupplier,
                      // ✅ onChanged corregido
                      onChanged: (Supplier? newSupplier) {
                        setState(() {
                          _selectedSupplier = newSupplier;
                        });
                      },
                      // ✅ Hint para modo oscuro
                      hint: Text(
                        'Seleccionar proveedor',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[500] 
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[500] 
                            : Colors.grey,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _products.where((p) => 
                      p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())
                    ).length,
                    itemBuilder: (ctx, i) {
                      final filtered = _products.where((p) => 
                        p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())
                      ).toList();
                      final product = filtered[i];
                      final inCart = _cart.containsKey(product.id);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: const Icon(Icons.inventory_2, color: Colors.white),
                          ),
                          title: Text(
                            product.nombre, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            'Costo: \$${(product.costo ?? 0).toStringAsFixed(2)} | Stock: ${product.stockActual}',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[400] 
                                  : Colors.black54,
                            ),
                          ),
                          trailing: inCart
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () => _decreaseQty(product.id!),
                                    ),
                                    Text('${_cart[product.id!]!['cantidad']}', 
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness == Brightness.dark 
                                            ? Colors.white 
                                            : Colors.black,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.green),
                                      onPressed: () => _increaseQty(product.id!),
                                    ),
                                  ],
                                )
                              : ElevatedButton(
                                  onPressed: () => _addToCart(product),
                                  child: const Text('Agregar'),
                                ),
                        ),
                      );
                    },
                  ),
                ),
                
                if (_cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF1E1E1E) 
                          : Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, -2))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_cart.length} productos', 
                              style: TextStyle(
                                fontSize: 14, 
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[400] 
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              'Total: \$${_cartTotal.toStringAsFixed(2)}', 
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold, 
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.green[300] 
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _confirmPurchase,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('CONFIRMAR COMPRA', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

  // ✅ SELECCIONAR PROVEEDOR
  Future<void> _showSupplierSelector() async {
    final suppliers = await _supplierRepo.getAllSuppliers();
    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No hay proveedores'), backgroundColor: Colors.orange),
      );
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Proveedor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suppliers.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(suppliers[i].nombre),
              subtitle: Text(suppliers[i].telefono ?? 'Sin teléfono'),
              onTap: () => Navigator.pop(ctx, suppliers[i].id),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () async { Navigator.pop(ctx); await _showNewSupplierDialog(); },
            icon: const Icon(Icons.add), label: const Text('Nuevo'),
          ),
        ],
      ),
    );
    if (selected != null) {
      final s = suppliers.firstWhere((x) => x.id == selected);
      setState(() { _selectedSupplierId = s.id; _selectedSupplierName = s.nombre; });
    }
  }

  // ✅ REGISTRAR NUEVO PROVEEDOR
  Future<void> _showNewSupplierDialog() async {
    final n = TextEditingController(), c = TextEditingController(), t = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Proveedor'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Nombre *')),
          TextField(controller: c, decoration: const InputDecoration(labelText: 'CI')),
          TextField(controller: t, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (n.text.trim().isEmpty) return;
              await _supplierRepo.createSupplier(nombre: n.text.trim(), ciIdentidad: c.text.trim().isEmpty ? null : c.text.trim(), telefono: t.text.trim().isEmpty ? null : t.text.trim());
              if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Registrado'), backgroundColor: Colors.green)); }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
