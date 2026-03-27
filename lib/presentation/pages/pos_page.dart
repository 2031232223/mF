import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../../core/models/product.dart';
import '../../core/models/customer.dart';
import '../../core/models/sale.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/customer_repository.dart';
import '../../core/repositories/sale_repository.dart';
import 'paused_sales_page.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});
  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _productRepo = ProductRepository();
  final _customerRepo = CustomerRepository();
  final _saleRepo = SaleRepository();
  
  List<CartItem> _cart = [];
  List<Product> _products = [];
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  
  // Pago
  double _amountPaid = 0.0;
  String _selectedCurrency = 'CUP';
  
  // RF 56-58: Fiado
  bool _isCredit = false;
  String _creditNotes = '';
  
  // RF 17: Descuento global
  bool _applyDiscount = false;
  double _discountPercent = 0.0;
  
  final _pauseNameController = TextEditingController();
  final _amountPaidController = TextEditingController();

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
        const SnackBar(content: Text('❌ Sin stock'), backgroundColor: Colors.red, duration: Duration(seconds: 1)),
      );
      return;
    }
    setState(() {
      final existing = _cart.indexWhere((c) => c.productoId == product.id);
      if (existing >= 0) {
        if (_cart[existing].cantidad < product.stockActual) {
          _cart[existing].cantidad++;
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
  }

  void _increaseQuantity(int index) {
    if (index >= 0 && index < _cart.length) {
      final item = _cart[index];
      final product = _products.firstWhere((p) => p.id == item.productoId);
      if (item.cantidad < product.stockActual) {
        setState(() => item.cantidad++);
      }
    }
  }

  void _decreaseQuantity(int index) {
    if (index >= 0 && index < _cart.length) {
      setState(() {
        _cart[index].cantidad--;
        if (_cart[index].cantidad <= 0) _cart.removeAt(index);
      });
    }
  }

  void _removeFromCart(int index) => setState(() => _cart.removeAt(index));
  void _clearCart() => setState(() => _cart.clear());
  
  // Cálculos
  double get _subtotal => _cart.fold(0.0, (sum, c) => sum + c.subtotal);
  double get _discountAmount => _applyDiscount ? _subtotal * (_discountPercent / 100) : 0.0;
  double get _total => _subtotal - _discountAmount;
  double get _change => _isCredit ? 0.0 : _amountPaid - _total;

  Future<void> _pauseSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Agrega productos'), backgroundColor: Colors.orange),
      );
      return;
    }
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⏸️ Pausar Venta'),
        content: TextField(
          controller: _pauseNameController,
          decoration: const InputDecoration(labelText: 'Nombre (ej: Mesa 1)', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(_pauseNameController.text),
            child: const Text('Pausar'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.insert('ventas_pausadas', {
          'nombre': name,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'cliente_id': _selectedCustomer?.id,
          'productos': jsonEncode(_cart.map((c) => c.toMap()).toList()),
          'total': _total,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Venta pausada'), backgroundColor: Colors.green),
        );
        _clearCart();
        _pauseNameController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _resumeSale() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PausedSalesPage()));
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _cart = (jsonDecode(result['productos'] as String) as List).map((p) => CartItem.fromMap(p)).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Venta retomada'), backgroundColor: Colors.green),
      );
    }
  }

  // RF 52: Teclado numérico OPTIMIZADO
  void _showNumericKeypad() {
    double tempAmount = _amountPaid;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💵 Ingresar Monto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('\$ ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(tempAmount.toStringAsFixed(2), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
                children: [
                  for (var i = 1; i <= 9; i++)
                    ElevatedButton(
                      onPressed: () {
                        tempAmount = double.parse('${(tempAmount * 100).toInt()}$i') / 100;
                        setModalState(() {});
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                      child: Text('$i', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      tempAmount = 0;
                      setModalState(() {});
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100], padding: const EdgeInsets.all(20)),
                    child: const Text('C', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      tempAmount = double.parse('${(tempAmount * 100).toInt()}0') / 100;
                      setModalState(() {});
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                    child: const Text('0', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (tempAmount > 0) {
                        tempAmount = (tempAmount * 100).toInt() ~/ 10 / 100;
                        setModalState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[100], padding: const EdgeInsets.all(20)),
                    child: const Text('⌫', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _amountPaid = tempAmount);
                    _amountPaidController.text = _amountPaid.toStringAsFixed(2);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Text('LISTO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Carrito vacío'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!_isCredit && _amountPaid < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Pago insuficiente. Faltan \$${(_total - _amountPaid).toStringAsFixed(2)}'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final lines = _cart.map((c) => SaleLine(
        ventaId: 0,
        productoId: c.productoId,
        cantidad: c.cantidad,
        precioUnitario: c.precio,
        subtotal: c.subtotal,
      )).toList();

      await _saleRepo.createSale(
        _selectedCustomer?.id,
        lines,
        _total,
        _isCredit ? _amountPaid : _total,
        _isCredit ? (_total - _amountPaid) : 0.0,
        _creditNotes,
        _selectedCurrency,
        1.0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Venta: \$${_total.toStringAsFixed(2)}'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
      );
      
      _clearCart();
      _amountPaid = 0.0;
      _amountPaidController.clear();
      _isCredit = false;
      _creditNotes = '';
      _applyDiscount = false;
      _discountPercent = 0.0;
      _loadData();
      
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    }
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🛒 Carrito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Cliente
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
                                  onPressed: () => _showNewCustomerDialog(setModalState),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Nuevo'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Customer>(
                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Cliente General')),
                                ..._customers.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))),
                              ],
                              value: _selectedCustomer,
                              onChanged: (v) => setModalState(() => _selectedCustomer = v),
                            ),
                          ],
                        ),
                      ),
                      
                      // Productos en carrito
                      if (_cart.isEmpty)
                        const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Carrito vacío', style: TextStyle(fontSize: 16, color: Colors.grey))))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _cart.length,
                          itemBuilder: (ctx, i) {
                            final c = _cart[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: Colors.blue, child: Text('${c.cantidad}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('\$${c.precio.toStringAsFixed(2)} c/u'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 28), onPressed: () { _decreaseQuantity(i); setModalState(() {}); }),
                                    Text('${c.cantidad}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    IconButton(icon: const Icon(Icons.add_circle, color: Colors.green, size: 28), onPressed: () { _increaseQuantity(i); setModalState(() {}); }),
                                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () { _removeFromCart(i); setModalState(() {}); }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      
                      // RF 17: Descuento global
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: Colors.purple[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('💲 Descuento Global', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Switch(
                                      value: _applyDiscount,
                                      onChanged: (v) {
                                        setModalState(() => _applyDiscount = v);
                                        setState(() => _applyDiscount = v);
                                      },
                                    ),
                                  ],
                                ),
                                if (_applyDiscount) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text('Porcentaje: '),
                                      Expanded(
                                        child: Slider(
                                          value: _discountPercent,
                                          min: 0,
                                          max: 50,
                                          divisions: 10,
                                          label: '${_discountPercent.toInt()}%',
                                          onChanged: (v) {
                                            setModalState(() => _discountPercent = v);
                                            setState(() => _discountPercent = v);
                                          },
                                        ),
                                      ),
                                      Text('${_discountPercent.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Ahorro:', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                                      Text('-\$${_discountAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Moneda
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💱 Moneda', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                  value: _selectedCurrency,
                                  items: const [
                                    DropdownMenuItem(value: 'CUP', child: Text('🇨🇺 CUP')),
                                    DropdownMenuItem(value: 'MLC', child: Text('💳 MLC')),
                                    DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD')),
                                  ],
                                  onChanged: (v) => setModalState(() => _selectedCurrency = v!),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Pago
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💵 Pago', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          hintText: _amountPaid > 0 ? '\$${_amountPaid.toStringAsFixed(2)}' : 'Monto pagado',
                                          filled: _amountPaid > 0,
                                        ),
                                        controller: TextEditingController(text: _amountPaid > 0 ? '\$${_amountPaid.toStringAsFixed(2)}' : ''),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: _showNumericKeypad,
                                      icon: const Icon(Icons.keyboard, size: 24),
                                      label: const Text('Teclado'),
                                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Fiado
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: _isCredit ? Colors.orange[50] : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('⚠️ Marcar como Fiado', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Switch(
                                      value: _isCredit,
                                      onChanged: (v) {
                                        setModalState(() => _isCredit = v);
                                        setState(() => _isCredit = v);
                                      },
                                    ),
                                  ],
                                ),
                                if (_isCredit) ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    decoration: const InputDecoration(labelText: 'Notas de crédito', border: OutlineInputBorder()),
                                    maxLines: 2,
                                    onChanged: (v) => _creditNotes = v,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Resumen final
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, -2))],
                        ),
                        child: Column(
                          children: [
                            // Subtotal
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                              Text('\$${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                            ]),
                            const SizedBox(height: 8),
                            // Descuento
                            if (_applyDiscount) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Descuento (${_discountPercent.toInt()}%):', style: TextStyle(color: Colors.green[700])),
                              Text('-\$${_discountAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 8),
                            // Total
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('TOTAL:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text('\$${_total.toStringAsFixed(2)} ($_selectedCurrency)', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                            ]),
                            const SizedBox(height: 12),
                            const Divider(),
                            // Pago y cambio
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Pagado:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                              Text('\$${_amountPaid.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                            ]),
                            const SizedBox(height: 8),
                            if (!_isCredit && _amountPaid > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('🔄 CAMBIO:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                              Text('\$${_change.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _change >= 0 ? Colors.blue : Colors.red)),
                            ]),
                            if (_isCredit) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('⚠️ Pendiente:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                              Text('\$${(_total - _amountPaid).toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ]),
                            const SizedBox(height: 16),
                            // Botón confirmar
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: _cart.isEmpty ? null : _completeSale,
                                icon: const Icon(Icons.check_circle, size: 26),
                                label: const Text('CONFIRMAR VENTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewCustomerDialog(Function setModalState) {
    final nc = TextEditingController(), cc = TextEditingController(), tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nc, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: cc, decoration: const InputDecoration(labelText: 'Carnet *', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: tc, decoration: const InputDecoration(labelText: 'Teléfono *', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nc.text.isEmpty || cc.text.isEmpty || tc.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Complete todos los campos'), backgroundColor: Colors.orange));
                return;
              }
              try {
                await _customerRepo.createCustomer(Customer(nombre: nc.text.trim(), carnetIdentidad: cc.text.trim(), telefono: tc.text.trim()));
                await _loadData();
                setModalState(() {});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cliente registrado'), backgroundColor: Colors.green));
                Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
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
          IconButton(icon: const Icon(Icons.play_circle_outline), onPressed: _resumeSale, tooltip: 'Retomar venta'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          if (_cart.isNotEmpty) IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearCart),
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
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                          leading: CircleAvatar(backgroundColor: p.stockActual > 0 ? Colors.blue : Colors.grey, child: Icon(Icons.inventory_2, color: Colors.white)),
                          title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Stock: ${p.stockActual}'),
                            Text('\$${p.precioVenta.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ]),
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
                              Text('Total: \$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.pause_circle, size: 32), onPressed: _pauseSale, tooltip: 'Pausar venta'),
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
    _pauseNameController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }
}

class CartItem {
  final int productoId;
  final String nombre;
  final double precio;
  int cantidad;
  final int stockDisponible;

  CartItem({
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.stockDisponible,
  });

  double get subtotal => precio * cantidad;

  Map<String, dynamic> toMap() => {
    'productoId': productoId,
    'nombre': nombre,
    'precio': precio,
    'cantidad': cantidad,
    'stockDisponible': stockDisponible,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    productoId: map['productoId'] as int,
    nombre: map['nombre'] as String,
    precio: (map['precio'] as num).toDouble(),
    cantidad: map['cantidad'] as int,
    stockDisponible: map['stockDisponible'] as int,
  );
}
