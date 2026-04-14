import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sale.dart';
import '../database/database_helper.dart';

class PdfGenerator {
  static Future<File?> generateSaleTicket({
    required Sale sale,
    required List<SaleLine> lines,
    String nombreEmpresa = 'Nova ADEN',
  }) async {
    final pdf = pw.Document();

    String nombreCliente = 'Cliente General';
    if (sale.clienteId != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final result = await db.query('clientes', where: 'id = ?', whereArgs: [sale.clienteId]);
        if (result.isNotEmpty) nombreCliente = result.first['nombre'] as String;
      } catch (e) { print('Error obteniendo cliente: $e'); }
    }

    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.roll80, build: (pw.Context context) {
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Column(children: [
          pw.Text(nombreEmpresa, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Ticket de Venta', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text('Fecha: ${_formatDate(sale.fecha)}', style: pw.TextStyle(fontSize: 10)),
          pw.Text('Ticket #: ${sale.id}', style: pw.TextStyle(fontSize: 10)),
          pw.Divider(),
        ])),
        pw.Text('Cliente: $nombreCliente', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        if (sale.moneda != 'CUP') pw.Text('Moneda: ${sale.moneda} (Tasa: ${sale.tasaCambio})', style: pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Expanded(child: pw.Text('Producto', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          pw.Text('Cant.', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text('Precio', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text('Subtotal', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.Divider(),
        ...lines.map((line) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Expanded(child: pw.Text(line.productoNombre.isNotEmpty ? line.productoNombre : 'Producto #${line.productoId}', style: pw.TextStyle(fontSize: 9), maxLines: 2)),
          pw.Text('${line.cantidad}', style: pw.TextStyle(fontSize: 9)),
          pw.Text('${sale.moneda} ${line.precioUnitario.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9)),
          pw.Text('${sale.moneda} ${line.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9)),
        ])),
        pw.Divider(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 10)),
          pw.Text('${sale.moneda} ${sale.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
        ]),
        if (sale.descuento > 0) pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Descuento:', style: pw.TextStyle(fontSize: 10)),
          pw.Text('- ${sale.moneda} ${sale.descuento.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.green)),
        ]),
        pw.SizedBox(height: 4),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('${sale.moneda} ${sale.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.Text('Monto Pagado: ${sale.moneda} ${sale.montoPagado.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
        if (sale.esFiado && sale.montoPendiente > 0) pw.Text('Pendiente: ${sale.moneda} ${sale.montoPendiente.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.orange)),
        pw.SizedBox(height: 16),
        pw.Center(child: pw.Column(children: [
          pw.Text('¡Gracias por su compra!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(nombreEmpresa, style: pw.TextStyle(fontSize: 9)),
          pw.Text('Generado: ${DateTime.now().toString().split('.').first}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ])),
      ]);
    }));

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/ticket_venta_${sale.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) { print('Error generando PDF: $e'); return null; }
  }

  static String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
