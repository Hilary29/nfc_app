import 'package:flutter/material.dart';
import '../../data/models/transaction.dart';
import '../../data/models/payment_response.dart';
import 'package:intl/intl.dart';

class PaymentStatusWidget extends StatelessWidget {
  final Transaction? transaction;

  const PaymentStatusWidget({super.key, this.transaction});

  @override
  Widget build(BuildContext context) {
    if (transaction == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: _getStatusColor(transaction!.status),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(transaction!.status),
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(transaction!.status),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (transaction!.response != null) ...[
              const SizedBox(height: 16),
              _buildResponseDetails(transaction!.response!),
            ],
            if (transaction!.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                transaction!.errorMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponseDetails(PaymentResponse response) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Approved', response.approved == true ? 'YES' : 'NO'),
          _buildDetailRow('Token', response.paymentToken ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TransactionStatus? status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.blue;
      case TransactionStatus.scanning:
        return Colors.orange;
      case TransactionStatus.processing:
        return Colors.amber;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(TransactionStatus? status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.scanning:
        return Icons.nfc;
      case TransactionStatus.processing:
        return Icons.hourglass_bottom;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(TransactionStatus? status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Payment Initiated';
      case TransactionStatus.scanning:
        return 'Scanning Device...';
      case TransactionStatus.processing:
        return 'Processing Payment...';
      case TransactionStatus.completed:
        return 'Payment Complete';
      case TransactionStatus.failed:
        return 'Payment Failed';
      case TransactionStatus.cancelled:
        return 'Payment Cancelled';
      default:
        return 'Unknown';
    }
  }
}
