import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
  
  // RF 17: Descuento global
  double _discountPercent = 0.0;
  bool _applyDiscount = false;
  
  // RF 18: Pago parcial/fiado
  double _amountPaid = 0.0;
  PaymentType _paymentType = PaymentType.cash;
  bool _isCredit = false;
  String _creditNotes = '';

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
        const SnackBar(content: Text('❌ Sin stock'), backgroundColor: Colors.red),
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

  // RF 16: Eliminar producto del carrito
  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
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

  void _clearCart() => setState(() => _cart.clear());

  // RF 17: Calcular total con descuento
  double get _subtotal => _cart.fold(0.0, (sum, c) => sum + (c.subtotal as num).toDouble());
  double get _discountAmount => _applyDiscount ? _subtotal * (_discountPercent / 100) : 0.0;
  double get _total => _subtotal - _discountAmount;

  // RF 18: Calcular cambio o pendiente
  double get _change => _amountPaid - _total;
  double get _pending => _isCredit ? _total - _amountPaid : 0.0;

  // RF 19: Generar ticket
  Future<void> _generateTicket(Sale sale) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ticket_${sale.id}_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      final ticket = '''
════════════════════════════════
        NOVA ADEN
   Administrador de Negocios
════════════════════════════════
Fecha: ${sale.fecha}
Ticket #: ${sale.id}
Cliente: ${_selectedCustomer?.nombre ?? 'General'}
────────────────────────────────
${_cart.map((c) => '${c.nombre} x${c.cantidad}\n   \$${c.precio.toStringAsFixed(2)} c/u = \$${c.subtotal.toStringAsFixed(2)}').join('\n')}
────────────────────────────────
Subtotal: \$${_subtotal.toStringAsFixed(2)}
${_applyDiscount ? 'Descuento (${_discountPercent}%): -\$${_discountAmount.toStringAsFixed(2)}\n' : ''}
TOTAL: \$${_total.toStringAsFixed(2)}
────────────────────────────────
Pago: \$${_amountPaid.toStringAsFixed(2)}
${_isCredit ? 'Pendiente (Fiado): \$${_pending.toStringAsFixed(2)}\n' : 'Cambio: \$${_change.toStringAsFixed(2)}\n'}
════════════════════════════════
   ¡Gracias por su compra!
════════════════════════════════
''';
      await file.writeAsString(ticket);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🧾 Ticket Generado'),
            content: SingleChildScrollView(
              child: Text(ticket, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Aquí se podría integrar con impresora Bluetooth
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🖨️  Enviando a impresora...'), backgroundColor: Colors.blue),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Imprimir'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error ticket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Carrito vacío'), backgroundColor: Colors.orange),
      );
      return;
    }
    // RF 18: Validar pago mínimo
    if (!_isCredit && _amountPaid < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Pago insuficiente'), backgroundColor: Colors.orange),
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

      final saleId = await _saleRepo.createSale(
        _selectedCustomer?.id,
        lines,
        _total,
        _isCredit ? _amountPaid : _total, // paidAmount
        _isCredit ? _pending : 0.0, // pendingAmount
        _creditNotes,
      );

      final sale = Sale(id: saleId, clienteId: _selectedCustomer?.id, fecha: DateTime.now().toIso8601String(), total: _total);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Venta: \$${_total.toStringAsFixed(2)}'), backgroundColor: Colors.green),
        );
        // RF 19: Generar ticket después de venta exitosa
        await _generateTicket(sale);
      }
      
      _clearCart();
      _discountPercent = 0.0;
      _applyDiscount = false;
      _amountPaid = 0.0;
      _isCredit = false;
      _creditNotes = '';
      _loadData();
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
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
                    const Text('🛒 Carrito de Venta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Selector de cliente
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
                      // Lista de productos en carrito
                      if (_cart.isNotEmpty)
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
                                    // RF 16: Botón eliminar
                                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () { _removeFromCart(i); setModalState(() {}); }),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      else
                        const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Carrito vacío', style: TextStyle(fontSize: 16, color: Colors.grey)))),
                      
                      // RF 17: Descuento global
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
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
                                      onChanged: (v) => setModalState(() => _applyDiscount = v),
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
                                          onChanged: (v) => setModalState(() => _discountPercent = v),
                                        ),
                                      ),
                                      Text('${_discountPercent.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Text('Ahorro: -\$${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // RF 18: Tipo de pago y monto
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💳 Método de Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<PaymentType>(
                                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                        value: _paymentType,
                                        items: const [
                                          DropdownMenuItem(value: PaymentType.cash, child: Text('💵 Efectivo')),
                                          DropdownMenuItem(value: PaymentType.transfer, child: Text('📱 Transferencia')),
                                          DropdownMenuItem(value: PaymentType.card, child: Text('💳 Tarjeta')),
                                        ],
                                        onChanged: (v) => setModalState(() => _paymentType = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Fiado: '),
                                        Switch(
                                          value: _isCredit,
                                          onChanged: (v) => setModalState(() => _isCredit = v),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text('Monto Pagado: \$'),
                                    Expanded(
                                      child: TextFormField(
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '0.00'),
                                        onChanged: (v) => setModalState(() => _amountPaid = double.tryParse(v) ?? 0.0),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isCredit) ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    decoration: const InputDecoration(labelText: 'Notas de crédito (opcional)', border: OutlineInputBorder()),
                                    maxLines: 2,
                                    onChanged: (v) => _creditNotes = v,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Totales
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey[100], boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, -2))]),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text('\$${_subtotal.toStringAsFixed(2)}')]),
                            if (_applyDiscount) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Descuento (${_discountPercent.toInt()}%):'), Text('-\$${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green))]),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green))]),
                            if (_isCredit) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pendiente:'), Text('\$${_pending.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
                            if (!_isCredit && _amountPaid > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Cambio:'), Text('\$${_change.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _cart.isEmpty ? null : _completeSale,
                                icon: const Icon(Icons.check_circle, size: 24),
                                label: const Text('CONFIRMAR VENTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

  void _showCustomerDialog() {
    final nc = TextEditingController(), cc = TextEditingController(), tc = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Registrar Cliente'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nc, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: cc, decoration: const InputDecoration(labelText: 'Carnet *', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: tc, decoration: const InputDecoration(labelText: 'Teléfono *', border: OutlineInputBorder())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () async {
          if (nc.text.isNotEmpty && cc.text.isNotEmpty && tc.text.isNotEmpty) {
            try {
              await _customerRepo.createCustomer(Customer(nombre: nc.text.trim(), carnetIdentidad: cc.text.trim(), telefono: tc.text.trim()));
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cliente registrado'), backgroundColor: Colors.green));
                Navigator.pop(ctx);
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
            }
          }
        }, child: const Text('Guardar')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Punto de Venta'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        if (_cart.isNotEmpty) IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearCart),
      ]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          controller: _searchController,
          decoration: InputDecoration(hintText: 'Buscar producto...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))), filled: true, fillColor: Colors.grey[100]),
          onChanged: (v) => setState(() {}),
        )),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _products.where((p) => p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).length,
          itemBuilder: (ctx, i) {
            final p = _products.where((prod) => prod.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).toList()[i];
            return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
              leading: CircleAvatar(backgroundColor: p.stockActual > 0 ? Colors.blue : Colors.grey, child: Icon(Icons.inventory_2, color: Colors.white)),
              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Stock: ${p.stockActual}'), Text('\$${p.precioVenta.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
              trailing: ElevatedButton(onPressed: p.stockActual > 0 ? () => _addToCart(p) : null, child: const Text('Agregar')),
            ));
          },
        )),
        if (_cart.isNotEmpty) Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, -2))]),
          child: Row(children: [
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_cart.length} productos', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text('Total: \$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ])),
            SizedBox(width: 180, height: 50, child: ElevatedButton.icon(
              onPressed: _showCartBottomSheet,
              icon: const Icon(Icons.shopping_cart, size: 20),
              label: const Text('VER CARRITO', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )),
          ]),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Clases auxiliares
class CartItem {
  final int productoId;
  final String nombre;
  final double precio;
  int cantidad;
  final int stockDisponible;
  CartItem({required this.productoId, required this.nombre, required this.precio, required this.cantidad, required this.stockDisponible});
  double get subtotal => precio * cantidad;
}

enum PaymentType { cash, transfer, card }
