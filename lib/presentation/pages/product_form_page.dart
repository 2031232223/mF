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
  late TextEditingController _margenController;
  late TextEditingController _precioController;
  late TextEditingController _stockController;
  late TextEditingController _stockMinimoController;
  late TextEditingController _categoriaController;
  late TextEditingController _stockCriticoController;
  
  bool _esFavorito = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.product?.nombre ?? '');
    _codigoController = TextEditingController(text: widget.product?.codigo ?? '');
    _costoController = TextEditingController(text: widget.product?.costo?.toString() ?? '');
    _margenController = TextEditingController(text: widget.product?.margenGanancia?.toString() ?? '30');
    _precioController = TextEditingController(text: widget.product?.precioVenta.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockActual.toString() ?? '0');
    _stockMinimoController = TextEditingController(text: widget.product?.stockMinimo.toString() ?? '5');
    _categoriaController = TextEditingController(text: widget.product?.categoria ?? '');
    _stockCriticoController = TextEditingController(text: widget.product?.stockCritico?.toString() ?? '2');
    _esFavorito = widget.product?.esFavorito ?? false;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _costoController.dispose();
    _margenController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    _categoriaController.dispose();
    _stockCriticoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final product = Product(
        id: widget.product?.id,
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim(),
        costo: double.tryParse(_costoController.text) ?? 0.0,
          margenGanancia: double.tryParse(_margenController.text) ?? 0.0,
        precioVenta: double.parse(_precioController.text),
        stockActual: int.tryParse(_stockController.text) ?? 0,
        stockMinimo: int.tryParse(_stockMinimoController.text) ?? 5,
        categoria: _categoriaController.text.trim().isEmpty ? null : _categoriaController.text.trim(),
        esFavorito: _esFavorito,
        stockCritico: int.tryParse(_stockCriticoController.text),
        unidadMedida: 'und',
      );

      if (widget.product == null) {
        await _repo.createProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto creado'), backgroundColor: Colors.green),
          );
        }
      } else {
        await _repo.updateProduct(widget.product!.id!, product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto actualizado'), backgroundColor: Colors.green),
          );
        }
      }
      
      if (mounted) Navigator.pop(context, true);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto'),
        centerTitle: true,
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codigoController,
              decoration: const InputDecoration(labelText: 'Código *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoriaController,
              decoration: const InputDecoration(labelText: 'Categoría (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _costoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Costo', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _margenController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Margen de ganancia (%)', border: OutlineInputBorder()),
                        onChanged: (val) {
                          final costo = double.tryParse(_costoController.text) ?? 0;
                          final margen = double.tryParse(val) ?? 0;
                          if (costo > 0) {
                            _precioController.text = (costo + (costo * (margen / 100))).toStringAsFixed(2);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _precioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio Venta *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock Actual', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockMinimoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock Mínimo', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockCriticoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock Crítico (alerta)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('⭐ Marcar como favorito'),
              subtitle: const Text('Aparecerá en lista de favoritos'),
              value: _esFavorito,
              onChanged: (v) => setState(() => _esFavorito = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'ACTUALIZAR PRODUCTO' : 'CREAR PRODUCTO', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
