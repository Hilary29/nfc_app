import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_app/models/nfc_data.dart';
import 'package:nfc_app/presentation/widgets/dialogs.dart';
import 'package:nfc_app/presentation/widgets/nfc_data_card.dart';
import 'package:nfc_app/presentation/widgets/nfc_write_form.dart';

enum NFCOperation { read, write }

class ReadWriteNFCScreen extends StatefulWidget {
  const ReadWriteNFCScreen({super.key});

  @override
  State<ReadWriteNFCScreen> createState() => _ReadWriteNFCScreenState();
}

class _ReadWriteNFCScreenState extends State<ReadWriteNFCScreen> {
  bool _isProcessing = false;
  String _message = "";
  NfcData? _lastReadData;
  String? _errorMessage;

  Future<void> _startNFCOperation({required NFCOperation nfcOperation}) async {
    try {
      setState(() {
        _isProcessing = true;
        _message = "Scanning";
      });

      bool isAvail = await NfcManager.instance.isAvailable();

      if (isAvail) {
        NfcManager.instance.startSession(
          onDiscovered: (NfcTag nfcTag) async {
            if (nfcOperation == NFCOperation.read) {
              await _readFromTag(tag: nfcTag);
            }
            setState(() => _isProcessing = false);
            await NfcManager.instance.stopSession();
          },
          onError: (e) async {
            setState(() {
              _isProcessing = false;
              _message = e.toString();
            });
          },
        );
      } else {
        setState(() {
          _isProcessing = false;
          _message = "Veuillez activer le NFC";
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = e.toString();
      });
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

        setState(() {
          _lastReadData = NfcData.fromJson(jsonData);
          _errorMessage = null;
          _message = "Données lues avec succès";
        });
      } else {
        setState(() {
          _errorMessage = "Aucune donnée NDEF trouvée";
          _lastReadData = null;
          _message = "Aucune donnée trouvée";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de lecture: ${e.toString()}";
        _lastReadData = null;
        _message = "Erreur de lecture";
      });
    }
  }

  Future<void> _writeJsonData(NfcData data) async {
    try {
      setState(() {
        _isProcessing = true;
        _message = "Écriture en cours";
      });

      bool isAvail = await NfcManager.instance.isAvailable();

      if (isAvail) {
        NfcManager.instance.startSession(
          onDiscovered: (NfcTag nfcTag) async {
            final jsonString = data.toJson();
            final bytes = utf8.encode(jsonString);

            NdefMessage message = NdefMessage([
              NdefRecord.createMime(
                'application/json',
                Uint8List.fromList(bytes),
              )
            ]);

            await Ndef.from(nfcTag)?.write(message);

            setState(() {
              _message = "Écriture réussie";
              _isProcessing = false;
            });
            await NfcManager.instance.stopSession();
          },
          onError: (e) async {
            setState(() {
              _isProcessing = false;
              _message = "Erreur: ${e.toString()}";
            });
          },
        );
      } else {
        setState(() {
          _isProcessing = false;
          _message = "Veuillez activer le NFC";
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = "Erreur: ${e.toString()}";
      });
    }
  }

  void _clearLastRead() {
    setState(() {
      _lastReadData = null;
      _errorMessage = null;
      _message = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NFC JSON Reader/Writer"),
        actions: [
          if (_lastReadData != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearLastRead,
              tooltip: 'Effacer',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_lastReadData != null)
              NfcDataCard(data: _lastReadData!)
            else if (_errorMessage != null)
              ErrorCard(message: _errorMessage!)
            else
              const EmptyStateCard(),
            const SizedBox(height: 24),
            NfcWriteForm(
              onWrite: (data) {
                scanningDialog(context);
                _writeJsonData(data);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                scanningDialog(context);
                _startNFCOperation(nfcOperation: NFCOperation.read);
              },
              icon: const Icon(Icons.nfc),
              label: const Text("LIRE NFC"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            if (_message.isNotEmpty && !_isProcessing)
              Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  });
                  return const SizedBox();
                },
              ),
          ],
        ),
      ),
    );
  }
}
