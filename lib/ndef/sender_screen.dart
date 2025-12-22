import 'package:flutter/material.dart';
import 'package:nfc_app/ndef/ndef_payload.dart';
import 'package:nfc_app/ndef/nfc_service.dart';

/// Écran permettant de saisir et écrire des données sur un tag NFC
class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nfcService = NfcService();

  NfcStatus _status = NfcStatus.idle;
  String _message = '';

  @override
  void dispose() {
    _idController.dispose();
    _descriptionController.dispose();
    _nfcService.stopSession();
    super.dispose();
  }

  Future<void> _writeToTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payload = NdefPayload(
      id: _idController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    setState(() {
      _status = NfcStatus.waiting;
      _message = 'Approchez le tag NFC...';
    });

    await _nfcService.writePayload(
      payload: payload,
      onSuccess: () {
        if (mounted) {
          setState(() {
            _status = NfcStatus.success;
            _message = 'Données écrites avec succès !';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _status = NfcStatus.error;
            _message = error;
          });
        }
      },
    );
  }

  void _cancel() {
    _nfcService.stopSession();
    setState(() {
      _status = NfcStatus.idle;
      _message = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Écrire sur Tag NFC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulaire
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'ID',
                      hintText: 'Entrez l\'identifiant',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'ID est requis';
                      }
                      return null;
                    },
                    enabled: _status != NfcStatus.waiting,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Entrez la description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La description est requise';
                      }
                      return null;
                    },
                    enabled: _status != NfcStatus.waiting,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Zone de statut
            if (_status != NfcStatus.idle)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor),
                ),
                child: Column(
                  children: [
                    _statusIcon,
                    const SizedBox(height: 8),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Boutons d'action
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _status == NfcStatus.waiting
                  ? OutlinedButton(
                      onPressed: _cancel,
                      child: const Text('Annuler'),
                    )
                  : ElevatedButton.icon(
                      onPressed: _writeToTag,
                      icon: const Icon(Icons.nfc),
                      label: const Text('Écrire sur le tag'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (_status) {
      case NfcStatus.idle:
        return Colors.grey;
      case NfcStatus.waiting:
        return Colors.blue;
      case NfcStatus.success:
        return Colors.green;
      case NfcStatus.error:
        return Colors.red;
    }
  }

  Widget get _statusIcon {
    switch (_status) {
      case NfcStatus.idle:
        return const SizedBox.shrink();
      case NfcStatus.waiting:
        return const CircularProgressIndicator();
      case NfcStatus.success:
        return const Icon(Icons.check_circle, size: 48, color: Colors.green);
      case NfcStatus.error:
        return const Icon(Icons.error, size: 48, color: Colors.red);
    }
  }
}

enum NfcStatus { idle, waiting, success, error }