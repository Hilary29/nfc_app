import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../notifiers/merchant_hce_notifier.dart';
import '../../data/models/transaction.dart';

class MerchantHceScreen extends StatelessWidget {
  const MerchantHceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MerchantHceNotifier(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Merchant - HCE NDEF'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const _MerchantHceBody(),
      ),
    );
  }
}

class _MerchantHceBody extends StatelessWidget {
  const _MerchantHceBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantHceNotifier>(
      builder: (context, notifier, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Input
              _AmountInputCard(notifier: notifier),

              const SizedBox(height: 20),

              // Payment Controls
              if (!notifier.isHceActive)
                _StartPaymentButton(notifier: notifier)
              else
                _ActivePaymentCard(notifier: notifier),

              const SizedBox(height: 20),

              // Transaction Status
              if (notifier.currentTransaction != null)
                _TransactionStatusCard(notifier: notifier),

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

class _AmountInputCard extends StatefulWidget {
  final MerchantHceNotifier notifier;

  const _AmountInputCard({Key? key, required this.notifier}) : super(key: key);

  @override
  State<_AmountInputCard> createState() => _AmountInputCardState();
}

class _AmountInputCardState extends State<_AmountInputCard> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              enabled: !widget.notifier.isHceActive,
              decoration: const InputDecoration(
                labelText: 'Amount (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                widget.notifier.setAmount(amount);
              },
            ),
            if (widget.notifier.amount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Amount: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(widget.notifier.amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StartPaymentButton extends StatelessWidget {
  final MerchantHceNotifier notifier;

  const _StartPaymentButton({Key? key, required this.notifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: notifier.canStartPayment
          ? () => notifier.startHcePaymentSession()
          : null,
      icon: const Icon(Icons.nfc),
      label: const Text('Start Payment Session'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
      ),
    );
  }
}

class _ActivePaymentCard extends StatelessWidget {
  final MerchantHceNotifier notifier;

  const _ActivePaymentCard({Key? key, required this.notifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.nfc,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'HCE Active',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for client to scan...',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Text(
                '${notifier.remainingSeconds}s remaining',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Cancel Button
            ElevatedButton.icon(
              onPressed: () => notifier.cancelPayment(),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionStatusCard extends StatelessWidget {
  final MerchantHceNotifier notifier;

  const _TransactionStatusCard({Key? key, required this.notifier})
      : super(key: key);

  Color _getStatusColor(TransactionStatus? status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(TransactionStatus? status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = notifier.currentTransaction!;
    final statusColor = _getStatusColor(transaction.status);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(transaction.status),
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Transaction Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Merchant ID',
              value: transaction.request?.merchantId ?? 'N/A',
            ),
            _InfoRow(
              label: 'Amount',
              value: NumberFormat.currency(
                symbol: 'FCFA ',
                decimalDigits: 0,
              ).format(transaction.request?.amount ?? 0),
            ),
            _InfoRow(
              label: 'Token',
              value: transaction.request?.paymentToken?.substring(0, 8) ?? 'N/A',
              monospace: true,
            ),
            _InfoRow(
              label: 'Status',
              value: transaction.status?.toString().split('.').last ?? 'Unknown',
            ),
            if (transaction.createdAt != null)
              _InfoRow(
                label: 'Created',
                value: DateFormat('HH:mm:ss').format(transaction.createdAt!),
              ),
            const SizedBox(height: 16),
            // Reset Button
            if (transaction.status == TransactionStatus.cancelled ||
                transaction.status == TransactionStatus.completed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => notifier.resetPayment(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.monospace = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
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
