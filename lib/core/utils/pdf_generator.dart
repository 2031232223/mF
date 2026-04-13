import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/sale.dart'; // Importa solo una vez
// ✅ IMPORTANTE: No definas class SaleLine aquí. Usa la que está en sale.dart

class PdfGenerator {
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
                pw.Center(child: pw.Text(nombreEmpresa.toUpperCase())),
                pw.SizedBox(height: 5),
                pw.Center(child: pw.Text('TICKET DE VENTA')),
                pw.Divider(),
                pw.SizedBox(height: 5),
                
                pw.Text('No. Venta: ${sale.id}'),
                pw.Text('Fecha: ${_formatDate(sale.fecha)}'),
                if (sale.clienteId != null) pw.Text('Cliente ID: ${sale.clienteId}'),
                pw.SizedBox(height: 10),
                
                pw.Divider(),
                pw.SizedBox(height: 5),
                
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Subtotal', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...lines.map((line) => pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${line.cantidad}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Prod #${line.productoId}', style: pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('\$${line.subtotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    ])).toList(),
                  ],
                ),
                
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${sale.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ]),
                
                if (sale.montoPagado > 0) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Pagado:'), pw.Text('\$${sale.montoPagado.toStringAsFixed(2)}')]),
                ],
                
                if (sale.montoPendiente > 0) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Pendiente:', style: pw.TextStyle(color: PdfColors.red)), pw.Text('\$${sale.montoPendiente.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.red))]),
                ],
                
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.Center(child: pw.Text('Gracias por su compra!')),
                pw.Center(child: pw.Text("nova-ADEN - Sistema de Gestion", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/ticket_venta_${sale.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'ticket_venta_${sale.id}.pdf');
      return file;
    } catch (e) {
      print('Error generando PDF: $e');
      return null;
    }
  }

  static String _formatDate(dynamic fecha) {
    if (fecha is DateTime) {
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (fecha is String) {
      return fecha.length > 10 ? fecha.substring(0, 16) : fecha;
    }
    return DateTime.now().toString().substring(0, 16);
  }
}
