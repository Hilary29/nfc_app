import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';

class ClientNotifier extends ChangeNotifier {
  bool _isHceActive = false;
  PaymentRequest? _pendingRequest;
  String _statusMessage = '';
  //String _customerId = 'CUSTOMER_001';
  //String _cardId = 'CARD_12345';

  bool get isHceActive => _isHceActive;
  PaymentRequest? get pendingRequest => _pendingRequest;
  String get statusMessage => _statusMessage;
  //String get customerId => _customerId;
  //String get cardId => _cardId;
  bool get hasPendingPayment => _pendingRequest != null;

  Future<void> startHceMode() async {
    try {
      _isHceActive = true;
      _statusMessage = 'Card emulation active. Ready to receive payment requests.';
      notifyListeners();

      _listenForApduCommands();
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

  void _listenForApduCommands() {
  }

  void _handleApduCommand(Uint8List command) {
    try {
      if (command.length < 5) return;

      final cla = command[0];
      final ins = command[1];

      if (cla == 0x00 && ins == 0xA4) {
        _handleSelectCommand(command);
      } else if (cla == 0x80 && ins == 0x01) {
        _handlePaymentCommand(command);
      }
    } catch (e) {
      _statusMessage = 'Error handling APDU: $e';
      notifyListeners();
    }
  }

  void _handleSelectCommand(Uint8List command) {
    _statusMessage = 'Merchant device detected';
    notifyListeners();
  }

  void _handlePaymentCommand(Uint8List command) {
    try {
      final lc = command[4];
      final data = command.sublist(5, 5 + lc);
      final jsonStr = utf8.decode(data);

      final request = PaymentRequest.fromCompactJson(jsonStr);
      _pendingRequest = request;
      _statusMessage = 'Payment request received: ${request.amount} FCFA';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error parsing payment request: $e';
      notifyListeners();
    }
  }

  Future<void> approvePayment() async {
    if (_pendingRequest == null) return;

    try {
      final response = PaymentResponse(
        approved: true,
        paymentToken: _pendingRequest!.paymentToken,
      );

      await _sendPaymentResponse(response);

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

      await _sendPaymentResponse(response);

      _statusMessage = 'Payment declined';
      _pendingRequest = null;
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error declining payment: $e';
      notifyListeners();
    }
  }

  Future<void> _sendPaymentResponse(PaymentResponse response) async {
    try {
      final responseJson = response.toCompactJson();
      final responseBytes = utf8.encode(responseJson);

      final apduResponse = Uint8List.fromList([
        ...responseBytes,
        0x90, 0x00,
      ]);

    } catch (e) {
      throw Exception('Failed to send response: $e');
    }
  }
}
