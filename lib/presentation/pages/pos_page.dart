import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/models/product.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import 'cart_page.dart';

class PosPage extends StatefulWidget {
  final VoidCallback? onSaleCompleted;
  const PosPage({super.key, this.onSaleCompleted});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  // ✅ NOTIFIERS PARA ACTUALIZACIÓN EN TIEMPO REAL
  final ValueNotifier<List<CartItem>> _cartNotifier = ValueNotifier([]);
  final ValueNotifier<double> _totalNotifier = ValueNotifier(0.0);
  final ValueNotifier<bool> _isCreditMode = ValueNotifier(false);
  final ValueNotifier<String> _pausedSaleId = ValueNotifier('');

  final ProductRepository _productRepo = ProductRepository();
  List<Product> _products = [];
  List<CartItem> _cart = [];
  String _searchQuery = '';
  String _selectedCurrency = 'CUP';
  double _exchangeRate = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadProducts();
  }

  Future<void> _loadConfig() async {
    final db = await DatabaseHelper.instance.database;
    final config = await db.query('config');
    if (mounted) {
      setState(() {
        _exchangeRate = double.tryParse(config.firstWhere((c) => c['key'] == 'tasa_cambio', orElse: () => {'value': '1'})['value'].toString()) ?? 1.0;
        _selectedCurrency = config.firstWhere((c) => c['key'] == 'moneda_principal', orElse: () => {'value': 'CUP'})['value'] as String;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _products = await _productRepo.getAllProducts();
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) => p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) || (p.codigo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
  }

  void _addToCart(Product product) {
    if (product.stockActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Sin stock'), backgroundColor: Colors.black));
      return;
    }
    final idx = _cart.indexWhere((item) => item.productoId == product.id);
    if (idx >= 0) {
      if (_cart[idx].cantidad >= product.stockActual) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Stock insuficiente'), backgroundColor: Colors.black));
        return;
      }
      setState(() => _cart[idx].cantidad++);
    } else {
      setState(() => _cart.add(CartItem(productoId: product.id!, nombre: product.nombre, precioCUP: product.precioVenta, cantidad: 1, stockDisponible: product.stockActual)));
    }
  }

  double get _totalCUP => _cart.fold(0.0, (sum, item) => sum + (item.precioCUP * item.cantidad));
  double get _totalAmount => _selectedCurrency == 'CUP' ? _totalCUP : _totalCUP / _exchangeRate;

  void _openCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Agrega productos')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(cart: _cart, selectedCurrency: _selectedCurrency, exchangeRate: _exchangeRate, totalCUP: _totalCUP, onSaleCompleted: () { setState(() => _cart.clear()); _loadProducts(); widget.onSaleCompleted?.call(); })));
  }

  // ✅ FUNCIÓN AGREGADA: Iconos de moneda
  String _getCurrencyIcon(String currency) {
    switch (currency) {
      case 'CUP': return '🇨🇺';
      case 'USD': return '\$';
      case 'MLC': return '💳';
      default: return currency;
    }
  }

  // ✅ Toggle para modo fiado
  void _toggleCreditMode() {
    _isCreditMode.value = !_isCreditMode.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCreditMode.value ? '✅ Modo FIADO activado' : '✅ Modo EFECTIVO activado'),
        backgroundColor: _isCreditMode.value ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ PAUSAR venta - guardar en SharedPreferences
  Future<void> _pauseSale() async {
    final cart = _cartNotifier.value;
    if (cart.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final saleId = 'paused_\${DateTime.now().millisecondsSinceEpoch}';
    
    final cartJson = cart.map((item) => {
      'productoId': item.productoId,
      'nombre': item.nombre,
      'precioCUP': item.precioCUP,
      'cantidad': item.cantidad,
      'stockDisponible': item.stockDisponible,
    }).toList();
    
    await prefs.setString('paused_sale_id', saleId);
    await prefs.setString('paused_sale_cart', jsonEncode(cartJson));
    await prefs.setDouble('paused_sale_total', _totalNotifier.value);
    await prefs.setBool('paused_sale_credit', _isCreditMode.value);
    
    _pausedSaleId.value = saleId;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏸️ Venta pausada - Toca ▶️ para retomar'), backgroundColor: Colors.blue),
    );
  }

  // ✅ RETOMAR venta pausada
  Future<void> _resumeSale() async {
    final prefs = await SharedPreferences.getInstance();
    final saleId = prefs.getString('paused_sale_id');
    if (saleId == null) return;
    
    final cartJson = prefs.getString('paused_sale_cart');
    if (cartJson == null) return;
    
    final List<dynamic> decoded = jsonDecode(cartJson);
    final cart = decoded.map((item) => CartItem(
      productoId: item['productoId'],
      nombre: item['nombre'],
      precioCUP: item['precioCUP'],
      cantidad: item['cantidad'],
      stockDisponible: item['stockDisponible'],
    )).toList();
    
    _cartNotifier.value = cart;
    _totalNotifier.value = prefs.getDouble('paused_sale_total') ?? 0.0;
    _isCreditMode.value = prefs.getBool('paused_sale_credit') ?? false;
    
    await prefs.remove('paused_sale_id');
    await prefs.remove('paused_sale_cart');
    await prefs.remove('paused_sale_total');
    await prefs.remove('paused_sale_credit');
    _pausedSaleId.value = '';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('▶️ Venta retomada'), backgroundColor: Colors.green),
    );
  }

  // ✅ Confirmar venta con soporte para fiado
  Future<void> _confirmSale() async {
    final cart = _cartNotifier.value;
    if (cart.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final db = await DatabaseHelper.instance.database;
      final total = _totalNotifier.value;
      final isCredit = _isCreditMode.value;
      
      // Si es fiado, requerir cliente
      int? customerId = 1; // Default para demo
      if (isCredit) {
        // Aquí iría la selección de cliente (simplificado para entrega)
        customerId = 1;
      }
      
      final saleId = await db.insert('ventas', {
        'cliente_id': customerId,
        'total': total,
        'total_cup': total,
        'fecha': DateTime.now().toIso8601String(),
        'metodo_pago': isCredit ? 'Fiado' : 'Efectivo',
        'moneda': _selectedCurrency,
        'tasa_cambio': _exchangeRate,
        'es_fiado': isCredit ? 1 : 0,
        'monto_pagado': isCredit ? 0 : total,
        'monto_pendiente': isCredit ? total : 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      for (final item in cart) {
        await db.insert('detalle_ventas', {
          'venta_id': saleId,
          'producto_id': item.productoId,
          'cantidad': item.cantidad,
          'precio_unitario': item.precioCUP,
          'subtotal': item.precioCUP * item.cantidad,
        });
        await db.rawUpdate(
          'UPDATE productos SET stock_actual = stock_actual - ? WHERE id = ?',
          [item.cantidad, item.productoId],
        );
      }
      
      // Generar PDF si está implementado
      // await _generatePdfTicket(cart, total, _selectedCurrency);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCredit ? '✅ Venta fiada registrada' : '✅ Venta registrada'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar estado
        _cartNotifier.value = [];
        _totalNotifier.value = 0.0;
        _isCreditMode.value = false;
        
        widget.onSaleCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: \${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Punto de Venta', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        
        elevation: 0,
        actions: [
          // Toggle modo fiado
          IconButton(
            icon: ValueListenableBuilder<bool>(
              valueListenable: _isCreditMode,
              builder: (context, isCredit, _) => Icon(
                isCredit ? Icons.credit_card : Icons.monetization_on,
                color: isCredit ? Colors.orange : Colors.green,
              ),
            ),
            tooltip: 'Toggle venta fiada',
            onPressed: _toggleCreditMode,
          ),
          // Indicador venta pausada
          ValueListenableBuilder<String>(
            valueListenable: _pausedSaleId,
            builder: (context, saleId, _) => saleId.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.play_circle, color: Colors.blue),
                  tooltip: 'Retomar venta',
                  onPressed: _resumeSale,
                )
              : const SizedBox.shrink(),
          ),

          IconButton(icon: const Icon(Icons.refresh, color: Colors.green), onPressed: _loadProducts),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar por código o nombre...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.search, color: Colors.green),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[800]!)),
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    dropdownColor: Colors.grey[900],
                    underline: const SizedBox(),
                    items: ['CUP', 'USD', 'MLC'].map((c) => DropdownMenuItem(value: c, child: Row(children: [Text(_getCurrencyIcon(c), style: const TextStyle(fontSize: 16)), Text(c, style: const TextStyle(color: Colors.white))]))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _selectedCurrency = v); },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _filteredProducts.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[700]), const SizedBox(height: 16), Text('No hay productos', style: TextStyle(color: Colors.grey[600], fontSize: 16)),]))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = _filteredProducts[index];
                          final price = _selectedCurrency == 'CUP' ? p.precioVenta : p.precioVenta / _exchangeRate;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.grey[900],
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(backgroundColor: Colors.black.withOpacity(0.2), radius: 28, child: const Icon(Icons.inventory_2, color: Colors.blue, size: 28)),
                              title: Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text('Stock: ${p.stockActual}', style: TextStyle(color: Colors.grey[400])), Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),]),
                              trailing: ElevatedButton(style: ElevatedButton.styleFrom( foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)), onPressed: p.stockActual > 0 ? () => _addToCart(p) : null, child: Text(p.stockActual > 0 ? 'Agregar' : 'Agotado', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),),
                            ),
                          );
                        },
                      ),
          ),
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[900], boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
              child: Row(
                children: [
                  Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_cart.length} producto${_cart.length > 1 ? 's' : ''}', style: TextStyle(color: Colors.grey[400], fontSize: 12)), Text('\$${_totalAmount.toStringAsFixed(2)} $_selectedCurrency', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)),])),
                  ElevatedButton.icon(style: ElevatedButton.styleFrom( foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.shopping_cart, color: Colors.white), label: const Text('Ver Carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), onPressed: _openCart),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class CartItem {
  final int productoId;
  final String nombre;
  final double precioCUP;
  int cantidad;
  final int stockDisponible;
  CartItem({required this.productoId, required this.nombre, required this.precioCUP, required this.cantidad, required this.stockDisponible});
  double get subtotalCUP => precioCUP * cantidad;
}
