import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountInputWidget extends StatefulWidget {
  final double initialAmount;
  final ValueChanged<double> onAmountChanged;

  const AmountInputWidget({
    super.key,
    required this.initialAmount,
    required this.onAmountChanged,
  });

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  late TextEditingController _controller;
  final _currencyFormat =
      NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.isEmpty) {
      widget.onAmountChanged(0.0);
      return;
    }

    final amount = double.tryParse(value) ?? 0.0;
    widget.onAmountChanged(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0',
                border: OutlineInputBorder(),
                suffixText: 'FCFA',
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              onChanged: _onChanged,
            ),
            if (widget.initialAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Amount: ${_currencyFormat.format(widget.initialAmount)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
