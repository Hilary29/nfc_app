import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../notifiers/client_nfc_reader_notifier.dart';
import '../../data/models/payment_request.dart';

class ClientNfcReaderScreen extends StatelessWidget {
  const ClientNfcReaderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientNfcReaderNotifier(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Client - NFC Reader'),
          backgroundColor: Colors.teal,
        ),
        body: const _ClientNfcReaderBody(),
      ),
    );
  }
}

class _ClientNfcReaderBody extends StatelessWidget {
  const _ClientNfcReaderBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientNfcReaderNotifier>(
      builder: (context, notifier, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scan Controls
              if (!notifier.isScanning && !notifier.hasPendingPayment)
                _ScanControlCard(notifier: notifier),

              // Scanning Indicator
              if (notifier.isScanning) _ScanningCard(notifier: notifier),

              // Payment Approval
              if (notifier.hasPendingPayment)
                _PaymentApprovalCard(notifier: notifier),

              // Payment Result
              if (notifier.approvalStatus != null &&
                  notifier.approvalStatus != PaymentApprovalStatus.pending)
                _PaymentResultCard(notifier: notifier),

              const SizedBox(height: 20),

              // Status Message
              if (notifier.statusMessage.isNotEmpty)
                _StatusMessageCard(message: notifier.statusMessage),
            ],
          ),
        );
      },
    );
  }
}

class _ScanControlCard extends StatelessWidget {
  final ClientNfcReaderNotifier notifier;

  const _ScanControlCard({Key? key, required this.notifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.nfc,
              size: 80,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ready to Scan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to start scanning for payment requests',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => notifier.startNfcReaderMode(),
              icon: const Icon(Icons.radar),
              label: const Text('Start Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningCard extends StatelessWidget {
  final ClientNfcReaderNotifier notifier;

  const _ScanningCard({Key? key, required this.notifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scanning...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hold your phone near the merchant device',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => notifier.stopNfcReaderMode(),
              icon: const Icon(Icons.stop),
              label: const Text('Stop Scanning'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentApprovalCard extends StatelessWidget {
  final ClientNfcReaderNotifier notifier;

  const _PaymentApprovalCard({Key? key, required this.notifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final request = notifier.detectedRequest!;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.orange, size: 32),
                SizedBox(width: 12),
                Text(
                  'Payment Request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _PaymentInfoRow(
              label: 'Merchant',
              value: request.merchantId ?? 'Unknown',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      symbol: 'FCFA ',
                      decimalDigits: 0,
                    ).format(request.amount ?? 0),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _PaymentInfoRow(
              label: 'Token',
              value: request.paymentToken?.substring(0, 12) ?? 'N/A',
              monospace: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Do you want to approve this payment?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => notifier.declinePayment(),
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => notifier.approvePayment(),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentResultCard extends StatelessWidget {
  final ClientNfcReaderNotifier notifier;

  const _PaymentResultCard({Key? key, required this.notifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isApproved =
        notifier.approvalStatus == PaymentApprovalStatus.approved;
    final request = notifier.detectedRequest!;

    return Card(
      elevation: 4,
      color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isApproved ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: isApproved ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isApproved ? 'Payment Approved' : 'Payment Declined',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isApproved ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                symbol: 'FCFA ',
                decimalDigits: 0,
              ).format(request.amount ?? 0),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(height: 8),
                  Text(
                    isApproved
                        ? 'Your approval has been recorded locally.\n\nNote: No automatic confirmation was sent to the merchant.'
                        : 'Payment was declined.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => notifier.resetSession(),
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _PaymentInfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.monospace = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: monospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _StatusMessageCard extends StatelessWidget {
  final String message;

  const _StatusMessageCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
