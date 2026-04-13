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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ SÍ A LA IZQUIERDA
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sí'),
                  ),
                ),
                const SizedBox(width: 16),
                // ✅ NO A LA DERECHA
                SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 2),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('No'),
                  ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sí'),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    child: const Text('No'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
