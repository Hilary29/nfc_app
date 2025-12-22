import 'dart:convert';
import 'package:nfc_app/ndef/ndef_payload.dart';
import 'package:nfc_manager/nfc_manager.dart';


/// Service gérant les opérations NFC (lecture/écriture NDEF)
class NfcService {
  static const String _mimeType = 'application/json';

  /// Vérifie si le NFC est disponible sur l'appareil
  Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Écrit un NdefPayload sur un tag NFC
  /// 
  /// [payload] : les données à écrire
  /// [onSuccess] : callback appelé en cas de succès
  /// [onError] : callback appelé en cas d'erreur
  Future<void> writePayload({
    required NdefPayload payload,
    required Function() onSuccess,
    required Function(String message) onError,
  }) async {
    if (!await isNfcAvailable()) {
      onError('NFC non disponible sur cet appareil');
      return;
    }

    if (!payload.isValid) {
      onError('Données invalides : id et description requis');
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          
          if (ndef == null) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Tag non compatible NDEF',
            );
            onError('Tag non compatible NDEF');
            return;
          }

          if (!ndef.isWritable) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Tag en lecture seule',
            );
            onError('Tag en lecture seule');
            return;
          }

          // Conversion du payload en JSON
          final jsonString = jsonEncode(payload.toJson());
          final bytes = utf8.encode(jsonString);

          // Vérification de la capacité du tag
          if (bytes.length > ndef.maxSize) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Données trop volumineuses pour ce tag',
            );
            onError('Données trop volumineuses (${bytes.length}/${ndef.maxSize} bytes)');
            return;
          }

          // Création du message NDEF avec type MIME JSON
          final message = NdefMessage([
            NdefRecord.createMime(_mimeType, bytes),
          ]);

          // Écriture sur le tag
          await ndef.write(message);

          await NfcManager.instance.stopSession(
            alertMessage: 'Écriture réussie !',
          );
          onSuccess();
        } catch (e) {
          await NfcManager.instance.stopSession(
            errorMessage: 'Erreur d\'écriture',
          );
          onError('Erreur lors de l\'écriture : $e');
        }
      },
      onError: (error) async {
        onError('Erreur NFC : $error');
      },
    );
  }

  /// Lit un NdefPayload depuis un tag NFC
  /// 
  /// [onRead] : callback avec le payload lu
  /// [onError] : callback en cas d'erreur
  Future<void> readPayload({
    required Function(NdefPayload payload) onRead,
    required Function(String message) onError,
  }) async {
    if (!await isNfcAvailable()) {
      onError('NFC non disponible sur cet appareil');
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);

          if (ndef == null) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Tag non compatible NDEF',
            );
            onError('Tag non compatible NDEF');
            return;
          }

          final message = await ndef.read();

          if (message.records.isEmpty) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Tag vide',
            );
            onError('Aucune donnée sur le tag');
            return;
          }

          // Recherche d'un record de type MIME JSON
          for (final record in message.records) {
            if (_isMimeJson(record)) {
              final jsonString = utf8.decode(record.payload);
              final json = jsonDecode(jsonString) as Map<String, dynamic>;
              final payload = NdefPayload.fromJson(json);

              await NfcManager.instance.stopSession(
                alertMessage: 'Lecture réussie !',
              );
              onRead(payload);
              return;
            }
          }

          // Fallback : essayer de parser le premier record comme JSON
          try {
            final jsonString = utf8.decode(message.records.first.payload);
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final payload = NdefPayload.fromJson(json);

            await NfcManager.instance.stopSession(
              alertMessage: 'Lecture réussie !',
            );
            onRead(payload);
          } catch (_) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Format non reconnu',
            );
            onError('Le tag ne contient pas de données NdefPayload valides');
          }
        } catch (e) {
          await NfcManager.instance.stopSession(
            errorMessage: 'Erreur de lecture',
          );
          onError('Erreur lors de la lecture : $e');
        }
      },
      onError: (error) async {
        onError('Erreur NFC : $error');
      },
    );
  }

  /// Vérifie si un record est de type MIME JSON
  bool _isMimeJson(NdefRecord record) {
    if (record.typeNameFormat != NdefTypeNameFormat.media) {
      return false;
    }
    final type = utf8.decode(record.type);
    return type == _mimeType;
  }

  /// Arrête la session NFC en cours
  Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // Session peut-être déjà arrêtée
    }
  }
}