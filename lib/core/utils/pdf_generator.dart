import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/sale.dart';
// ✅ ELIMINADO: import '../models/sale_line.dart'; (no existe)
// Usamos SaleLine desde sale.dart o lo definimos localmente

// ✅ Definición local de SaleLine si no existe como archivo separado
class SaleLine {
  final int ventaId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  
  SaleLine({
    required this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });
  
  factory SaleLine.fromMap(Map<String, dynamic> map) {
    return SaleLine(
      ventaId: map['venta_id'] as int? ?? 0,
      productoId: map['producto_id'] as int? ?? 0,
      cantidad: map['cantidad'] as int? ?? 0,
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PdfGenerator {
  // ✅ MÉTODO PRINCIPAL: Generar ticket de venta en PDF
  static Future<File?> generateSaleTicket({
    required Sale sale,
    required List<SaleLine> lines,
    String nombreEmpresa = 'Nova Aden',
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Center(
                  child: pw.Text(
                    nombreEmpresa.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'TICKET DE VENTA',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 5),
                
                // Información de la venta
                pw.Text('No. Venta: ${sale.id}'),
                // ✅ CORREGIDO: sale.fecha ya es String o DateTime manejable
                pw.Text('Fecha: ${_formatDate(sale.fecha)}'),
                if (sale.clienteId != null)
                  pw.Text('Cliente ID: ${sale.clienteId}'),
                // ✅ ELIMINADO: sale.moneda no existe en el modelo Sale
                // pw.Text('Moneda: ${sale.moneda}'),
                pw.SizedBox(height: 10),
                
                pw.Divider(),
                pw.SizedBox(height: 5),
                
                // Tabla de productos
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Encabezados de tabla
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Cant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    // Líneas de productos
                    ...lines.map((line) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('${line.cantidad}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Prod #${line.productoId}', style: pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '\$${line.subtotal.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 5),
                
                // Totales
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    // ✅ CORREGIDO: Sin referencia a sale.moneda
                    pw.Text(
                      '\$${sale.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                if (sale.montoPagado > 0) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Pagado:'),
                      pw.Text('\$${sale.montoPagado.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                
                if (sale.montoPendiente > 0) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Pendiente:', style: pw.TextStyle(color: PdfColors.red)),
                      pw.Text('\$${sale.montoPendiente.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.red)),
                    ],
                  ),
                ],
                
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                // Pie - ✅ CORREGIDO: String con acentos entre comillas dobles
                pw.Center(
                  child: pw.Text(
                    'Gracias por su compra!',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  // ✅ CORREGIDO: Usar comillas dobles para evitar conflicto con apóstrofes
                  child: pw.Text(
                    "nova-ADEN - Sistema de Gestion",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/ticket_venta_${sale.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Imprimir o compartir
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'ticket_venta_${sale.id}.pdf',
      );

      return file;
    } catch (e) {
      print('Error generando PDF: $e');
      return null;
    }
  }

  // ✅ Helper: Formatear fecha - manejar String o DateTime
  static String _formatDate(dynamic fecha) {
    if (fecha is DateTime) {
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (fecha is String) {
      // Si ya es String, devolverlo o parsearlo si es necesario
      return fecha.length > 10 ? fecha.substring(0, 16) : fecha;
    }
    return DateTime.now().toString().substring(0, 16);
  }

  // ✅ MÉTODO ADICIONAL: Generar catálogo de productos (para RF 47)
  static Future<void> generateProductCatalog(List<dynamic> products) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Catalogo de Productos - Nova ADEN')),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Codigo', 'Nombre', 'Precio', 'Stock'],
            data: products.map((p) => [
              p.codigo ?? '',
              p.nombre,
              '\$${(p.precioVenta ?? 0).toStringAsFixed(2)}',
              '${p.stockActual ?? 0} ${p.unidadMedida ?? "und"}',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
