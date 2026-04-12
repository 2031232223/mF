import 'package:flutter/material.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _feedbackCtrl = TextEditingController();
  final List<Map<String, dynamic>> _faqs = [
    {'q': '¿Cómo vendo en otra moneda?', 'a': 'En el POS, toca el selector de moneda (CUP/MLC/USD). Los precios se convierten automáticamente según la tasa configurada.'},
    {'q': '¿Cómo duplico un producto?', 'a': 'En Inventario, toca el ícono de copiar (📋) junto al producto. Se abrirá el formulario con los datos prellenados.'},
    {'q': '¿Qué pasa si archivo un producto?', 'a': 'Se oculta de la lista principal. Puedes verlo tocando el ícono de archivo (📦) en la barra superior.'},
    {'q': '¿Dónde se guardan los respaldos?', 'a': 'En la carpeta externa "NovaAden_Backups" comprimidos en .zip con validación de integridad.'},
    {'q': '¿Cómo cambio las tasas de cambio?', 'a': 'Ve a Configuración > Monedas y Tasas. Ingresa el valor actual del día.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('❓ Ayuda y Feedback'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preguntas Frecuentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._faqs.map((faq) => ExpansionTile(
              title: Text(faq['q'], style: const TextStyle(fontWeight: FontWeight.w500)),
              children: [Padding(padding: const EdgeInsets.all(16), child: Text(faq['a'], style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : Colors.black54)))],
            )),
            const SizedBox(height: 24),
            const Text('Enviar Retroalimentación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 5,
              decoration: InputDecoration(hintText: 'Escribe tu sugerencia o reporte...', border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_feedbackCtrl.text.trim().isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Feedback enviado. ¡Gracias!'), backgroundColor: Colors.green),
                    );
                    _feedbackCtrl.clear();
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('ENVIAR FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
