import 'package:flutter/material.dart';

class CommonDialogs {
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    String? title,
    String? content,
    String? message,
    String? itemName,
  }) {
    final dialogContent = content ?? message ?? '¿Estás seguro?';
    final dialogTitle = title ?? (itemName != null ? 'Eliminar $itemName' : 'Confirmar');
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(dialogTitle, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          content: Text(dialogContent, style: const TextStyle(color: Colors.white)),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop(false);
                  },
                  child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        content: Text(content, style: const TextStyle(color: Colors.white)),
        actions: <Widget>[
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
