import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/transaction.dart';

class MerchantNotifier extends ChangeNotifier {
  double _amount = 0.0;
  String _paymentToken = '';
  Transaction? _currentTransaction;
  bool _isScanning = false;
  String _statusMessage = '';

  static const String MERCHANT_ID = 'MERCHANT_001';
  final _uuid = const Uuid();

  double get amount => _amount;
  String get paymentToken => _paymentToken;
  Transaction? get currentTransaction => _currentTransaction;
  bool get isScanning => _isScanning;
  String get statusMessage => _statusMessage;
  bool get canStartPayment => _amount > 0;

  void setAmount(double value) {
    _amount = value;
    _paymentToken = _uuid.v4();
    notifyListeners();
  }

  void resetPayment() {
    _amount = 0.0;
    _paymentToken = '';
    _currentTransaction = null;
    _isScanning = false;
    _statusMessage = '';
    notifyListeners();
  }

  Future<void> startPaymentSession() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        _statusMessage = 'NFC not available. Please enable NFC.';
        notifyListeners();
        return;
      }

      final request = PaymentRequest(
        merchantId: MERCHANT_ID,
        amount: _amount,
        paymentToken: _paymentToken,
      );

      _currentTransaction = Transaction(
        request: request,
        status: TransactionStatus.pending,
        createdAt: DateTime.now(),
      );
      _isScanning = true;
      _statusMessage = 'Waiting for customer device...';
      notifyListeners();

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          await _handleNfcTag(tag);
        },
        onError: (error) async {
          _handleError('NFC Error: ${error.message}');
          await NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      _handleError('Failed to start payment: $e');
    }
  }

  Future<void> _handleNfcTag(NfcTag tag) async {
    try {
      _currentTransaction = _currentTransaction?.copyWith(
        status: TransactionStatus.scanning,
      );
      _statusMessage = 'Reading payment data...';
      notifyListeners();

      final isoDep = IsoDep.from(tag);
      if (isoDep == null) {
        _handleError('Device does not support payment mode');
        await NfcManager.instance.stopSession();
        return;
      }

      final requestJson = _currentTransaction!.request?.toCompactJson();
      final requestBytes = Uint8List.fromList(utf8.encode(requestJson!));

      final selectApdu = Uint8List.fromList([
        0x00, 0xA4, 0x04, 0x00, 0x07,
        0xF0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06,
      ]);

      Uint8List? selectResponse = await isoDep.transceive(data: selectApdu);

      if (selectResponse == null || selectResponse.length < 2) {
        _handleError('No response from payment device');
        await NfcManager.instance.stopSession();
        return;
      }

      final sw1 = selectResponse[selectResponse.length - 2];
      final sw2 = selectResponse[selectResponse.length - 1];

      if (sw1 != 0x90 || sw2 != 0x00) {
        _handleError(
            'Payment app not available (SW: ${sw1.toRadixString(16)}${sw2.toRadixString(16)})');
        await NfcManager.instance.stopSession();
        return;
      }

      final paymentApdu = Uint8List.fromList([
        0x80, 0x01, 0x00, 0x00,
        requestBytes.length,
        ...requestBytes,
      ]);

      Uint8List? paymentResponse = await isoDep.transceive(data: paymentApdu);

      if (paymentResponse == null || paymentResponse.length < 2) {
        _handleError('No payment response received');
        await NfcManager.instance.stopSession();
        return;
      }

      final responseData =
          paymentResponse.sublist(0, paymentResponse.length - 2);
      final responseJson = utf8.decode(responseData);

      final response = PaymentResponse.fromCompactJson(responseJson);

      _currentTransaction = _currentTransaction?.copyWith(
        response: response,
        status: TransactionStatus.completed,
      );
      _statusMessage = (response.approved == true) ? 'Payment approved!' : 'Payment declined';
      _isScanning = false;
      notifyListeners();

      await NfcManager.instance.stopSession();
    } catch (e) {
      _handleError('Error reading payment: $e');
      await NfcManager.instance.stopSession();
    }
  }

  void _handleError(String error) {
    _currentTransaction = _currentTransaction?.copyWith(
      status: TransactionStatus.failed,
    );
    _statusMessage = error;
    _isScanning = false;
    notifyListeners();
  }

  Future<void> cancelPayment() async {
    if (_isScanning) {
      await NfcManager.instance.stopSession();
      _currentTransaction = _currentTransaction?.copyWith(
        status: TransactionStatus.cancelled,
      );
      _isScanning = false;
      _statusMessage = 'Payment cancelled';
      notifyListeners();
    }
  }
}
