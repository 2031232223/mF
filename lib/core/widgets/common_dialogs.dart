import 'package:flutter/material.dart';

class CommonDialogs {
  /// Diálogo de confirmación con botones Sí/No
  /// Compatible con llamadas que usan: title, content, message, itemName
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    String? title,
    String? content,
    String? message,      // alias para content (compatibilidad con backup_page)
    String? itemName,     // opcional: nombre del item a confirmar
  }) {
    // Usar message como content si content no se proporciona
    final dialogContent = content ?? message ?? '¿Estás seguro?';
    final dialogTitle = title ?? (itemName != null ? 'Eliminar $itemName' : '¿Estás seguro?');
    
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
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
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Diálogo de información simple
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        content: Text(content, style: const TextStyle(color: Colors.white)),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
