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
    return Container(
      color: Colors.grey[200],
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
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () => onNumberPressed(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
        ),
        child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
