import 'package:flutter/material.dart';
import 'package:nfc_app/ndef/ndef_payload.dart';
import 'package:nfc_app/ndef/nfc_service.dart';

/// Écran permettant de lire et afficher les données d'un tag NFC
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final _nfcService = NfcService();

  NfcStatus _status = NfcStatus.idle;
  String _message = '';
  NdefPayload? _payload;

  @override
  void dispose() {
    _nfcService.stopSession();
    super.dispose();
  }

  Future<void> _readFromTag() async {
    setState(() {
      _status = NfcStatus.waiting;
      _message = 'Approchez le tag NFC...';
      _payload = null;
    });

    await _nfcService.readPayload(
      onRead: (payload) {
        if (mounted) {
          setState(() {
            _status = NfcStatus.success;
            _message = 'Lecture réussie !';
            _payload = payload;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _status = NfcStatus.error;
            _message = error;
            _payload = null;
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

  void _reset() {
    setState(() {
      _status = NfcStatus.idle;
      _message = '';
      _payload = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lire Tag NFC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Zone de statut
            if (_status != NfcStatus.idle && _payload == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor),
                ),
                child: Column(
                  children: [
                    _statusIcon,
                    const SizedBox(height: 12),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            // Affichage des données lues
            if (_payload != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Données reçues',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDataRow('ID', _payload!.id),
                    const SizedBox(height: 12),
                    _buildDataRow('Description', _payload!.description),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Nouvelle lecture'),
              ),
            ],

            // Icône NFC décorative quand idle
            if (_status == NfcStatus.idle && _payload == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.nfc,
                        size: 120,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Prêt à scanner',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Boutons d'action
            if (_payload == null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _status == NfcStatus.waiting
                    ? OutlinedButton(
                        onPressed: _cancel,
                        child: const Text('Annuler'),
                      )
                    : ElevatedButton.icon(
                        onPressed: _readFromTag,
                        icon: const Icon(Icons.nfc),
                        label: const Text('Lire le tag'),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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