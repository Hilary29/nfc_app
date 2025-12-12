import 'dart:convert';

class PaymentRequest {
  final String? merchantId;
  final double? amount;
  final String? paymentToken;

  PaymentRequest({
    this.merchantId,
    this.amount,
    this.paymentToken,
  });

  Map<String, dynamic> toJson() => {
        'merchantId': merchantId,
        'amount': amount,
        'paymentToken': paymentToken,
      };

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => PaymentRequest(
        merchantId: json['merchantId'] as String,
        amount: (json['amount'] as num).toDouble(),
        paymentToken: json['paymentToken'] as String,
      );

  String toCompactJson() => jsonEncode(toJson());

  factory PaymentRequest.fromCompactJson(String jsonStr) =>
      PaymentRequest.fromJson(jsonDecode(jsonStr));
}
