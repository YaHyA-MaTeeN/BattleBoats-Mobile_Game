import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  // Static AES key and IV
  // In production, these should be stored securely
  static final String _keyString = 'MySecretKeyFor32BytesLongKeyXXXX'; // 32 chars = 256-bit
  static final String _ivString = 'InitialVectorXYZ'; // 16 chars = 128-bit

  /// Encrypts a string using AES-256-CBC
  /// Returns the encrypted text as a Base64-encoded string
  static String encryptData(String plainText) {
    try {
      final key = _keyStringToBytes(_keyString);
      final iv = _keyStringToBytes(_ivString);

      final cipher = CBCBlockCipher(AESEngine())
        ..init(true, ParametersWithIV(KeyParameter(key), iv));

      final plainBytes = utf8.encode(plainText);
      final paddedPlainBytes = _pkcs7Padding(plainBytes, 16);

      final encryptedBytes = cipher.process(paddedPlainBytes);
      return base64Encode(encryptedBytes);
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts a Base64-encoded AES-256-CBC encrypted string
  /// Returns the decrypted plaintext. Runs in a background isolate via `compute`.
  static Future<String> decryptData(String encryptedBase64) async {
    return compute(_decryptDataIsolate, encryptedBase64);
  }



  /// Encrypts move data (x,y coordinates as JSON)
  static String encryptMove(int x, int y) {
    final moveData = '{\"x\":0,\"y\":0}'.replaceFirst('0', x.toString()).replaceFirst('0', y.toString());
    return encryptData(moveData);
  }

  /// Decrypts move data and returns [x, y]
  static Future<List<int>> decryptMove(String encryptedMove) async {
    try {
      final moveData = await decryptData(encryptedMove);
      final xMatch = RegExp(r'\"x\":(\d+)').firstMatch(moveData);
      final yMatch = RegExp(r'\"y\":(\d+)').firstMatch(moveData);

      if (xMatch != null && yMatch != null) {
        final x = int.parse(xMatch.group(1)!);
        final y = int.parse(yMatch.group(1)!);
        return [x, y];
      }
      throw Exception('Invalid move data format');
    } catch (e) {
      throw Exception('Failed to decrypt move: $e');
    }
  }

  static Uint8List _keyStringToBytes(String key) {
    final bytes = utf8.encode(key);
    if (bytes.length != 16 && bytes.length != 24 && bytes.length != 32) {
      throw Exception('Key must be 16, 24, or 32 bytes, got ${bytes.length}');
    }
    return Uint8List.fromList(bytes);
  }

  static Uint8List _pkcs7Padding(Uint8List data, int blockSize) {
    final paddingLength = blockSize - (data.length % blockSize);
    final padded = Uint8List(data.length + paddingLength);
    padded.setRange(0, data.length, data);
    padded.fillRange(data.length, padded.length, paddingLength);
    return padded;
  }

  static Uint8List _removePkcs7Padding(Uint8List data) {
    final paddingLength = data.last;
    return Uint8List.view(data.buffer, data.offsetInBytes, data.length - paddingLength);
  }
}

String _decryptDataIsolate(String encryptedBase64) {
  try {
    final key = EncryptionService._keyStringToBytes(EncryptionService._keyString);
    final iv = EncryptionService._keyStringToBytes(EncryptionService._ivString);

    final encryptedBytes = base64Decode(encryptedBase64);

    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));

    final decryptedBytes = cipher.process(encryptedBytes);
    final unpadded = EncryptionService._removePkcs7Padding(decryptedBytes);
    return utf8.decode(unpadded);
  } catch (e) {
    throw Exception('Decryption failed: $e');
  }
}
