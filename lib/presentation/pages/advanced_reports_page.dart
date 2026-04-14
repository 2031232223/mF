import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/repositories/report_repository.dart';
import '../../core/models/report.dart';

class AdvancedReportsPage extends StatefulWidget {
  const AdvancedReportsPage({super.key});

  @override
  State<AdvancedReportsPage> createState() => _AdvancedReportsPageState();
}

class _AdvancedReportsPageState extends State<AdvancedReportsPage> {
  final ReportRepository _reportRepo = ReportRepository();
  int _selectedIndex = 0;
  
  List<ProductRotation> _rotationData = [];
  List<ProductMargin> _marginData = [];
  List<CashFlow> _cashFlowData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRotationData();
  }

  Future<void> _loadRotationData() async {
    setState(() => _isLoading = true);
    try {
      _rotationData = await _reportRepo.getProductRotation();
    } catch (e) {
      print('Error cargando rotación: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMarginData() async {
    setState(() => _isLoading = true);
    try {
      _marginData = await _reportRepo.getProductMargin();
    } catch (e) {
      print('Error cargando márgenes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCashFlowData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      _cashFlowData = await _reportRepo.getCashFlow(
        startDate: startDate,
        endDate: now,
      );
    } catch (e) {
      print('Error cargando flujo de caja: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Avanzados'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // Tabs de navegación
          Container(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[900] 
                : Colors.grey[200],
            child: Row(
              children: [
                Expanded(child: _buildTab('Rotación', Icons.trending_up, 0)),
                Expanded(child: _buildTab('Márgenes', Icons.show_chart, 1)),
                Expanded(child: _buildTab('Flujo Caja', Icons.account_balance, 2)),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildRotationReport(),
                      _buildMarginReport(),
                      _buildCashFlowReport(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 0) _loadRotationData();
        if (index == 1) _loadMarginData();
        if (index == 2) _loadCashFlowData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // RF 62: Reporte de Rotación
  Widget _buildRotationReport() {
    return _rotationData.isEmpty
        ? const Center(child: Text('No hay datos de rotación'))
        : ListView.builder(
            itemCount: _rotationData.length,
            itemBuilder: (ctx, i) {
              final item = _rotationData[i];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(item.productName),
                  subtitle: Text('Última venta: ${item.ultimaVenta.day}/${item.ultimaVenta.month}/${item.ultimaVenta.year}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.totalVendido} unid.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${item.ingresosTotales.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // RF 63: Reporte de Márgenes
  Widget _buildMarginReport() {
    return _marginData.isEmpty
        ? const Center(child: Text('No hay datos de márgenes'))
        : ListView.builder(
            itemCount: _marginData.length,
            itemBuilder: (ctx, i) {
              final item = _marginData[i];
              final isPositive = item.margen > 0;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(item.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Costo: \$${item.costo.toStringAsFixed(2)}'),
                      Text('Venta: \$${item.precioVenta.toStringAsFixed(2)}'),
                      Text('Margen: \$${item.margen.toStringAsFixed(2)} (${item.porcentajeMargen.toStringAsFixed(1)}%)'),
                    ],
                  ),
                  trailing: Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
              );
            },
          );
  }

  // RF 64: Reporte de Flujo de Caja
  Widget _buildCashFlowReport() {
    if (_cashFlowData.isEmpty) {
      return const Center(child: Text('No hay datos de flujo de caja'));
    }

    final totalIngresos = _cashFlowData.fold<double>(0, (sum, cf) => sum + cf.ingresos);
    final totalEgresos = _cashFlowData.fold<double>(0, (sum, cf) => sum + cf.egresos);
    final saldoFinal = totalIngresos - totalEgresos;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Resumen
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Ingresos', totalIngresos, Colors.green),
                  _buildSummaryItem('Egresos', totalEgresos, Colors.red),
                  _buildSummaryItem('Saldo', saldoFinal, saldoFinal >= 0 ? Colors.blue : Colors.orange),
                ],
              ),
            ),
          ),
          
          // Gráfico
          SizedBox(
            height: 250,
            child: _buildCashFlowChart(),
          ),
          
          // Lista detallada
          ..._cashFlowData.map((cf) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text('${cf.fecha.day}/${cf.fecha.month}/${cf.fecha.year}'),
              subtitle: Text('Ingresos: \$${cf.ingresos.toStringAsFixed(2)} | Egresos: \$${cf.egresos.toStringAsFixed(2)}'),
              trailing: Text(
                '\$${cf.saldo.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cf.saldo >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // RF 67: Gráfico de Flujo de Caja
  Widget _buildCashFlowChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _cashFlowData.length) return const Text('');
                  final date = _cashFlowData[value.toInt()].fecha;
                  return Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _cashFlowData.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.saldo);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.3), Colors.blue.withOpacity(0.1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
