import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/models/customer.dart';
import '../../core/models/sale.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/customer_repository.dart';
import '../../core/repositories/sale_repository.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final ProductRepository _productRepo = ProductRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final SaleRepository _saleRepo = SaleRepository();
  
  List<CartItem> _cart = [];
  List<Product> _products = [];
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _products = await _productRepo.getAllProducts();
    _customers = await _customerRepo.getAllCustomers();
    setState(() => _isLoading = false);
  }

  void _addToCart(Product product) {
    if (product.stockActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Sin stock disponible'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      final existing = _cart.indexWhere((c) => c.productoId == product.id);
      if (existing >= 0) {
        if (_cart[existing].cantidad < product.stockActual) {
          _cart[existing].cantidad++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ No hay más stock disponible'), backgroundColor: Colors.orange),
          );
        }
      } else {
        _cart.add(CartItem(
          productoId: product.id!,
          nombre: product.nombre,
          precio: product.precioVenta,
          cantidad: 1,
          stockDisponible: product.stockActual,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${product.nombre} agregado al carrito'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _increaseQuantity(int index) {
    if (index >= 0 && index < _cart.length) {
      final item = _cart[index];
      if (item.cantidad < item.stockDisponible) {
        setState(() => item.cantidad++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Stock máximo alcanzado'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _decreaseQuantity(int index) {
    if (index >= 0 && index < _cart.length) {
      setState(() {
        _cart[index].cantidad--;
        if (_cart[index].cantidad <= 0) {
          _cart.removeAt(index);
        }
      });
    }
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Carrito vacío'), backgroundColor: Colors.orange),
      );
      return;
    }

    final lines = _cart.map((c) => SaleLine(
      ventaId: 0,
      productoId: c.productoId,
      cantidad: c.cantidad,
      precioUnitario: c.precio,
      subtotal: c.subtotal,
    )).toList();

    try {
      await _saleRepo.createSale(_selectedCustomer?.id, lines);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Venta de \$${_total.toStringAsFixed(2)} realizada con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      _clearCart();
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  double get _total => _cart.fold(0.0, (sum, c) => sum + c.subtotal);

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🛒 Carrito',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cliente:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _showCustomerDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Nuevo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Customer>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Cliente General')),
                      ..._customers.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))),
                    ],
                    value: _selectedCustomer,
                    onChanged: (v) => setState(() => _selectedCustomer = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _cart.isEmpty
                  ? const Center(child: Text('El carrito está vacío', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _cart.length,
                      itemBuilder: (ctx, i) {
                        final c = _cart[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text('${c.cantidad}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('\$${c.precio.toStringAsFixed(2)} c/u'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _decreaseQuantity(i),
                                ),
                                Text('${c.cantidad}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => _increaseQuantity(i),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeFromCart(i),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _cart.isEmpty ? null : _completeSale,
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text('CONFIRMAR VENTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDialog() {
    final nombreController = TextEditingController();
    final ciController = TextEditingController();
    final telefonoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreController, decoration: InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: ciController, decoration: InputDecoration(labelText: 'Carnet de Identidad *', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: telefonoController, decoration: InputDecoration(labelText: 'Teléfono *', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isNotEmpty && ciController.text.isNotEmpty && telefonoController.text.isNotEmpty) {
                final customer = Customer(
                  nombre: nombreController.text.trim(),
                  carnetIdentidad: ciController.text.trim(),
                  telefono: telefonoController.text.trim(),
                );
                try {
                  await _customerRepo.createCustomer(customer);
                  await _loadData();
                  setState(() => _selectedCustomer = _customers.firstWhere((c) => c.carnetIdentidad == ciController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Cliente registrado'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Complete todos los campos'), backgroundColor: Colors.orange),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          if (_cart.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearCart),
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
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _products.where((p) => p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).length,
                    itemBuilder: (ctx, i) {
                      final p = _products.where((prod) => prod.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).toList()[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.stockActual > 0 ? Colors.blue : Colors.grey,
                            child: Icon(Icons.inventory_2, color: Colors.white),
                          ),
                          title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stock: ${p.stockActual}'),
                              Text('\$${p.precioVenta.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: p.stockActual > 0 ? () => _addToCart(p) : null,
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
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, -2))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_cart.length} productos', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              Text(
                                'Total: \$${_total.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _showCartBottomSheet,
                            icon: const Icon(Icons.shopping_cart, size: 20),
                            label: const Text('VER CARRITO', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class CartItem {
  final int productoId;
  final String nombre;
  final double precio;
  int cantidad;
  final int stockDisponible;
  CartItem({required this.productoId, required this.nombre, required this.precio, required this.cantidad, required this.stockDisponible});
  double get subtotal => precio * cantidad;
}
