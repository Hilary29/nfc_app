import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../data/models/payment_request.dart';
import '../data/models/transaction.dart';

class MerchantHceNotifier extends ChangeNotifier {
  static const platform = MethodChannel('com.example.nfc_app/merchant_hce');
  static const String MERCHANT_ID = 'MERCHANT_001';

  double _amount = 0.0;
  String _paymentToken = '';
  Transaction? _currentTransaction;
  bool _isHceActive = false;
  String _statusMessage = '';
  Timer? _timeoutTimer;

  static const Duration TIMEOUT_DURATION = Duration(seconds: 60);
  int _remainingSeconds = 60;

  final _uuid = const Uuid();

  // Getters
  double get amount => _amount;
  String get paymentToken => _paymentToken;
  Transaction? get currentTransaction => _currentTransaction;
  bool get isHceActive => _isHceActive;
  String get statusMessage => _statusMessage;
  int get remainingSeconds => _remainingSeconds;
  bool get canStartPayment => _amount > 0 && !_isHceActive;

  void setAmount(double value) {
    _amount = value;
    _paymentToken = _uuid.v4();
    notifyListeners();
  }

  Future<void> startHcePaymentSession() async {
    try {
      // 1. Créer PaymentRequest
      final request = PaymentRequest(
        merchantId: MERCHANT_ID,
        amount: _amount,
        paymentToken: _paymentToken,
      );

      // 2. Créer Transaction
      _currentTransaction = Transaction(
        request: request,
        status: TransactionStatus.pending,
        createdAt: DateTime.now(),
      );

      // 3. Activer HCE NDEF
      await _activateNdefHce(request.toCompactJson());

      // 4. Démarrer timeout
      _startTimeout();

      _isHceActive = true;
      _statusMessage = 'HCE Active - Waiting for client...';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Failed to start HCE session: $e';
      _isHceActive = false;
      notifyListeners();
    }
  }

  Future<void> _activateNdefHce(String jsonPayload) async {
    try {
      await platform.invokeMethod('setNdefPayload', {
        'payload': jsonPayload,
      });
    } catch (e) {
      _statusMessage = 'Failed to activate HCE: $e';
      notifyListeners();
      rethrow;
    }
  }

  void _startTimeout() {
    _remainingSeconds = 30;
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      notifyListeners();

      if (_remainingSeconds <= 0) {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timeoutTimer?.cancel();
    _currentTransaction = _currentTransaction?.copyWith(
      status: TransactionStatus.cancelled,
    );
    _statusMessage = 'Timeout - No confirmation received';
    _isHceActive = false;
    _deactivateNdefHce();
    notifyListeners();
  }

  Future<void> cancelPayment() async {
    if (_isHceActive) {
      _timeoutTimer?.cancel();
      _currentTransaction = _currentTransaction?.copyWith(
        status: TransactionStatus.cancelled,
      );
      _statusMessage = 'Payment cancelled';
      _isHceActive = false;
      await _deactivateNdefHce();
      notifyListeners();
    }
  }

  Future<void> _deactivateNdefHce() async {
    try {
      await platform.invokeMethod('clearNdefPayload');
    } catch (e) {
      // Log error but don't throw
      debugPrint('Error deactivating NDEF HCE: $e');
    }
  }

  void resetPayment() {
    _amount = 0.0;
    _paymentToken = '';
    _currentTransaction = null;
    _isHceActive = false;
    _statusMessage = '';
    _remainingSeconds = 30;
    _timeoutTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _deactivateNdefHce();
    super.dispose();
  }
}
