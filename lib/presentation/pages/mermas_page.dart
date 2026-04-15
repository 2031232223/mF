import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/repositories/product_repository.dart';
import 'common_dialogs.dart';

class MermasPage extends StatefulWidget {
  const MermasPage({super.key});

  @override
  State<MermasPage> createState() => _MermasPageState();
}

class _MermasPageState extends State<MermasPage> {
  final ProductRepository _productRepo = ProductRepository();
  List<Map<String, dynamic>> _productos = [];
  Map<String, String>? _motivoSelecionado;
  TextEditingController? _cantidadController;
  bool _isLoading = false;

  final List<Map<String, String>> _motivos = [
    {'key': 'deterioro', 'label': '🍂 Deterioro'},
    {'key': 'vencimiento', 'label': '⏰ Vencimiento'},
    {'key': 'robo', 'label': '🔒 Robo/Sustracción'},
    {'key': 'error_operativo', 'label': '❌ Error Operativo'},
    {'key': 'personalizado', 'label': '✏️ Personalizado'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoading = true);
    try {
      final allProducts = await _productRepo.getAllProducts();
      setState(() {
        _productos = allProducts.map((p) => {
          'id': p.id,
          'nombre': p.nombre,
          'stockActual': p.stockActual,
          'codigo': p.codigo ?? '',
        }).toList();
      });
    } catch (e) {
      print('Error cargando productos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarMerma(int productId) async {
    if (_cantidadController?.text.isEmpty == true ||
        _motivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Complete todos los campos'), backgroundColor: Colors.red),
      );
      return;
    }

    final cantidad = int.tryParse(_cantidadController!.text) ?? 0;
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Cantidad debe ser > 0'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      final product = await _productRepo.getProductById(productId);
      if (product == null || product.stockActual < cantidad) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Stock insuficiente (${product?.stockActual ?? 0})'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await db.insert('mermas', {
        'producto_id': productId,
        'cantidad': cantidad,
        'motivo': _motivoSelecionado!['key'],
        'fecha': DateTime.now().toIso8601String(),
      });

      await _productRepo.updateProductStock(productId, cantidad);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Merma registrada exitosamente'), backgroundColor: Colors.red),
        );
        _clearForm();
        _loadProductos();
      }
    } catch (e) {
      print('Error registrando merma: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _cantidadController?.clear();
    _motivoSelecionado = null;
  }

  void _mostrarDialogoConfirmacion(int productId, String nombre) {
    CommonDialogs.showDeleteConfirmation(
      context: context,
      itemName: nombre,
    ).then((confirmado) {
      if (confirmado == true && mounted) {
        _registrarMerma(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Merma')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Buscar Producto', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<Map<String, String>>(
              decoration: InputDecoration(labelText: 'Seleccionar Motivo'),
              items: _motivos.map((m) => DropdownMenuItem(value: m, child: Text(m['label']!))).toList(),
              onChanged: (val) {
                setState(() => _motivoSelecionado = val);
              },
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _cantidadController,
              decoration: InputDecoration(labelText: 'Cantidad', prefixIcon: Icon(Icons.numbers)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            _buildProductoList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_productos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No hay productos registrados', style: TextStyle(color: Colors.grey))),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _productos.length,
      itemBuilder: (ctx, i) {
        final prod = _productos[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.inventory_2, color: Colors.blue)),
            title: Text(prod['nombre']),
            subtitle: Text('Stock: ${prod['stockActual']} | Cód: ${prod['codigo']}'),
            trailing: ElevatedButton(
              onPressed: () => _mostrarDialogoConfirmacion(prod['id'], prod['nombre']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ),
        );
      },
    );
  }
}
