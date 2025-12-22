import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
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

      // Essayer d'abord avec IsoDep (HCE émulé)
      final isoDep = IsoDep.from(tag);
      if (isoDep != null) {
        await _readFromHce(isoDep);
        return;
      }

      // Sinon essayer avec NDEF standard (tag physique)
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        await _readFromNdefTag(ndef);
        return;
      }

      _statusMessage = 'Tag does not support IsoDep or NDEF';
      _isScanning = false;
      notifyListeners();
      await NfcManager.instance.stopSession();
    } catch (e) {
      _statusMessage = 'Error reading payment: $e';
      _isScanning = false;
      notifyListeners();
      await NfcManager.instance.stopSession();
    }
  }

  Future<void> _readFromHce(IsoDep isoDep) async {
    try {
      // 1. SELECT NDEF Application (AID: D2760000850101)
      final selectApdu = Uint8List.fromList([
        0x00, 0xA4, 0x04, 0x00, 0x07,
        0xD2, 0x76, 0x00, 0x00, 0x85, 0x01, 0x01,
      ]);

      final selectResponse = await isoDep.transceive(data: selectApdu);
      if (selectResponse == null || selectResponse.length < 2) {
        _statusMessage = 'No response from HCE service';
        _isScanning = false;
        notifyListeners();
        await NfcManager.instance.stopSession();
        return;
      }

      final sw1 = selectResponse[selectResponse.length - 2];
      final sw2 = selectResponse[selectResponse.length - 1];

      if (sw1 != 0x90 || sw2 != 0x00) {
        _statusMessage = 'NDEF app not available (SW: ${sw1.toRadixString(16)}${sw2.toRadixString(16)})';
        _isScanning = false;
        notifyListeners();
        await NfcManager.instance.stopSession();
        return;
      }

      // 2. SELECT NDEF File (E104)
      final selectFileApdu = Uint8List.fromList([
        0x00, 0xA4, 0x00, 0x0C, 0x02,
        0xE1, 0x04,
      ]);

      final selectFileResponse = await isoDep.transceive(data: selectFileApdu);
      if (selectFileResponse == null || selectFileResponse.length < 2 ||
          selectFileResponse[selectFileResponse.length - 2] != 0x90) {
        _statusMessage = 'Failed to select NDEF file';
        _isScanning = false;
        notifyListeners();
        await NfcManager.instance.stopSession();
        return;
      }

      // 3. READ BINARY (lire le contenu NDEF)
      final readApdu = Uint8List.fromList([
        0x00, 0xB0, 0x00, 0x00, 0xFF, // Lire 255 bytes max
      ]);

      final readResponse = await isoDep.transceive(data: readApdu);
      if (readResponse == null || readResponse.length < 2) {
        _statusMessage = 'Failed to read NDEF data';
        _isScanning = false;
        notifyListeners();
        await NfcManager.instance.stopSession();
        return;
      }

      // Enlever les 2 derniers bytes (SW1 SW2)
      final ndefData = readResponse.sublist(0, readResponse.length - 2);

      // Parser le TLV NDEF
      await _parseNdefTlv(ndefData);

      await NfcManager.instance.stopSession();
    } catch (e) {
      _statusMessage = 'Error reading from HCE: $e';
      _isScanning = false;
      notifyListeners();
      await NfcManager.instance.stopSession();
    }
  }

  Future<void> _parseNdefTlv(Uint8List tlvData) async {
    try {
      if (tlvData.isEmpty || tlvData[0] != 0x03) {
        _statusMessage = 'Invalid NDEF TLV format';
        _isScanning = false;
        notifyListeners();
        return;
      }

      // TLV: [0x03] [Length MSB] [Length LSB] [NDEF Message] [0xFE]
      final lengthMsb = tlvData[1];
      final lengthLsb = tlvData[2];
      final messageLength = (lengthMsb << 8) | lengthLsb;

      final ndefMessage = tlvData.sublist(3, 3 + messageLength);

      // Parse NDEF Record
      // [Flags] [Type Length] [Payload Length] [Type] [Payload]
      final flags = ndefMessage[0];
      final typeLength = ndefMessage[1];
      final payloadLength = ndefMessage[2];
      final type = ndefMessage[3];

      if (type != 0x54) {
        _statusMessage = 'Not a Text Record';
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Payload starts at index 4
      final payload = ndefMessage.sublist(4, 4 + payloadLength);

      // Text Record: [Status] [Language...] [Text...]
      final statusByte = payload[0];
      final languageCodeLength = statusByte & 0x3F;
      final textBytes = payload.sublist(1 + languageCodeLength);
      final jsonText = utf8.decode(textBytes);

      // Parser PaymentRequest
      final request = PaymentRequest.fromCompactJson(jsonText);
      _detectedRequest = request;
      _approvalStatus = PaymentApprovalStatus.pending;
      _statusMessage = 'Payment request detected';
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error parsing NDEF: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _readFromNdefTag(Ndef ndef) async {
    try {
      final cachedMessage = ndef.cachedMessage;
      if (cachedMessage == null || cachedMessage.records.isEmpty) {
        _statusMessage = 'No NDEF records found';
        _isScanning = false;
        notifyListeners();
        await NfcManager.instance.stopSession();
        return;
      }

      final record = cachedMessage.records.first;

      if (record.type.isNotEmpty && record.type[0] == 0x54) {
        final payload = record.payload;

        if (payload.isEmpty) {
          _statusMessage = 'Empty NDEF payload';
          _isScanning = false;
          notifyListeners();
          await NfcManager.instance.stopSession();
          return;
        }

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
      _statusMessage = 'Error reading NDEF tag: $e';
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
