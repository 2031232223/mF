import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/models/customer.dart';
import '../../core/models/sale.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/repositories/customer_repository.dart';
import '../../core/repositories/sale_repository.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/pdf_generator.dart';
import 'paused_sales_page.dart';

class PosPage extends StatefulWidget {
  final VoidCallback? onSaleCompleted;
  const PosPage({super.key, this.onSaleCompleted});
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
  double _amountPaid = 0.0;
  String _selectedCurrency = 'CUP';
  double _mlcRate = 120.0;
  double _usdRate = 1.0;
  bool _isCredit = false;
  bool _applyDiscount = false;
  double _discountPercent = 0.0;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _products = await _productRepo.getAllProducts();
    _customers = await _customerRepo.getAllCustomers();
    _mlcRate = await CurrencyHelper.getMlcRate();
    _usdRate = await CurrencyHelper.getUsdRate();
    setState(() => _isLoading = false);
  }

  double _convert(double cupAmount) => CurrencyHelper.convertFromCUP(cupAmount, _selectedCurrency, _mlcRate, _usdRate);

  void _addToCart(Product product) {
    if (product.stockActual <= 0) return;
    setState(() {
      final idx = _cart.indexWhere((c) => c.productoId == product.id);
      if (idx >= 0 && _cart[idx].cantidad < product.stockActual) _cart[idx].cantidad++;
      else if (idx < 0) _cart.add(CartItem(productoId: product.id!, nombre: product.nombre, precioCUP: product.precioVenta, cantidad: 1, stockDisponible: product.stockActual));
    });
  }

  void _increaseQuantity(int index) {
    if (index < 0 || index >= _cart.length) return;
    final p = _products.firstWhere((pr) => pr.id == _cart[index].productoId);
    if (_cart[index].cantidad < p.stockActual) setState(() => _cart[index].cantidad++);
  }

  void _decreaseQuantity(int index) {
    if (index < 0 || index >= _cart.length) return;
    setState(() { _cart[index].cantidad--; if (_cart[index].cantidad <= 0) _cart.removeAt(index); });
  }

  void _removeFromCart(int index) => setState(() => _cart.removeAt(index));
  void _clearCart() => setState(() => _cart.clear());

  double get _subtotalCUP => _cart.fold(0.0, (sum, c) => sum + c.subtotalCUP);
  double get _discountAmountCUP => _applyDiscount ? _subtotalCUP * (_discountPercent / 100) : 0.0;
  double get _totalCUP => _subtotalCUP - _discountAmountCUP;
  double get _subtotal => _convert(_subtotalCUP);
  double get _discountAmount => _convert(_discountAmountCUP);
  double get _total => _convert(_totalCUP);
  double get _amountPaidForeign => _convert(_amountPaid);
  double get _change => _isCredit ? 0.0 : (_amountPaidForeign >= _total ? _amountPaidForeign - _total : 0.0);
  double get _pending => _isCredit ? _total - _amountPaidForeign : 0.0;

  Future<void> _pauseSale() async {
    if (_cart.isEmpty) return;
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('Pausar Venta'), content: TextField(decoration: const InputDecoration(labelText: 'Nombre')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop('Pausada'), child: const Text('Pausar'))]));
    if (name != null && name.isNotEmpty) {
      // Logic to save paused sale would go here
      _clearCart();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Venta pausada')));
    }
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) return;
    final totalCUPToPay = CurrencyHelper.convertToCUP(_total, _selectedCurrency, _mlcRate, _usdRate);
    final paidCUP = CurrencyHelper.convertToCUP(_amountPaidForeign, _selectedCurrency, _mlcRate, _usdRate);
    if (!_isCredit && paidCUP < totalCUPToPay) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Pago insuficiente. Faltan \$${(totalCUPToPay - paidCUP).toStringAsFixed(2)} CUP'))); return; }
    try {
      final lines = _cart.map((c) => SaleLine(ventaId: 0, productoId: c.productoId, cantidad: c.cantidad, precioUnitario: c.precioCUP, subtotal: c.subtotalCUP)).toList();
      final saleId = await _saleRepo.createSale(_selectedCustomer?.id, lines, totalCUPToPay, _isCredit ? paidCUP : totalCUPToPay, _isCredit ? (totalCUPToPay - paidCUP) : 0.0, '', _selectedCurrency, _selectedCurrency == 'CUP' ? 1.0 : (_selectedCurrency == 'MLC' ? _mlcRate : _usdRate));
      final createdSale = await _saleRepo.getSaleById(saleId);
      if (createdSale != null) {
        final saleLines = await _saleRepo.getSaleLines(saleId);
        final finalLines = saleLines.map((l) => SaleLine(ventaId: saleId, productoId: l.productoId, cantidad: l.cantidad, precioUnitario: l.precioUnitario, subtotal: l.subtotal)).toList();
        await PdfGenerator.generateSaleTicket(createdSale, finalLines);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Venta registrada satisfactoriamente'), backgroundColor: Colors.green));
      if (widget.onSaleCompleted != null) widget.onSaleCompleted!();
      _clearCart();
      _amountPaid = 0.0;
      _isCredit = false;
      _applyDiscount = false;
      _discountPercent = 0.0;
      _loadData();
      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'))); }
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (context, setModalState) => DraggableScrollableSheet(initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (context, scrollController) => Column(children: [
      Container(padding: const EdgeInsets.all(16), color: Colors.blue, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('🛒 Carrito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx))])),
      Expanded(child: SingleChildScrollView(controller: scrollController, child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: DropdownButtonFormField<Customer>(decoration: const InputDecoration(border: OutlineInputBorder()), items: [const DropdownMenuItem(value: null, child: Text('Cliente General')), ..._customers.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre)))], value: _selectedCustomer, onChanged: (v) => setModalState(() => _selectedCustomer = v))),
        if (_cart.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Carrito vacío')))
        else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _cart.length, itemBuilder: (ctx, i) {
          final c = _cart[i];
          return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.blue, child: Text('${c.cantidad}', style: const TextStyle(color: Colors.white))), title: Text(c.nombre), subtitle: Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_convert(c.precioCUP).toStringAsFixed(2)} c/u'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () { _decreaseQuantity(i); setModalState(() {}); }),
              Text('${c.cantidad}'),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () { _increaseQuantity(i); setModalState(() {}); }),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { _removeFromCart(i); setModalState(() {}); }),
            ])));
        }),
        Card(color: Colors.grey[100], child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_subtotal.toStringAsFixed(2)}')]),
          if (_applyDiscount) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Descuento:'), Text('-${_selectedCurrency == 'CUP' ? '\$' : ''}${_discountAmount.toStringAsFixed(2)}')]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_total.toStringAsFixed(2)} $_selectedCurrency', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green))]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pagado:'), Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_amountPaidForeign.toStringAsFixed(2)}')]),
          if (!_isCredit && _amountPaidForeign >= _total) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('CAMBIO:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)), Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_change.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue))]),
          if (_isCredit && _amountPaidForeign > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pendiente:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)), Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_pending.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange))]),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _cart.isEmpty ? null : _completeSale, icon: const Icon(Icons.check_circle), label: Text('CONFIRMAR VENTA'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
        ]))),
      ]))),
    ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Punto de Venta'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Buscar producto...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[100]), onChanged: (v) => setState(() {}))),
        Expanded(child: ListView.builder(itemCount: _products.where((p) => p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).length, itemBuilder: (ctx, i) {
          final p = _products.where((prod) => prod.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).toList()[i];
          return Card(child: ListTile(leading: CircleAvatar(backgroundColor: p.stockActual > 0 ? Colors.blue : Colors.grey, child: const Icon(Icons.inventory_2, color: Colors.white)),
            title: Text(p.nombre), subtitle: Text('Stock: ${p.stockActual}'), trailing: Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_convert(p.precioVenta).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            onTap: () => _addToCart(p)));
        })),
        if (_cart.isNotEmpty) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, -2))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total: ${_selectedCurrency == 'CUP' ? '\$' : ''}${_total.toStringAsFixed(2)} $_selectedCurrency', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))])),
              IconButton(icon: const Icon(Icons.pause_circle, size: 32), onPressed: _pauseSale)]),
            CheckboxListTile(title: const Text('Venta Fiada'), value: _isCredit, onChanged: (v) => setState(() => _isCredit = v ?? false)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Monto Pagado', prefixIcon: const Icon(Icons.payment), border: const OutlineInputBorder()), onChanged: (v) => setState(() => _amountPaid = double.tryParse(v) ?? 0.0))),
              const SizedBox(width: 8),
              SizedBox(height: 50, width: 150, child: ElevatedButton.icon(onPressed: _showCartBottomSheet, icon: const Icon(Icons.shopping_cart), label: const Text('CARRITO'))),
            ]),
          ])),
      ]));
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
  Map<String, dynamic> toMap() => {'productoId': productoId, 'nombre': nombre, 'precioCUP': precioCUP, 'cantidad': cantidad};
  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(productoId: map['productoId'], nombre: map['nombre'], precioCUP: map['precioCUP'], cantidad: map['cantidad'], stockDisponible: 0);
}
