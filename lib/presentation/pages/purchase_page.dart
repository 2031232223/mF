import 'package:flutter/material.dart';
import 'supplier_page.dart';
import 'package:intl/intl.dart';
import '../../core/models/product.dart';
import '../../core/models/supplier.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/supplier_repository.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});
  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final ProductRepository _productRepo = ProductRepository();
  final SupplierRepository _supplierRepo = SupplierRepository();
  
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  // Carrito: productId -> {cantidad, costoUnitario}
  final Map<int, Map<String, dynamic>> _cart = {};
  bool _isQuickPurchase = false; // RF 6: Compra rápida sin proveedor

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

  void _removeFromCart(int productId) {
    setState(() => _cart.remove(productId));
  }

  void _updateCost(int productId, double newCost) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!['costoUnitario'] = newCost;
      }
    });
  }

  double get _cartTotal {
    return _cart.values.fold(0.0, (sum, item) {
      return sum + (item['cantidad'] * item['costoUnitario']);
    });
  }

  // RF 50: Calcular costo promedio ponderado
  double _calculateWeightedAverageCost(int productId, double newCost, int newQty) {
    final product = _products.firstWhere((p) => p.id == productId, orElse: () => _products.first);
    final currentStock = product.stockActual;
    final currentCost = product.costo ?? 0.0;
    
    if (currentStock == 0) return newCost;
    
    final totalCost = (currentCost * currentStock) + (newCost * newQty);
    final totalQty = currentStock + newQty;
    return totalCost / totalQty;
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
      
      // RF 7/10: Registrar compra
      final purchaseId = await db.insert('compras', {
        'proveedor_id': _isQuickPurchase ? null : _selectedSupplier?.id,
        'fecha': DateTime.now().toIso8601String(),
        'total': _cartTotal,
      });
      
      // RF 8/9/10: Procesar líneas y actualizar stock + costo promedio (RF 50)
      for (var entry in _cart.entries) {
        final productId = entry.key;
        final item = entry.value;
        final cantidad = item['cantidad'] as int;
        final costoUnitario = item['costoUnitario'] as double;
        
        // Insertar línea de compra
        await db.insert('compra_detalles', {
          'compra_id': purchaseId,
          'producto_id': productId,
          'cantidad': cantidad,
          'costo_unitario': costoUnitario,
          'subtotal': cantidad * costoUnitario,
        });
        
        // RF 50: Actualizar producto con costo promedio ponderado
        final newAvgCost = _calculateWeightedAverageCost(productId, costoUnitario, cantidad);
        await db.rawUpdate(
          'UPDATE productos SET stock_actual = stock_actual + ?, costo = ? WHERE id = ?',
          [cantidad, newAvgCost, productId],
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Compra registrada y stock actualizado'), backgroundColor: Colors.green),
      );
      
      // Limpiar carrito y recargar
      setState(() => _cart.clear());
      _loadData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPurchaseHistory() async {
    final db = await DatabaseHelper.instance.database;
    final purchases = await db.rawQuery('''
      SELECT c.id, c.fecha, c.total, p.nombre as proveedor
      FROM compras c
      LEFT JOIN proveedores p ON c.proveedor_id = p.id
      ORDER BY c.fecha DESC
    ''');
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📋 Historial de Compras'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: purchases.isEmpty
              ? const Center(child: Text('Sin compras registradas'))
              : ListView.builder(
                  itemCount: purchases.length,
                  itemBuilder: (ctx, i) {
                    final p = purchases[i];
                    return ListTile(
                      title: Text('Compra #${p['id']}'),
                      subtitle: Text('${p['proveedor'] ?? 'Rápida'} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(p['fecha'] as String))}'),
                      trailing: Text('\$${(p['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => _showPurchaseDetails(p['id'] as int),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _showPurchaseDetails(int purchaseId) async {
    final db = await DatabaseHelper.instance.database;
    final details = await db.rawQuery('''
      SELECT cd.*, pr.nombre as producto
      FROM compra_detalles cd
      JOIN productos pr ON cd.producto_id = pr.id
      WHERE cd.compra_id = ?
    ''', [purchaseId]);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalle de Compra'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: details.length,
            itemBuilder: (ctx, i) {
              final d = details[i];
              return ListTile(
                title: Text(d['producto'] as String),
                subtitle: Text('${d['cantidad']} un. x \$${(d['costo_unitario'] as num).toStringAsFixed(2)}'),
                trailing: Text('\$${(d['subtotal'] as num).toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showPurchaseHistory, // RF 11: Listar compras
            tooltip: 'Historial',
          ),
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
               // RF 6: Toggle compra rápida
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Row(
                       children: [
                         const Text('Compra rápida (sin proveedor):'),
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
                         if (result != null && mounted) {
                           setState(() {
                             _suppliers.add(result);
                             _selectedSupplier = result;
                           });
                         }
                       },
                       icon: const Icon(Icons.add_business),
                       label: const Text('Nuevo'),
                     ),
                   ],
                 ),
               ),

               // Selector de proveedor (solo si no es compra rápida)
               if (!_isQuickPurchase)
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   child: DropdownButtonFormField<Supplier>(
                     decoration: InputDecoration(
                       labelText: 'Proveedor *',
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                       filled: true,
                       fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
                     ),
                     items: [
                       const DropdownMenuItem(value: null, child: Text('Seleccionar proveedor')),
                       ..._suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.nombre))),
                     ],
                     value: _selectedSupplier,
                     onChanged: (v) => setState(() => _selectedSupplier = v),
                   ),
                 ),

               const SizedBox(height: 16),

               // Buscador de productos
                // Buscador de productos
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
                      hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.grey),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lista de productos
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
                          title: Text(product.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Costo: \$${(product.costo ?? 0).toStringAsFixed(2)} | Stock: ${product.stockActual}'),
                          trailing: inCart
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () => _decreaseQty(product.id!),
                                    ),
                                    Text('${_cart[product.id!]!['cantidad']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                
                // Footer con carrito y confirmar
                if (_cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, -2))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_cart.length} productos', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('Total: \$${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _confirmPurchase, // RF 10: Confirmar compra
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
