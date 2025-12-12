import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/notifiers/merchant_notifier.dart';
import '../widgets/amount_input_widget.dart';
import '../widgets/payment_token_display.dart';
import '../widgets/payment_status_widget.dart';

class MerchantScreen extends StatelessWidget {
  const MerchantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MerchantNotifier(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Merchant Payment Terminal'),
          centerTitle: true,
        ),
        body: const _MerchantScreenBody(),
      ),
    );
  }
}

class _MerchantScreenBody extends StatelessWidget {
  const _MerchantScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantNotifier>(
      builder: (context, notifier, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmountInputWidget(
                initialAmount: notifier.amount,
                onAmountChanged: (amount) {
                  notifier.setAmount(amount);
                },
              ),
              const SizedBox(height: 16),
              PaymentTokenDisplay(token: notifier.paymentToken),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: notifier.canStartPayment && !notifier.isScanning
                    ? () => notifier.startPaymentSession()
                    : null,
                icon: Icon(notifier.isScanning ? Icons.nfc : Icons.payment),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    notifier.isScanning ? 'Scanning...' : 'Start Payment',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
              if (notifier.isScanning) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => notifier.cancelPayment(),
                  child: const Text('Cancel Payment'),
                ),
              ],
              const SizedBox(height: 24),
              if (notifier.statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      if (notifier.isScanning)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (notifier.isScanning) const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          notifier.statusMessage,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              PaymentStatusWidget(transaction: notifier.currentTransaction),
              const SizedBox(height: 24),
              if (notifier.currentTransaction != null && !notifier.isScanning)
                OutlinedButton.icon(
                  onPressed: () => notifier.resetPayment(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Payment'),
                ),
            ],
          ),
        );
      },
    );
  }
}
