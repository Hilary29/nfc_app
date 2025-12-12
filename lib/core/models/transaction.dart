import 'payment_request.dart';
import 'payment_response.dart';

class Transaction {
  final PaymentRequest? request;
  final PaymentResponse? response;
  final TransactionStatus? status;
  final String? errorMessage;
  final DateTime? createdAt;

  Transaction({
    this.request,
    this.response,
    this.status,
    this.errorMessage,
    this.createdAt,
  });

  Transaction copyWith({
    PaymentRequest? request,
    PaymentResponse? response,
    TransactionStatus? status,
    DateTime? createdAt,
  }) {
    return Transaction(
      request: request ?? this.request,
      response: response ?? this.response,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isSuccessful =>
      status == TransactionStatus.completed && response?.approved == true;
}

enum TransactionStatus {
  pending,
  scanning,
  processing,
  completed,
  failed,
  cancelled,
}
