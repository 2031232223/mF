import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final void Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(children: _buildNumRow(['1', '2', '3'])),
          Row(children: _buildNumRow(['4', '5', '6'])),
          Row(children: _buildNumRow(['7', '8', '9'])),
          Row(children: [
            Expanded(child: _buildNumButton('0')),
            Expanded(child: _buildNumButton('.')),
            Expanded(child: IconButton(icon: const Icon(Icons.backspace, color: Colors.red), onPressed: onBackspace)),
          ]),
          Row(children: [Expanded(child: _buildActionBtn('C', onClear, Colors.orange))]),
        ],
      ),
    );
  }

  List<Widget> _buildNumRow(List<String> nums) {
    return nums.map((n) => Expanded(child: _buildNumButton(n))).toList();
  }

  Widget _buildNumButton(String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () => onNumberPressed(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: isDark ? Colors.white : Colors.black,
        ),
        child: Text(
          text, 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionBtn(String text, VoidCallback action, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: Colors.white,
        ),
        child: Text(
          text, 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
