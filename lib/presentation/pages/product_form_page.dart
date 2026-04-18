import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProductRepository();
  
  late TextEditingController _nombreController;
  late TextEditingController _codigoController;
  late TextEditingController _costoController;
  late TextEditingController _precioController;
  late TextEditingController _stockController;
  late TextEditingController _stockMinimoController;
  late TextEditingController _categoriaController;
  late TextEditingController _margenController;
  
  bool _esFavorito = false;
  bool _loading = false;
  double _precioSugerido = 0.0;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.product?.nombre ?? '');
    _codigoController = TextEditingController(text: widget.product?.codigo ?? '');
    _costoController = TextEditingController(text: widget.product?.costo?.toString() ?? '');
    _precioController = TextEditingController(text: widget.product?.precioVenta.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockActual.toString() ?? '0');
    _stockMinimoController = TextEditingController(text: widget.product?.stockMinimo.toString() ?? '5');
    _categoriaController = TextEditingController(text: widget.product?.categoria ?? '');
    _margenController = TextEditingController(text: '30'); // Margen default 30%
    _esFavorito = widget.product?.esFavorito ?? false;
    _calcularPrecioSugerido();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _costoController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    _categoriaController.dispose();
    _margenController.dispose();
    super.dispose();
  }

  void _calcularPrecioSugerido() {
    final costo = double.tryParse(_costoController.text) ?? 0.0;
    final margen = double.tryParse(_margenController.text) ?? 30.0;
    setState(() {
      _precioSugerido = costo * (1 + (margen / 100));
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final product = Product(
        id: widget.product?.id,
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim().isEmpty ? 'PROD-' + DateTime.now().millisecondsSinceEpoch.toString() : _codigoController.text.trim(),
        categoria: _categoriaController.text.trim().isEmpty ? 'General' : _categoriaController.text.trim(),
        costo: double.tryParse(_costoController.text) ?? 0.0,
        precioVenta: double.tryParse(_precioController.text) ?? 0.0,
        stockActual: int.tryParse(_stockController.text) ?? 0,
        stockMinimo: int.tryParse(_stockMinimoController.text) ?? 5,
        esFavorito: _esFavorito,
      );

      if (widget.product == null) {
        await _repo.createProduct(product);
      } else {
        await _repo.updateProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null ? '✅ Producto creado' : '✅ Producto actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.black),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre (OBLIGATORIO)
            _buildTextField(_nombreController, 'Nombre del producto *', Icons.inventory_2, isDark,
              validator: (v) => v!.trim().isEmpty ? 'Campo obligatorio' : null),
            const SizedBox(height: 16),
            
            // Código (opcional)
            _buildTextField(_codigoController, 'Código (opcional)', Icons.qr_code, isDark),
            const SizedBox(height: 16),
            
            // Categoría (opcional)
            _buildTextField(_categoriaController, 'Categoría (opcional)', Icons.category, isDark),
            const SizedBox(height: 24),
            
            // Costo
            _buildTextField(_costoController, 'Costo', Icons.attach_money, isDark, 
              keyboardType: TextInputType.number,
              onChanged: (v) => _calcularPrecioSugerido()),
            const SizedBox(height: 16),
            
            // Margen de ganancia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text('Margen de Ganancia (%)', 
                        style: TextStyle(color: isDark ? Colors.green : Colors.black87, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _margenController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Ej: 30',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => _calcularPrecioSugerido(),
                  ),
                  if (_precioSugerido > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Precio sugerido:', style: TextStyle(color: Colors.grey[300])),
                          Text('\$${_precioSugerido.toStringAsFixed(2)}', 
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Precio de Venta (OBLIGATORIO)
            _buildTextField(_precioController, 'Precio de Venta *', Icons.sell, isDark, 
              keyboardType: TextInputType.number,
              validator: (v) {
                final price = double.tryParse(v!);
                if (price == null || price <= 0) return 'Precio obligatorio y mayor a 0';
                return null;
              }),
            const SizedBox(height: 24),
            
            // Stock
            Row(children: [
              Expanded(child: _buildTextField(_stockController, 'Stock Actual', Icons.inventory_2, isDark, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_stockMinimoController, 'Stock Mínimo', Icons.warning, isDark, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 32),
            
            // Botón Guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white, size: 24),
                label: Text(_loading ? 'Guardando...' : 'Guardar Producto', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _loading ? null : _saveProduct,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isDark, 
      {TextInputType? keyboardType, String? Function(String?)? validator, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.green),
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[700]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
