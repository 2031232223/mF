import 'package:flutter/material.dart';
import '../../core/models/customer.dart';
import '../../core/models/sale.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/customer_repository.dart';
import '../../core/repositories/sale_repository.dart';
import 'pos_page.dart';

class CartPage extends StatefulWidget {
  final List<CartItem> cart;
  final String selectedCurrency;
  final double exchangeRate;
  final double totalCUP;
  final VoidCallback onSaleCompleted;

  const CartPage({
    super.key,
    required this.cart,
    required this.selectedCurrency,
    required this.exchangeRate,
    required this.totalCUP,
    required this.onSaleCompleted,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CustomerRepository _customerRepo = CustomerRepository();
  final SaleRepository _saleRepo = SaleRepository();
  
  Customer? _selectedCustomer;
  bool _isCredit = false;
  double _discount = 0.0;
  final TextEditingController _paymentController = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      _customers = await _customerRepo.getAllCustomers();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading customers: $e');
    }
  }

  double get _subtotal => widget.totalCUP - _discount;
  
  double get _total {
    if (widget.selectedCurrency == 'CUP') return _subtotal;
    return _subtotal / widget.exchangeRate;
  }

  double get _paid {
    return double.tryParse(_paymentController.text) ?? 0.0;
  }

  double get _change => _paid - _total;

  Future<void> _confirmSale() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Selecciona un cliente'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_paid < _total && !_isCredit) {
      ScaffoldMessenger.of.context).showSnackBar(
        const SnackBar(content: Text('⚠️ El pago es insuficiente'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sale = Sale(
        customerId: _selectedCustomer!.id,
        totalCUP: _subtotal,
        totalUSD: widget.selectedCurrency == 'USD' ? _total : _subtotal / widget.exchangeRate,
        totalMLC: widget.selectedCurrency == 'MLC' ? _total : _subtotal / widget.exchangeRate,
        currency: widget.selectedCurrency,
        exchangeRate: widget.exchangeRate,
        discount: _discount,
        isCredit: _isCredit,
        items: widget.cart.map((item) => SaleItem(
          productId: item.productoId,
          quantity: item.cantidad,
          priceCUP: item.precioCUP,
        )).toList(),
      );

      await _saleRepo.createSale(sale);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Venta registrada exitosamente'), backgroundColor: Colors.green),
        );
        widget.onSaleCompleted();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Seleccionar Cliente', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_customers.isEmpty)
              const Text('No hay clientes registrados', style: TextStyle(color: Colors.grey)),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  return Card(
                    color: Colors.grey[850],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blue, child: Text(customer.nombre[0], style: const TextStyle(color: Colors.white))),
                      title: Text(customer.nombre, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(customer.telefono ?? '', style: TextStyle(color: Colors.grey[400])),
                      onTap: () {
                        setState(() => _selectedCustomer = customer);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        elevation: 2,
        actions: [
          DropdownButton<String>(
            value: widget.selectedCurrency,
            dropdownColor: Colors.blue[900],
            underline: const SizedBox(),
            items: ['CUP', 'USD', 'MLC'].map((currency) {
              return DropdownMenuItem(value: currency, child: Text(currency, style: const TextStyle(color: Colors.white)));
            }).toList(),
            onChanged: null,
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Column(
        children: [
          // Customer Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Cliente:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  label: const Text('Nuevo', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    // TODO: Navigate to create customer
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Card(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(_selectedCustomer == null ? Icons.person : Icons.check, color: Colors.white)),
                title: Text(_selectedCustomer?.nombre ?? 'Seleccionar cliente', style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showCustomerSelector,
              ),
            ),
          ),

          // Cart Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                final item = widget.cart[index];
                final priceInCurrency = widget.selectedCurrency == 'CUP' ? item.precioCUP : item.precioCUP / widget.exchangeRate;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 24,
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                              Text('${priceInCurrency.toStringAsFixed(2)} c/u', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                if (item.cantidad > 1) {
                                  setState(() => item.cantidad--);
                                }
                              },
                            ),
                            Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                if (item.cantidad < item.stockDisponible) {
                                  setState(() => item.cantidad++);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () {
                                setState(() => widget.cart.removeAt(index));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Discount
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Card(
              color: Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, color: Colors.green),
                    const SizedBox(width: 12),
                    const Text('Descuento Global', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: _discount > 0,
                      onChanged: (value) {
                        setState(() => _discount = value ? 0.0 : 0.0);
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(color: Colors.grey)),
                    Text('${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      '${_total.toStringAsFixed(2)} ${widget.selectedCurrency}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pagado:', style: TextStyle(color: Colors.grey)),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _paymentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (_paid < _total)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text('Faltante:', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text('${(_total - _paid).toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                if (_paid >= _total && _paid > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('Cambio:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text('${_change.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle, color: Colors.white, size: 24),
                label: Text(
                  _isLoading ? 'Procesando...' : 'CONFIRMAR VENTA',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _isLoading ? null : _confirmSale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }
}
