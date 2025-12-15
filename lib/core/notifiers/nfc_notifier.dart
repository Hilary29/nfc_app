import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_app/core/models/nfc_data.dart';

class NFCNotifier extends ChangeNotifier {
  bool _isProcessing = false;
  String _message = "";
  NfcData? _lastReadData;
  String? _errorMessage;

  bool get isProcessing => _isProcessing;
  String get message => _message;
  NfcData? get lastReadData => _lastReadData;
  String? get errorMessage => _errorMessage;

  Future<void> startNFCOperation(
      {required NFCOperation nfcOperation}) async {
    try {
      _isProcessing = true;
      notifyListeners();

      bool isAvail = await NfcManager.instance.isAvailable();

      if (isAvail) {
        _message = "Scanning";
        notifyListeners();

        NfcManager.instance.startSession(onDiscovered: (NfcTag nfcTag) async {
          if (nfcOperation == NFCOperation.read) {
            _readFromTag(tag: nfcTag);
          }

          _isProcessing = false;
          notifyListeners();
          await NfcManager.instance.stopSession();
        }, onError: (e) async {
          _isProcessing = false;
          _message = e.toString();
          notifyListeners();
        });
      } else {
        _isProcessing = false;
        _message = "Veuillez activer le NFC";
        notifyListeners();
      }
    } catch (e) {
      _isProcessing = false;
      _message = e.toString();
      notifyListeners();
    }
  }

  Future<void> _readFromTag({required NfcTag tag}) async {
    try {
      Map<String, dynamic> nfcData = tag.data;

      if (nfcData.containsKey('ndef')) {
        List<int> payload = nfcData['ndef']['cachedMessage']
            ?['records']?[0]['payload'];

        String jsonString = utf8.decode(payload, allowMalformed: false);
        Map<String, dynamic> jsonData = jsonDecode(jsonString);

        _lastReadData = NfcData.fromJson(jsonData);
        _errorMessage = null;
        _message = "Données lues avec succès";
      } else {
        _errorMessage = "Aucune donnée NDEF trouvée";
        _lastReadData = null;
        _message = "Aucune donnée trouvée";
      }
    } catch (e) {
      _errorMessage = "Erreur de lecture: ${e.toString()}";
      _lastReadData = null;
      _message = "Erreur de lecture";
    }
  }

  Future<void> writeJsonData(NfcData data) async {
    try {
      _isProcessing = true;
      notifyListeners();

      bool isAvail = await NfcManager.instance.isAvailable();

      if (isAvail) {
        _message = "Écriture en cours";
        notifyListeners();

        NfcManager.instance.startSession(onDiscovered: (NfcTag nfcTag) async {
          final jsonString = data.toJson();
          final bytes = utf8.encode(jsonString);

          NdefMessage message = NdefMessage([
            NdefRecord.createMime(
              'application/json',
              Uint8List.fromList(bytes),
            )
          ]);

          await Ndef.from(nfcTag)?.write(message);

          _message = "Écriture réussie";
          _isProcessing = false;
          notifyListeners();
          await NfcManager.instance.stopSession();
        }, onError: (e) async {
          _isProcessing = false;
          _message = "Erreur: ${e.toString()}";
          notifyListeners();
        });
      } else {
        _isProcessing = false;
        _message = "Veuillez activer le NFC";
        notifyListeners();
      }
    } catch (e) {
      _isProcessing = false;
      _message = "Erreur: ${e.toString()}";
      notifyListeners();
    }
  }

  void clearLastRead() {
    _lastReadData = null;
    _errorMessage = null;
    _message = "";
    notifyListeners();
  }
}

enum NFCOperation { read, write }
