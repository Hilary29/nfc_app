import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentTokenDisplay extends StatelessWidget {
  final String token;

  const PaymentTokenDisplay({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    if (token.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Token',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    token,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: token));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Token copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
