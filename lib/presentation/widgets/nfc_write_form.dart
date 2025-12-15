import 'package:flutter/material.dart';
import 'package:nfc_app/core/models/nfc_data.dart';

class NfcWriteForm extends StatefulWidget {
  final Function(NfcData) onWrite;

  const NfcWriteForm({super.key, required this.onWrite});

  @override
  State<NfcWriteForm> createState() => _NfcWriteFormState();
}

class _NfcWriteFormState extends State<NfcWriteForm> {
  final _formKey = GlobalKey<FormState>();
  final _senderController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _senderController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = NfcData(
        sender: _senderController.text,
        content: _contentController.text,
      );

      if (data.validate()) {
        widget.onWrite(data);
        _senderController.clear();
        _contentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données trop volumineuses pour le tag NFC'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Écrire des Données',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senderController,
                decoration: const InputDecoration(
                  labelText: 'Expéditeur',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un expéditeur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un contenu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.nfc),
                label: const Text('ÉCRIRE NFC'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
