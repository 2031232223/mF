import 'package:flutter/material.dart';

class DiscountDialog extends StatefulWidget {
  final double totalAmount;
  final double currentDiscount;

  const DiscountDialog({
    super.key,
    required this.totalAmount,
    this.currentDiscount = 0.0,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late TextEditingController _controller;
  String _discountType = 'percentage'; // 'percentage' o 'fixed'

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentDiscount > 0 
          ? widget.currentDiscount.toStringAsFixed(2) 
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _discountValue => double.tryParse(_controller.text) ?? 0.0;
  
  double get _finalDiscount {
    if (_discountType == 'percentage') {
      return widget.totalAmount * (_discountValue / 100);
    }
    return _discountValue;
  }

  double get _finalTotal => widget.totalAmount - _finalDiscount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aplicar Descuento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tipo de descuento
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  value: 'percentage',
                  groupValue: _discountType,
                  onChanged: (v) => setState(() => _discountType = v!),
                  title: const Text('Porcentaje %'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  value: 'fixed',
                  groupValue: _discountType,
                  onChanged: (v) => setState(() => _discountType = v!),
                  title: const Text('Monto fijo \$'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Input de descuento
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _discountType == 'percentage' ? 'Porcentaje (%)' : 'Monto (\$)',
              prefixText: _discountType == 'percentage' ? '% ' : '\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Resumen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', '\$${widget.totalAmount.toStringAsFixed(2)}'),
                _buildSummaryRow('Descuento', '-\$${_finalDiscount.toStringAsFixed(2)}', color: Colors.green),
                const Divider(),
                _buildSummaryRow('Total', '\$${_finalTotal.toStringAsFixed(2)}', isTotal: true),
              ],
            ),
          ),
        ],
      ),
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
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
