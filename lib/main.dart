import 'package:flutter/material.dart';
import 'package:nfc_app/nfc_payment/presentation/screens/mode_selection_screen.dart';
import 'package:nfc_app/nfc_read_write/presentation/screen/read_write_nfc_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NFC Payment POC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ModeSelectionScreen(),
        '/demo': (context) => const ReadWriteNFCScreen(),
      },
    );
  }
}
