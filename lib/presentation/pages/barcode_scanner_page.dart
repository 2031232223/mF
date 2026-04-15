import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// NOTA: Para escáner real se necesita la dependencia mobile_scanner
// Esta implementación usa el teclado como escáner (los escáners USB/Bluetooth
// funcionan como teclado y envían el código + Enter)

class BarcodeScannerPage extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const BarcodeScannerPage({
    super.key,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastScanned = '';
  List<String> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    // Mantener el foco para recibir entrada del escáner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleBarcode(String barcode) {
    if (barcode.isEmpty) return;
    
    setState(() {
      _lastScanned = barcode;
      _scanHistory.insert(0, barcode);
      if (_scanHistory.length > 10) _scanHistory.removeLast();
    });

    widget.onBarcodeScanned(barcode);
    
    // Mostrar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Código escaneado: $barcode'),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 1),
      ),
    );

    // Limpiar para próximo escaneo
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📷 Escáner de Código de Barras'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Instrucciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Modo de Escaneo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Conecta tu escáner USB/Bluetooth o usa el teclado para ingresar códigos manualmente.\n\nLos escáners funcionan como teclado y envían el código automáticamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Campo de entrada
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Código de Barras',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _focusNode.requestFocus();
                  },
                ),
              ),
              onSubmitted: _handleBarcode,
              autofocus: true,
            ),
            
            const SizedBox(height: 24),
            
            // Último escaneado
            if (_lastScanned.isNotEmpty)
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Último código escaneado'),
                  subtitle: Text(_lastScanned, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Historial
            Expanded(
              child: _scanHistory.isEmpty
                  ? const Center(child: Text('Sin escaneos recientes', style: TextStyle(color: Colors.grey)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Historial reciente:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _scanHistory.length,
                            itemBuilder: (ctx, i) => ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(_scanHistory[i]),
                              subtitle: Text('Hace ${i + 1} escaneos'),
                              dense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
