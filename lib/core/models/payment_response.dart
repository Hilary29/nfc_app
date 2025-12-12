import 'dart:convert';

class PaymentResponse {
  bool? approved;
  String? paymentToken;

  PaymentResponse({
    this.approved,
    this.paymentToken,
  });

  Map<String, dynamic> toJson() => {
        'approved': approved,
        'paymentToken': paymentToken,
      };

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      PaymentResponse(
        approved: json['approved'] as bool,
        paymentToken: json['paymentToken'] as String,
      );

  String toCompactJson() => jsonEncode(toJson());

  factory PaymentResponse.fromCompactJson(String jsonStr) =>
      PaymentResponse.fromJson(jsonDecode(jsonStr));
}
