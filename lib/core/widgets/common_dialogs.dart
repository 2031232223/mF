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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SÍ A LA IZQUIERDA (Verde)
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 36),
                    ),
                    child: const Text('Sí'),
                  ),
                ),
                const SizedBox(width: 16),
                // NO A LA DERECHA (Rojo)
                SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red, width: 2),
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
