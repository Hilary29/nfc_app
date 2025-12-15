import 'package:flutter/material.dart';
import 'package:nfc_app/core/notifier/nfc_notifier.dart';
import 'package:nfc_app/presentation/widgets/dialogs.dart';
import 'package:nfc_app/presentation/widgets/nfc_data_card.dart';
import 'package:nfc_app/presentation/widgets/nfc_write_form.dart';
import 'package:provider/provider.dart';

class ReadWriteNFCScreen extends StatelessWidget {
  const ReadWriteNFCScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NFCNotifier(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("NFC JSON Reader/Writer"),
          actions: [
            Consumer<NFCNotifier>(
              builder: (context, notifier, _) {
                if (notifier.lastReadData != null) {
                  return IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      notifier.clearLastRead();
                    },
                    tooltip: 'Effacer',
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<NFCNotifier>(
                builder: (context, notifier, _) {
                  if (notifier.lastReadData != null) {
                    return NfcDataCard(data: notifier.lastReadData!);
                  } else if (notifier.errorMessage != null) {
                    return ErrorCard(message: notifier.errorMessage!);
                  } else {
                    return const EmptyStateCard();
                  }
                },
              ),
              const SizedBox(height: 24),
              NfcWriteForm(
                onWrite: (data) {
                  scanningDialog(context);
                  Provider.of<NFCNotifier>(context, listen: false)
                      .writeJsonData(data);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  scanningDialog(context);
                  Provider.of<NFCNotifier>(context, listen: false)
                      .startNFCOperation(nfcOperation: NFCOperation.read);
                },
                icon: const Icon(Icons.nfc),
                label: const Text("LIRE NFC"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              Consumer<NFCNotifier>(
                builder: (context, provider, _) {
                  if (provider.message.isNotEmpty && !provider.isProcessing) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    });
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
