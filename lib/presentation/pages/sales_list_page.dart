import 'package:flutter/material.dart';
import '../../core/models/sale.dart';
import '../../core/repositories/sale_repository.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final SaleRepository _repo = SaleRepository();
  List<Sale> _sales = [];
  bool _isLoading = true;
  bool _showTodayOnly = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      _sales = _showTodayOnly ? await _repo.getTodaySales() : await _repo.getAllSales();
    } catch (e) {
      print('Error loading sales: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
          PopupMenuButton<bool>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() => _showTodayOnly = v);
              _loadSales();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: true, child: Text('📅 Ventas de Hoy')),
              const PopupMenuItem(value: false, child: Text('📋 Todas las Ventas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con resumen
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('${_sales.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                          const Text('Ventas', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('\$${_sales.fold(0.0, (s, v) => s + v.total).toStringAsFixed(2)}', 
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text('Total', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('${_sales.where((s) => s.esFiado).length}', 
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                          const Text('Fiados', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Lista de ventas
                Expanded(
                  child: _sales.isEmpty
                      ? Center(child: Text(_showTodayOnly ? 'No hay ventas hoy' : 'No hay ventas registradas'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _sales.length,
                          itemBuilder: (ctx, i) {
                            final sale = _sales[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: sale.esFiado ? Colors.orange : Colors.green,
                                  child: Icon(sale.esFiado ? Icons.credit_card : Icons.check_circle, color: Colors.white),
                                ),
                                title: Text('Venta #${sale.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('🕐 ${_formatDate(sale.fecha)}'),
                                    Text('💰 Total: \$${sale.total.toStringAsFixed(2)}'),
                                    if (sale.esFiado) ...[
                                      Text('📝 Pagado: \$${sale.montoPagado.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue)),
                                      Text('⚠️ Pendiente: \$${sale.montoPendiente.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                      if (sale.notasCredito != null && sale.notasCredito!.isNotEmpty)
                                        Text('📋 ${sale.notasCredito}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                    ],
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _showSaleDetails(sale),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Venta #${sale.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📅 Fecha: ${_formatDate(sale.fecha)}'),
              const SizedBox(height: 8),
              Text('💰 Total: \$${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (sale.esFiado) ...[
                const SizedBox(height: 8),
                Text('💵 Pagado: \$${sale.montoPagado.toStringAsFixed(2)}'),
                Text('⚠️ Pendiente: \$${sale.montoPendiente.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange)),
                if (sale.notasCredito != null && sale.notasCredito!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('📋 Notas: ${sale.notasCredito}'),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          ElevatedButton.icon(
            onPressed: () {
              // Aquí se podría integrar con impresión
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🧾 Ticket generado'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Reimprimir'),
          ),
        ],
      ),
    );
  }
}
