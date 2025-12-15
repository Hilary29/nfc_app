import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_app/models/nfc_data.dart';
import 'package:nfc_app/presentation/widgets/dialogs.dart';
import 'package:nfc_app/presentation/widgets/nfc_write_form.dart';

class NfcWriteScreen extends StatefulWidget {
  const NfcWriteScreen({super.key});

  @override
  State<NfcWriteScreen> createState() => _NfcWriteScreenState();
}

class _NfcWriteScreenState extends State<NfcWriteScreen> {
  bool _isProcessing = false;
  String _message = "";

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

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Écriture NFC"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_message.isNotEmpty && !_isProcessing)
              Card(
                elevation: 2,
                color: _message.contains('succès')
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _message.contains('succès')
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: _message.contains('succès')
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(_message),
                      ),
                    ],
                  ),
                ),
              ),
            if (_message.isNotEmpty && !_isProcessing)
              const SizedBox(height: 16),
            NfcWriteForm(
              onWrite: (data) {
                scanningDialog(context);
                _writeJsonData(data);
              },
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
