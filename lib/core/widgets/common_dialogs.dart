import 'package:flutter/material.dart';

class CommonDialogs {
  // ✅ DIÁLOGO DE CONFIRMACIÓN DE ELIMINACIÓN (SÍ a izquierda, NO a derecha)
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    IconData? icon,
    String? message,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirmar Eliminación'),
          ],
        ),
        content: Text(message ?? '¿Eliminar "${itemName}"?'),
        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DIÁLOGO PARA GENERAR PDF (Ticket de venta)
  static Future<bool?> showTicketGenerationConfirmation({
    required BuildContext context,
    String mensaje = '¿Desea generar y compartir el ticket en PDF?',
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.receipt, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Text('🧾 Ticket de Venta'),
        ]),
        content: Text(mensaje),
        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
            ),
          ),
        ],
      ),
    );
  }
}
