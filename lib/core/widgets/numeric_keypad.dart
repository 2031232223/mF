import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onDigitPressed;
  final Function() onBackspacePressed;
  final Function() onClearPressed;
  final Function() onDonePressed;
  final String currentValue;
  final String? label;
  final bool showDecimal;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
    required this.onDonePressed,
    required this.currentValue,
    this.label,
    this.showDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[900] 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Valor actual
          if (label != null) ...[
            Text(label!, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 8),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[800] 
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
            ),
            child: Text(
              currentValue.isEmpty ? '0' : currentValue,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 16),
          
          // Teclado numérico
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildKey('7', context),
              _buildKey('8', context),
              _buildKey('9', context),
              _buildKey('4', context),
              _buildKey('5', context),
              _buildKey('6', context),
              _buildKey('1', context),
              _buildKey('2', context),
              _buildKey('3', context),
              _buildKey('0', context),
              if (showDecimal) _buildKey('.', context),
              _buildKeyWidget(
                icon: Icons.backspace,
                color: Colors.orange,
                onPressed: onBackspacePressed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onClearPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('C', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onDonePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('CONFIRMAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit, BuildContext context) {
    return _buildKeyWidget(
      label: digit,
      color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey[800] 
          : Colors.white,
      textColor: Colors.black87,
      onPressed: () => onDigitPressed(digit),
    );
  }

  Widget _buildKeyWidget({
    String? label,
    IconData? icon,
    Color? color,
    Color? textColor,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: label != null 
          ? Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
          : Icon(icon, size: 28),
    );
  }
}
