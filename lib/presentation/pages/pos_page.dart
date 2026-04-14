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
import '../../core/utils/currency_helper.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/widgets/common_dialogs.dart';
import 'paused_sales_page.dart';

// ✅ CartItem para el carrito del POS
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

class PosPage extends StatefulWidget {
  final VoidCallback? onSaleCompleted;
  const PosPage({super.key, this.onSaleCompleted});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final ProductRepository _productRepo = ProductRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final SaleRepository _saleRepo = SaleRepository();
  
  List<Product> _products = [];
  List<CartItem> _cart = [];
  Customer? _selectedCustomer;
  String _selectedCurrency = 'CUP';
  double _exchangeRate = 1.0;
  double _taxRate = 0.0;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  bool _isCredit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final db = await DatabaseHelper.instance.database;
    final config = await db.query('config');
    setState(() {
      _exchangeRate = config.firstWhere((c) => c['key'] == 'tasa_cambio', orElse: () => {'value': '1'})['value'].toString().parseDouble();
      _taxRate = config.firstWhere((c) => c['key'] == 'tax_rate', orElse: () => {'value': '0'})['value'].toString().parseDouble();
      _selectedCurrency = config.firstWhere((c) => c['key'] == 'moneda_principal', orElse: () => {'value': 'CUP'})['value'] as String;
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _products = await _productRepo.getAllProducts();
    } catch (e) {
      print('Error cargando productos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalCUP => _cart.fold(0.0, (sum, item) => sum + item.subtotalCUP);
  
  double get _totalAmount {
    if (_selectedCurrency == 'CUP') return _totalCUP;
    return _totalCUP / _exchangeRate;
  }

  double _getPriceInSelectedCurrency(double priceCUP) {
    if (_selectedCurrency == 'CUP') return priceCUP;
    return priceCUP / _exchangeRate;
  }

  void _addToCart(Product product) {
    if (product.stockActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Sin stock'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final existingIndex = _cart.indexWhere((item) => item.productoId == product.id);
    if (existingIndex >= 0) {
      if (_cart[existingIndex].cantidad >= product.stockActual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Stock insuficiente'), backgroundColor: Colors.orange),
        );
        return;
      }
      setState(() => _cart[existingIndex].cantidad++);
    } else {
      setState(() {
        _cart.add(CartItem(
          productoId: product.id,
          nombre: product.nombre,
          precioCUP: product.precioVenta,
          cantidad: 1,
          stockDisponible: product.stockActual,
        ));
      });
    }
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  Future<void> _confirmSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ El carrito está vacío'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    if (amountPaid <= 0 && !_isCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Ingrese el monto pagado'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final pendingAmount = _isCredit ? _totalAmount : (_totalAmount - amountPaid);
    if (pendingAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ El monto pagado excede el total'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    try {
      // Convertir CartItem a SaleLine con productoNombre
      final saleLines = _cart.map((item) => SaleLine(
        productoId: item.productoId,
        productoNombre: item.nombre,  // ✅ Mapear nombre → productoNombre
        cantidad: item.cantidad,
        precioUnitario: _getPriceInSelectedCurrency(item.precioCUP),
        subtotal: _getPriceInSelectedCurrency(item.subtotalCUP),
      )).toList();
      
      final saleId = await _saleRepo.createSale(
        _selectedCustomer?.id,
        saleLines,
        _totalAmount,
        _isCredit ? 0.0 : amountPaid,
        pendingAmount,
        _isCredit ? 'Venta fiada' : null,
        _selectedCurrency,
        _exchangeRate,
      );
      
      final shouldGeneratePdf = await CommonDialogs.showTicketGenerationConfirmation(
        context: context,
        mensaje: '¿Desea generar y compartir el ticket de venta en PDF?',
      );
      
      if (shouldGeneratePdf == true && mounted) {
        await _generatePdfTicket(saleId);
      }
      
      setState(() {
        _cart.clear();
        _amountPaidController.clear();
        _selectedCustomer = null;
        _isCredit = false;
      });
      
      _loadProducts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Venta completada exitosamente'), backgroundColor: Colors.green),
        );
        widget.onSaleCompleted?.call();
      }
    } catch (e) {
      print('Error al confirmar venta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generatePdfTicket(int saleId) async {
    try {
      final sale = await _saleRepo.getSaleById(saleId);
      if (sale == null) return;
      final lines = await _saleRepo.getSaleLines(saleId);
      final pdfFile = await PdfGenerator.generateSaleTicket(sale: sale, lines: lines);
      if (pdfFile != null && mounted) {
        await Printing.sharePdf(bytes: await pdfFile.readAsBytes(), filename: 'ticket_venta_$saleId.pdf');
      }
    } catch (e) {
      print('Error generando PDF: $e');
    }
  }

  Future<void> _showNewCustomerDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre completo *', prefixIcon: Icon(Icons.person)), autofocus: true),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Carnet de Identidad', prefixIcon: Icon(Icons.credit_card))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ El nombre es obligatorio'), backgroundColor: Colors.orange),
                );
                return;
              }
              try {
                final customerId = await _customerRepo.createCustomer(
                  nameCtrl.text.trim(),
                  idCtrl.text.trim().isEmpty ? null : idCtrl.text.trim(),
                  phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                );
                final newCustomer = await _customerRepo.getCustomerById(customerId);
                if (mounted) {
                  setState(() => _selectedCustomer = newCustomer);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Cliente registrado exitosamente'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                print('Error registrando cliente: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    
    nameCtrl.dispose();
    phoneCtrl.dispose();
    idCtrl.dispose();
  }

  Future<void> _pauseSale() async {
    if (_cart.isEmpty) return;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pausar Venta'),
        content: TextField(decoration: const InputDecoration(labelText: 'Nombre de la venta')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'Guardada'),
            child: const Text('Guardar'),
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
          'total': _totalCUP,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Venta pausada'), backgroundColor: Colors.green),
        );
        setState(() => _cart.clear());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredProducts = _searchController.text.isEmpty
        ? _products
        : _products.where((p) => p.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (p.codigo?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        backgroundColor: theme.primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.pause), onPressed: _pauseSale, tooltip: 'Pausar venta'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts, tooltip: 'Actualizar'),
        ],
      ),
      body: Row(
        children: [
          // Lista de productos
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (ctx, i) {
                            final p = filteredProducts[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text(p.nombre),
                                subtitle: Text('Stock: ${p.stockActual} | \$${p.precioVenta.toStringAsFixed(2)}'),
                                trailing: p.stockActual > 0
                                    ? ElevatedButton(onPressed: () => _addToCart(p), child: const Text('Agregar'))
                                    : const Text('Agotado', style: TextStyle(color: Colors.red)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Carrito
          Container(
            width: 300,
            color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
            child: Column(
              children: [
                // Selector de moneda
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'CUP', child: Text('🇨🇺 CUP')),
                      DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD')),
                      DropdownMenuItem(value: 'MLC', child: Text('💱 MLC')),
                    ],
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                ),
                
                // Cliente seleccionado
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCustomer?.nombre ?? 'Cliente: General',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add, size: 20),
                        onPressed: _showNewCustomerDialog,
                        tooltip: 'Nuevo cliente',
                      ),
                    ],
                  ),
                ),
                
                // Items del carrito
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('Carrito vacío', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (ctx, i) {
                            final item = _cart[i];
                            return ListTile(
                              title: Text(item.nombre),
                              subtitle: Text('\$${_getPriceInSelectedCurrency(item.precioCUP).toStringAsFixed(2)} x ${item.cantidad}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('\$${_getPriceInSelectedCurrency(item.subtotalCUP).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.remove, size: 20), onPressed: () => setState(() => item.cantidad > 1 ? item.cantidad-- : _removeFromCart(i))),
                                  IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () => item.cantidad < item.stockDisponible ? setState(() => item.cantidad++) : null),
                                  IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _removeFromCart(i)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                
                // Total y pago
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total:', style: TextStyle(fontSize: 16)),
                        Text('\$${_selectedCurrency} ${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      ]),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountPaidController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monto pagado',
                          prefixText: '\$${_selectedCurrency} ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Checkbox(value: _isCredit, onChanged: (v) => setState(() => _isCredit = v!)),
                        const Text('Venta fiada'),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _cart.isEmpty ? null : _confirmSale,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('CONFIRMAR VENTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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

// Extension para parsear double de String
extension StringParser on String {
  double parseDouble() => double.tryParse(this) ?? 0.0;
}
