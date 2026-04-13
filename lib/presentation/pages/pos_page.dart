import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import '../../core/models/product.dart';
import '../../core/models/customer.dart';
import '../../core/models/sale.dart';
import '../../core/database/database_helper.dart';
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
  final _barcodeController = TextEditingController();
  double _amountPaid = 0.0;
  String _selectedCurrency = 'CUP';
  double _mlcRate = 120.0;
  double _usdRate = 500.0;
  bool _isCredit = false;
  bool _applyDiscount = false;
  double _discountPercent = 0.0;
  int? _lastSaleId;
  
  // ✅ Variable para nombre de empresa configurable
  String _nombreEmpresa = 'Nova Aden';

  @override
  void initState() {
    super.initState();
    _loadData();
    _cargarConfigEmpresa();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // ✅ Cargar nombre de empresa desde configuración
  Future<void> _cargarConfigEmpresa() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'config',
        where: 'key = ?',
        whereArgs: ['nombre_empresa'],
      );
      if (result.isNotEmpty && result.first['value'] != null) {
        setState(() {
          _nombreEmpresa = result.first['value'] as String;
        });
      }
    } catch (e) {
      // Mantener valor por defecto 'Nova Aden'
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _products = await _productRepo.getAllProducts();
    _customers = await _customerRepo.getAllCustomers();
    _mlcRate = await CurrencyHelper.getMlcRate();
    _usdRate = await CurrencyHelper.getUsdRate();
    setState(() => _isLoading = false);
  }

  double _convert(double cupAmount) {
    return CurrencyHelper.convertFromCUP(cupAmount, _selectedCurrency, _mlcRate, _usdRate);
  }

  Product? _findByBarcode(String barcode) {
    try {
      return _products.firstWhere(
        (p) => p.codigo == barcode || p.codigo.contains(barcode),
        orElse: () => throw Exception('No encontrado'),
      );
    } catch (e) {
      return null;
    }
  }

  void _handleBarcodeScan(String barcode) {
    final product = _findByBarcode(barcode);
    if (product != null) {
      _addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${product.nombre} agregado'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
      );
      _barcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Producto no encontrado'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showBarcodeScanner() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📷 Escanear Código de Barras'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese el código manualmente o use el escáner:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Código de Barras',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) _handleBarcodeScan(value);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_barcodeController.text.isNotEmpty) {
                  _handleBarcodeScan(_barcodeController.text);
                  Navigator.pop(ctx);
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Buscar'),
            ),
            const SizedBox(height: 8),
            const Text('💡 Tip: Use un lector de código de barras USB/Bluetooth para escaneo rápido', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    if (product.stockActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No hay stock'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      final idx = _cart.indexWhere((c) => c.productoId == product.id);
      if (idx >= 0) {
        if (_cart[idx].cantidad < product.stockActual) {
          _cart[idx].cantidad++;
        }
      } else {
        _cart.add(CartItem(
          productoId: product.id!,
          nombre: product.nombre,
          precioCUP: product.precioVenta,
          cantidad: 1,
          stockDisponible: product.stockActual,
        ));
      }
    });
  }

  void _increaseQuantity(int index) {
    if (index < 0 || index >= _cart.length) return;
    final p = _products.firstWhere((pr) => pr.id == _cart[index].productoId);
    if (_cart[index].cantidad < p.stockActual) {
      setState(() => _cart[index].cantidad++);
    }
  }

  void _decreaseQuantity(int index) {
    if (index < 0 || index >= _cart.length) return;
    setState(() {
      _cart[index].cantidad--;
      if (_cart[index].cantidad <= 0) _cart.removeAt(index);
    });
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
          decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop('Pausada'), child: const Text('Pausar')),
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
          'total': _totalCUP,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Venta pausada'), backgroundColor: Colors.green),
        );
        _clearCart();
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

  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Carrito vacío'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final totalCUP = _totalCUP;
      final paidCUP = _selectedCurrency == 'CUP' 
          ? _amountPaid 
          : _amountPaid * (_selectedCurrency == 'MLC' ? _mlcRate : _usdRate);
      final pendingCUP = _isCredit ? (totalCUP - paidCUP) : 0.0;

      if (!_isCredit && paidCUP < (totalCUP - 0.01)) {
        final faltanteEnMoneda = _selectedCurrency == 'CUP' 
            ? (totalCUP - _amountPaid)
            : (totalCUP / (_selectedCurrency == 'MLC' ? _mlcRate : _usdRate)) - _amountPaid;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Pago insuficiente. Faltan: ${faltanteEnMoneda.toStringAsFixed(2)} $_selectedCurrency'), 
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final saleLines = _cart.map((item) => SaleLine(
        ventaId: 0,
        productoId: item.productoId,
        cantidad: item.cantidad,
        precioUnitario: item.precioCUP,
        subtotal: item.subtotalCUP,
      )).toList();

      final saleId = await _saleRepo.createSale(
        _selectedCustomer?.id,
        saleLines,
        totalCUP,
        paidCUP,
        pendingCUP,
        _isCredit ? 'Venta fiada' : null,
        _selectedCurrency,
        _selectedCurrency == 'MLC' ? _mlcRate : (_selectedCurrency == 'USD' ? _usdRate : 1.0),
      );
      _lastSaleId = saleId is int ? saleId : null;

      String mensaje = _selectedCurrency == 'CUP'
          ? '✅ Venta: ${totalCUP.toStringAsFixed(2)} CUP'
          : '✅ Venta: ${_amountPaid.toStringAsFixed(2)} $_selectedCurrency (${totalCUP.toStringAsFixed(2)} CUP)';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // ✅ Diálogo de confirmación PDF: Sí (izq) / No (der), centrados con separación
      if (mounted) {
        final shouldGeneratePdf = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🧾 Ticket de Venta'),
            content: const Text('¿Desea generar y compartir el ticket en PDF?'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ SÍ a la izquierda
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sí'),
                      ),
                    ),
                    const SizedBox(width: 16), // ✅ Separación entre botones
                    // ✅ NO a la derecha
                    SizedBox(
                      width: 100,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (shouldGeneratePdf == true && mounted) {
          final sale = await _saleRepo.getSaleById(_lastSaleId!);
          if (sale != null) {
            final saleLines = await _saleRepo.getSaleLines(sale.id!);
            // ✅ Pasar nombre de empresa configurable al generador de PDF
            await PdfGenerator.generateSaleTicket(
              sale, 
              saleLines, 
              nombreEmpresa: _nombreEmpresa,
            );
          }
        }
      }

      if (widget.onSaleCompleted != null) widget.onSaleCompleted!();
      _clearCart();
      _amountPaid = 0.0;
      _isCredit = false;
      _applyDiscount = false;
      _discountPercent = 0.0;
      _selectedCustomer = null;
      _lastSaleId = null;
      _loadData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showNewCustomerDialog() {
    final nc = TextEditingController();
    final cc = TextEditingController();
    final tc = TextEditingController();
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
              TextField(controller: tc, decoration: const InputDecoration(labelText: 'Teléfono ', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nc.text.isEmpty || cc.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Complete campos'), backgroundColor: Colors.orange),
                );
                return;
              }
              try {
                await _customerRepo.createCustomer(Customer(
                  nombre: nc.text.trim(),
                  carnetIdentidad: cc.text.trim(),
                  telefono: tc.text.trim(),
                ));
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Cliente registrado'), backgroundColor: Colors.green),
                );
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
              _buildCartHeader(setModalState, ctx),
              Expanded(child: _buildCartContent(scrollController, setModalState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartHeader(Function setModalState, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🛒 Carrito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedCurrency,
                dropdownColor: Colors.blue[800],
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'CUP', child: Text('🇨🇺 CUP', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'MLC', child: Text('💳 MLC', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setModalState(() => _selectedCurrency = v);
                    setState(() => _selectedCurrency = v);
                    _loadData();
                  }
                },
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(scrollController, Function setModalState) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          _buildCustomerSection(setModalState),
          if (_cart.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Carrito vacío', style: TextStyle(fontSize: 16, color: Colors.grey))))
          else
            _buildCartItems(setModalState),
          _buildDiscountSection(setModalState),
          _buildPaymentSection(setModalState),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(Function setModalState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cliente:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: _showNewCustomerDialog, icon: const Icon(Icons.person_add), label: const Text('Nuevo')),
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
    );
  }

  Widget _buildCartItems(Function setModalState) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
            subtitle: Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_convert(c.precioCUP).toStringAsFixed(2)} c/u'),
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
    );
  }

  Widget _buildDiscountSection(Function setModalState) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark ? Colors.purple[900] : Colors.purple[50],
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
                  Text('Ahorro:', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.green[700], fontWeight: FontWeight.bold)),
                  Text('-${_selectedCurrency == 'CUP' ? '\$' : ''}${_discountAmount.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(Function setModalState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ Modo oscuro: fondo blanco → gris oscuro
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : Colors.grey[100],
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Subtotal:', style: TextStyle(
              fontSize: 16,
              // ✅ Texto visible en modo oscuro
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[300] 
                  : Colors.black,
            )),
            Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_subtotal.toStringAsFixed(2)}', 
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (_applyDiscount)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Descuento:', style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.green[300] 
                    : Colors.green[700],
              )),
              Text('-${_selectedCurrency == 'CUP' ? '\$' : ''}${_discountAmount.toStringAsFixed(2)}', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.green[300] 
                      : Colors.green[700], 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_total.toStringAsFixed(2)} $_selectedCurrency',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Pagado:', style: TextStyle(
              fontSize: 16, 
              // ✅ Color de texto adaptable
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[400] 
                  : Colors.grey[700],
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto Pagado',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.payments, color: Colors.blue),
                  hintText: '0.00',
                  // ✅ Hint visible en modo oscuro
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[500] 
                        : Colors.grey,
                  ),
                ),
                style: TextStyle(
                  // ✅ Texto del input visible en modo oscuro
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                ),
                onChanged: (val) {
                  setState(() {
                    _amountPaid = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
            ),
            Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_amountPaidForeign.toStringAsFixed(2)}', 
              style: TextStyle(
                fontSize: 16, 
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[700],
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (!_isCredit) ...[
            if (_amountPaidForeign < _total)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('⚠️ Faltante:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                Text(
                  '${_selectedCurrency == 'CUP' ? '\$' : ''}${(_total - _amountPaidForeign).toStringAsFixed(2)} $_selectedCurrency',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ])
            else if (_amountPaidForeign >= _total)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('🔄 CAMBIO:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_change.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              ]),
          ],
          if (_isCredit && _amountPaidForeign > 0)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('⚠️ Pendiente:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_pending.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
            ]),
          const SizedBox(height: 16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Punto de Venta'),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _selectedCurrency,
              dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'CUP', child: Text('🇨🇺 CUP')),
                DropdownMenuItem(value: 'MLC', child: Text('💳 MLC')),
                DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedCurrency = v);
                _loadData();
              },
            ),
          ],
        ),
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
                      hintText: 'Buscar por código o nombre...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
                      hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.grey),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _products.where((p) => 
                        p.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                        p.codigo.toLowerCase().contains(_searchController.text.toLowerCase())).length,
                    itemBuilder: (ctx, i) {
                      final filtered = _products.where((prod) =>
                          prod.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          prod.codigo.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                      final p = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.stockActual > 0 ? Colors.blue : Colors.grey,
                            child: Icon(Icons.inventory_2, color: Colors.white),
                          ),
                          title: Text(p.nombre, style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            // ✅ Título visible en modo oscuro
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black,
                          )),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stock: ${p.stockActual}', 
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey[400] 
                                      : Colors.black54,
                                ),
                              ),
                              Text('${_selectedCurrency == 'CUP' ? '\$' : ''}${_convert(p.precioVenta).toStringAsFixed(2)}', 
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.green[300] 
                                      : Colors.green, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                      // ✅ Fondo adaptable: blanco → gris oscuro en modo oscuro
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF1E1E1E) 
                          : Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, -2))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_cart.length} productos', 
                                    style: TextStyle(
                                      fontSize: 14, 
                                      // ✅ Texto gris visible en modo oscuro
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.grey[400] 
                                          : Colors.grey,
                                    ),
                                  ),
                                  Text('Total: ${_selectedCurrency == 'CUP' ? '\$' : ''}${_total.toStringAsFixed(2)} $_selectedCurrency', 
                                    style: TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.bold, 
                                      // ✅ Total visible en modo oscuro
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.green[300] 
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.pause_circle, size: 32), onPressed: _pauseSale, tooltip: 'Pausar venta'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Venta Fiada', style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text('El cliente pagará después'),
                                value: _isCredit,
                                onChanged: (v) => setState(() => _isCredit = v ?? false),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                // ✅ CORREGIDO: titleTextStyle y subtitleTextStyle para Flutter 3.22+
                                titleTextStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey[300] 
                                      : null,
                                ),
                                subtitleTextStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey[400] 
                                      : null,
                                ),
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
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
  CartItem({
    required this.productoId,
    required this.nombre,
    required this.precioCUP,
    required this.cantidad,
    required this.stockDisponible,
  });

  double get subtotalCUP => precioCUP * cantidad;

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'precioCUP': precioCUP,
      'cantidad': cantidad,
      'stockDisponible': stockDisponible,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productoId: map['productoId'] as int,
      nombre: map['nombre'] as String,
      precioCUP: (map['precioCUP'] as num).toDouble(),
      cantidad: map['cantidad'] as int,
      stockDisponible: map['stockDisponible'] as int,
    );
  }
}
