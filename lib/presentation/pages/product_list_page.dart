import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/utils/csv_exporter.dart';
import 'inventory_adjustments_page.dart';
import 'bulk_price_page.dart';

class ProductListPage extends StatefulWidget {
  final VoidCallback? onStatsChanged;
  const ProductListPage({super.key, this.onStatsChanged});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _repo = ProductRepository();
  List<Product> _products = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _products = await _repo.getAllProducts();
    setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      final products = await _repo.getAllProducts();
      final path = await CsvExporter.exportProducts(products.map((p) => p.toMap()).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Exportado: ${path.split('/').last}'), backgroundColor: Colors.green, duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await _repo.deleteProduct(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Producto eliminado'), backgroundColor: Colors.green),
        );
        _load();
        if (widget.onStatsChanged != null) widget.onStatsChanged!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showProductForm({Product? product}) {
    final nombreCtrl = TextEditingController(text: product?.nombre ?? '');
    final codigoCtrl = TextEditingController(text: product?.codigo ?? '');
    final costoCtrl = TextEditingController(text: product?.costo?.toString() ?? '');
    final precioCtrl = TextEditingController(text: product?.precioVenta.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stockActual.toString() ?? '0');
    final stockMinCtrl = TextEditingController(text: product?.stockMinimo.toString() ?? '5');
    final categoriaCtrl = TextEditingController(text: product?.categoria ?? '');
    final stockCriticoCtrl = TextEditingController(text: product?.stockCritico?.toString() ?? '2');
    final margenCtrl = TextEditingController(text: product?.margenGanancia?.toString() ?? '30');
    bool esFavorito = product?.esFavorito ?? false;
    double precioSugerido = 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product == null ? '➕ Nuevo Producto' : '✏️ Editar Producto',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                TextField(
                  controller: nombreCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codigoCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Código *',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoriaCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Categoría (opcional)',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costoCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Costo',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                        onChanged: (v) {
                          final costo = double.tryParse(v) ?? 0.0;
                          final margen = double.tryParse(margenCtrl.text) ?? 30.0;
                          precioSugerido = costo > 0 ? costo * (1 + margen / 100) : 0.0;
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: precioCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Precio Venta *',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  color: isDark ? Colors.blue[900] : Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.orange[400], size: 20),
                            const SizedBox(width: 8),
                            Text('Sugerir Precio por Margen', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Margen %: ', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                            Expanded(
                              child: TextField(
                                controller: margenCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey[700] : Colors.white,
                                ),
                                onChanged: (v) {
                                  final costo = double.tryParse(costoCtrl.text) ?? 0.0;
                                  final margen = double.tryParse(v) ?? 30.0;
                                  precioSugerido = costo > 0 ? costo * (1 + margen / 100) : 0.0;
                                  setModalState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        if (precioSugerido > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Precio sugerido:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                              Text('\$${precioSugerido.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                precioCtrl.text = precioSugerido.toStringAsFixed(2);
                                setModalState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue[400]!),
                              ),
                              child: Text('Aplicar Precio Sugerido', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Stock Actual',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stockMinCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Stock Mínimo',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockCriticoCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Stock Crítico (alerta)',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('⭐ Marcar como favorito', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text('Aparecerá en lista de favoritos', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                  value: esFavorito,
                  onChanged: (v) => esFavorito = v,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (nombreCtrl.text.isEmpty || codigoCtrl.text.isEmpty || precioCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ Complete los campos obligatorios'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      try {
                        final newProduct = Product(
                          id: product?.id,
                          nombre: nombreCtrl.text.trim(),
                          codigo: codigoCtrl.text.trim(),
                          costo: double.tryParse(costoCtrl.text) ?? 0.0,
                          precioVenta: double.parse(precioCtrl.text),
                          stockActual: int.tryParse(stockCtrl.text) ?? 0,
                          stockMinimo: int.tryParse(stockMinCtrl.text) ?? 5,
                          categoria: categoriaCtrl.text.trim().isEmpty ? null : categoriaCtrl.text.trim(),
                          esFavorito: esFavorito,
                          stockCritico: int.tryParse(stockCriticoCtrl.text),
                          margenGanancia: double.tryParse(margenCtrl.text),
                        );
                        if (product == null) {
                          await _repo.createProduct(newProduct);
                        } else {
                          await _repo.updateProduct(product.id!, newProduct);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(product == null ? '✅ Producto creado' : '✅ Producto actualizado'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(ctx);
                          _load();
                          if (widget.onStatsChanged != null) widget.onStatsChanged!();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: Text(
                      product == null ? 'CREAR PRODUCTO' : 'ACTUALIZAR PRODUCTO',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInventoryMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚙️ Opciones de Inventario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Gestión avanzada de productos', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _menuOption(
              icon: Icons.edit,
              color: Colors.orange,
              title: 'Ajustes de Stock',
              subtitle: 'Ajustar stock tras conteo físico (+/-)',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryAdjustmentsPage()));
              },
            ),
            const SizedBox(height: 12),
            _menuOption(
              icon: Icons.price_change,
              color: Colors.green,
              title: 'Cambio Masivo de Precios',
              subtitle: 'Modificar precios por porcentaje',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkPricePage()));
              },
            ),
            const SizedBox(height: 12),
            _menuOption(
              icon: Icons.download,
              color: Colors.blue,
              title: 'Exportar Catálogo',
              subtitle: 'Descargar productos en CSV',
              onTap: () {
                Navigator.pop(ctx);
                _exportCsv();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _menuOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white, size: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportCsv, tooltip: 'Exportar a CSV'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'menu',
            onPressed: _showInventoryMenu,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.tune),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showProductForm(),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _search,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _products.where((p) => p.nombre.toLowerCase().contains(_search.text.toLowerCase())).length,
                    itemBuilder: (ctx, i) {
                      final p = _products.where((prod) => prod.nombre.toLowerCase().contains(_search.text.toLowerCase())).toList()[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.stockActual > 0 ? (p.esStockCritico ? Colors.orange : Colors.blue) : Colors.grey,
                            child: Icon(p.esFavorito ? Icons.star : Icons.inventory_2, color: Colors.white),
                          ),
                          title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.categoria != null) Text('📁 ${p.categoria}', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                              Text('Stock: ${p.stockActual} ${p.esStockCritico ? '⚠️ Crítico' : ''}', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                              Text('\$${p.precioVenta.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold)),
                              if (p.margenGanancia != null) Text('Margen: ${p.margenGanancia!.toStringAsFixed(1)}%', style: TextStyle(color: Colors.green[400], fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: Icon(Icons.edit, color: isDark ? Colors.white : Colors.black87), onPressed: () => _showProductForm(product: p)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(p.id!)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}
