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
  
  bool _esFavorito = false;
  bool _loading = false;

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
    _esFavorito = widget.product?.esFavorito ?? false;
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
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final product = Product(
        id: widget.product?.id ?? 0,
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim(),
        categoria: _categoriaController.text.trim(),
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
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
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
          style: TextStyle(color: isDark ? Colors.green : Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_nombreController, 'Nombre del producto', Icons.inventory_2, isDark),
            _buildTextField(_codigoController, 'Código', Icons.qr_code, isDark),
            _buildTextField(_categoriaController, 'Categoría', Icons.category, isDark),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildTextField(_costoController, 'Costo', Icons.attach_money, isDark, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_precioController, 'Precio Venta', Icons.sell, isDark, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildTextField(_stockController, 'Stock Actual', Icons.inventory_2, isDark, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_stockMinimoController, 'Stock Mínimo', Icons.warning, isDark, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                label: Text(_loading ? 'Guardando...' : 'Guardar Producto', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _loading ? null : _saveProduct,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isDark, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.green : Colors.black87),
        prefixIcon: Icon(icon, color: isDark ? Colors.green : Colors.black87),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.green : Colors.grey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
      ),
      validator: (v) => v!.trim().isEmpty ? 'Campo requerido' : null,
    );
  }
}
