import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class MessageEncryptionService {
  MessageEncryptionService._();

  static final MessageEncryptionService instance = MessageEncryptionService._();

  static const String _algorithmVersion = 'v1';
  static const String _defaultSecret = 'change-this-chat-key-before-release';
  static const String _secretFromEnv = String.fromEnvironment(
    'CHAT_ENCRYPTION_KEY',
    defaultValue: _defaultSecret,
  );

  final AesGcm _aesGcm = AesGcm.with256bits();
  final Random _random = Random.secure();
  final Sha256 _sha256 = Sha256();

  bool get isUsingDefaultKey => _secretFromEnv == _defaultSecret;

  Future<String> encryptMessage({
    required String plainText,
    required String conversationId,
  }) async {
    if (plainText.isEmpty) {
      return plainText;
    }

    final secretKey = await _buildConversationKey(conversationId);
    final nonce = _generateNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
      aad: utf8.encode(conversationId),
    );

    return jsonEncode({
      'v': _algorithmVersion,
      'n': base64Encode(secretBox.nonce),
      'c': base64Encode(secretBox.cipherText),
      'm': base64Encode(secretBox.mac.bytes),
    });
  }

  Future<String> decryptMessage({
    required String encryptedText,
    required String conversationId,
  }) async {
    if (encryptedText.isEmpty) {
      return encryptedText;
    }

    final payload = _tryParsePayload(encryptedText);
    if (payload == null) {
      return encryptedText;
    }

    try {
      final secretKey = await _buildConversationKey(conversationId);
      final nonce = base64Decode(payload.nonce);
      final cipherText = base64Decode(payload.cipherText);
      final macBytes = base64Decode(payload.mac);

      final clearBytes = await _aesGcm.decrypt(
        SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        ),
        secretKey: secretKey,
        aad: utf8.encode(conversationId),
      );
      return utf8.decode(clearBytes);
    } catch (_) {
      // Keep legacy/failed payloads readable in UI instead of crashing.
      return encryptedText;
    }
  }

  Future<SecretKey> _buildConversationKey(String conversationId) async {
    final hash = await _sha256.hash(
      utf8.encode('$_secretFromEnv::$conversationId'),
    );
    return SecretKey(hash.bytes);
  }

  List<int> _generateNonce() {
    return List<int>.generate(12, (_) => _random.nextInt(256));
  }

  _EncryptedPayload? _tryParsePayload(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final version = decoded['v'];
      final nonce = decoded['n'];
      final cipherText = decoded['c'];
      final mac = decoded['m'];

      if (version != _algorithmVersion ||
          nonce is! String ||
          cipherText is! String ||
          mac is! String) {
        return null;
      }

      return _EncryptedPayload(
        nonce: nonce,
        cipherText: cipherText,
        mac: mac,
      );
    } catch (_) {
      return null;
    }
  }
}

class _EncryptedPayload {
  const _EncryptedPayload({
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  final String nonce;
  final String cipherText;
  final String mac;
}
