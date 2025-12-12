import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../notifiers/client_notifier.dart';
import '../widgets/card_display_widget.dart';
import '../widgets/payment_approval_widget.dart';

class ClientScreen extends StatelessWidget {
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientNotifier(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Client Payment Card'),
          centerTitle: true,
        ),
        body: const _ClientScreenBody(),
      ),
    );
  }
}

class _ClientScreenBody extends StatelessWidget {
  const _ClientScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientNotifier>(
      builder: (context, notifier, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardDisplayWidget(
                cardId: '',
                customerId: '',
                isActive: notifier.isHceActive,
              ),
              const SizedBox(height: 24),
              if (!notifier.isHceActive)
                ElevatedButton.icon(
                  onPressed: () => notifier.startHceMode(),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Activate Card',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => notifier.stopHceMode(),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Deactivate Card',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (notifier.statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notifier.isHceActive
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: notifier.isHceActive
                          ? Colors.green.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        notifier.isHceActive ? Icons.check_circle : Icons.info,
                        color: notifier.isHceActive ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          notifier.statusMessage,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              if (notifier.hasPendingPayment && notifier.pendingRequest != null)
                PaymentApprovalWidget(
                  request: notifier.pendingRequest!,
                  onApprove: () => notifier.approvePayment(),
                  onDecline: () => notifier.declinePayment(),
                ),
              if (notifier.isHceActive && !notifier.hasPendingPayment)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Bring your phone close to the merchant terminal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
