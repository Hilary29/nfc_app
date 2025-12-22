import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../data/models/payment_request.dart';

class ClientNfcReaderNotifier extends ChangeNotifier {
  bool _isScanning = false;
  PaymentRequest? _detectedRequest;
  String _statusMessage = '';
  PaymentApprovalStatus? _approvalStatus;

  bool get isScanning => _isScanning;
  PaymentRequest? get detectedRequest => _detectedRequest;
  String get statusMessage => _statusMessage;
  PaymentApprovalStatus? get approvalStatus => _approvalStatus;
  bool get hasPendingPayment =>
      _detectedRequest != null &&
      _approvalStatus == PaymentApprovalStatus.pending;

  Future<void> startNfcReaderMode() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        _statusMessage = 'NFC not available. Please enable NFC.';
        notifyListeners();
        return;
      }

      _isScanning = true;
      _statusMessage = 'Scanning for payment request...';
      notifyListeners();

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          await _handleNfcTag(tag);
        },
        onError: (error) async {
          _statusMessage = 'NFC Error: ${error.message}';
          _isScanning = false;
          notifyListeners();
          await NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      _statusMessage = 'Failed to start NFC reader: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _handleNfcTag(NfcTag tag) async {
    try {
      _statusMessage = 'Reading payment data...';
      notifyListeners();

      final ndef = Ndef.from(tag);
      if (ndef == null) {
        _statusMessage = 'Tag does not contain NDEF data';
        _isScanning = false;
        notifyListeners();
        await NfcManager.instance.stopSession();
        return;
      }

      final cachedMessage = ndef.cachedMessage;
      if (cachedMessage == null || cachedMessage.records.isEmpty) {
        _statusMessage = 'No NDEF records found';
        _isScanning = false;
        notifyListeners();
        await NfcManager.instance.stopSession();
        return;
      }

      // Lire le Text Record
      final record = cachedMessage.records.first;

      // Vérifier Type = "T" (Text Record)
      // Le type pour Text Record est [0x54] ("T")
      if (record.type.isNotEmpty && record.type[0] == 0x54) {

        final payload = record.payload;

        if (payload.isEmpty) {
          _statusMessage = 'Empty NDEF payload';
          _isScanning = false;
          notifyListeners();
          await NfcManager.instance.stopSession();
          return;
        }

        // Format Text Record: [Status byte] [Language code...] [Text...]
        final statusByte = payload[0];
        final languageCodeLength = statusByte & 0x3F;

        if (payload.length < 1 + languageCodeLength) {
          _statusMessage = 'Invalid Text Record format';
          _isScanning = false;
          notifyListeners();
          await NfcManager.instance.stopSession();
          return;
        }

        final textBytes = payload.sublist(1 + languageCodeLength);
        final jsonText = utf8.decode(textBytes);

        // Parser PaymentRequest
        final request = PaymentRequest.fromCompactJson(jsonText);
        _detectedRequest = request;
        _approvalStatus = PaymentApprovalStatus.pending;
        _statusMessage = 'Payment request detected';
        _isScanning = false;
        notifyListeners();
      } else {
        _statusMessage = 'Invalid NDEF format (expected Text Record)';
        _isScanning = false;
        notifyListeners();
      }

      await NfcManager.instance.stopSession();
    } catch (e) {
      _statusMessage = 'Error reading payment: $e';
      _isScanning = false;
      notifyListeners();
      await NfcManager.instance.stopSession();
    }
  }

  void approvePayment() {
    if (_detectedRequest != null) {
      _approvalStatus = PaymentApprovalStatus.approved;
      _statusMessage = 'Payment approved locally';
      notifyListeners();
    }
  }

  void declinePayment() {
    if (_detectedRequest != null) {
      _approvalStatus = PaymentApprovalStatus.declined;
      _statusMessage = 'Payment declined';
      notifyListeners();
    }
  }

  Future<void> stopNfcReaderMode() async {
    if (_isScanning) {
      await NfcManager.instance.stopSession();
      _isScanning = false;
      _statusMessage = 'Scanning stopped';
      notifyListeners();
    }
  }

  void resetSession() {
    _isScanning = false;
    _detectedRequest = null;
    _statusMessage = '';
    _approvalStatus = null;
    notifyListeners();
  }
}

enum PaymentApprovalStatus {
  pending,
  approved,
  declined,
}
