import 'package:flutter/material.dart';

class CommonDialogs {
  // ✅ DIÁLOGO DE ELIMINACIÓN (SÍ IZQ - NO DER)
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    Color? confirmColor,
    Color? cancelColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Eliminar "${itemName}"?'),
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

  // ✅ CONFIRMACIÓN GENERAR PDF
  static Future<bool?> showTicketGenerationConfirmation({required BuildContext context}) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('🧾 Ticket de Venta'),
        content: const Text('¿Desea generar y compartir el ticket en PDF?'),
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
