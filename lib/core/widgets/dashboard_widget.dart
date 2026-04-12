import 'package:flutter/material.dart';

class DashboardWidget extends StatelessWidget {
  const DashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Tarjeta Resumen General
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Resumen General', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Icon(Icons.trending_up, color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Ventas Totales
                  Row(children: [
                    Icon(Icons.attach_money, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ventas Totales', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('\$15,250.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ])),
                  ]),
                  const Divider(height: 24),
                  
                  // Productos
                  Row(children: [
                    Icon(Icons.inventory_2, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Productos en Inventario', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('49 unidades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ])),
                  ]),
                  const Divider(height: 24),
                  
                  // Proveedores
                  Row(children: [
                    Icon(Icons.store, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Proveedores Registrados', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('1 proveedor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ])),
                  ]),
                  const Divider(height: 24),
                  
                  // Clientes
                  Row(children: [
                    Icon(Icons.person, color: Colors.purple, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Clientes Registrados', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('1 cliente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                    ])),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Botones Acceso Rápido
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/pos'), icon: Icon(Icons.point_of_sale), label: Text('POS'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical: 12)))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/inventory'), icon: Icon(Icons.inventory_2), label: Text('Inventario'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical: 12)))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/purchases'), icon: Icon(Icons.shopping_cart), label: Text('Compras'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical: 12)))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/reports'), icon: Icon(Icons.bar_chart), label: Text('Reportes'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical: 12)))),
            ]),
          ],
        ),
      ),
    );
  }
}
