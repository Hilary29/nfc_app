import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/payment_request.dart';
import '../data/models/payment_response.dart';

class ClientNotifier extends ChangeNotifier {
  static const platform = MethodChannel('com.example.nfc_app/hce');

  bool _isHceActive = false;
  PaymentRequest? _pendingRequest;
  String _statusMessage = '';

  bool get isHceActive => _isHceActive;
  PaymentRequest? get pendingRequest => _pendingRequest;
  String get statusMessage => _statusMessage;
  bool get hasPendingPayment => _pendingRequest != null;

  ClientNotifier() {
    _setupMethodChannelListener();
  }

  void _setupMethodChannelListener() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMerchantDetected':
          _handleMerchantDetected();
          break;
        case 'onPaymentRequest':
          final data = call.arguments['data'] as String;
          _handlePaymentRequest(data);
          break;
        case 'onDeactivated':
          final reason = call.arguments['reason'] as String?;
          _handleDeactivated(reason);
          break;
      }
    });
  }

  Future<void> startHceMode() async {
    try {
      _isHceActive = true;
      _statusMessage = 'Card emulation active. Ready to receive payment requests.';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Failed to start HCE: $e';
      _isHceActive = false;
      notifyListeners();
    }
  }

  Future<void> stopHceMode() async {
    try {
      _isHceActive = false;
      _pendingRequest = null;
      _statusMessage = 'Card emulation stopped';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error stopping HCE: $e';
      notifyListeners();
    }
  }

  void _handleMerchantDetected() {
    _statusMessage = 'Merchant device detected';
    notifyListeners();
  }

  void _handlePaymentRequest(String jsonData) {
    try {
      final request = PaymentRequest.fromCompactJson(jsonData);
      _pendingRequest = request;
      _statusMessage = 'Payment request received: ${request.amount} FCFA';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error parsing payment request: $e';
      notifyListeners();
    }
  }

  void _handleDeactivated(String? reason) {
    if (_pendingRequest != null) {
      _statusMessage = 'Connection lost: ${reason ?? "Unknown"}';
      _pendingRequest = null;
    }
    notifyListeners();
  }

  Future<void> approvePayment() async {
    if (_pendingRequest == null) return;

    try {
      final response = PaymentResponse(
        approved: true,
        paymentToken: _pendingRequest!.paymentToken,
      );

      await _sendPaymentResponse(response, approved: true);

      _statusMessage = 'Payment approved and sent';
      _pendingRequest = null;
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error approving payment: $e';
      notifyListeners();
    }
  }

  Future<void> declinePayment() async {
    if (_pendingRequest == null) return;

    try {
      final response = PaymentResponse(
        approved: false,
        paymentToken: _pendingRequest!.paymentToken,
      );

      await _sendPaymentResponse(response, approved: false);

      _statusMessage = 'Payment declined';
      _pendingRequest = null;
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error declining payment: $e';
      notifyListeners();
    }
  }

  Future<void> _sendPaymentResponse(PaymentResponse response, {required bool approved}) async {
    try {
      final responseJson = response.toCompactJson();

      await platform.invokeMethod('sendResponse', {
        'approved': approved,
        'responseJson': responseJson,
      });
    } catch (e) {
      throw Exception('Failed to send response: $e');
    }
  }
}
