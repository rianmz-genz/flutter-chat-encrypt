import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class CryptoUtils {
  // Pastikan panjangnya 32 karakter
  static final Key _key = Key.fromUtf8('thisisanewlongandsecurekeyforcha');

  // >>> PERBAIKAN DI SINI: Gunakan string untuk IV dan pastikan panjangnya 16 karakter <<<
  static final IV _iv = IV.fromUtf8('sixteenbyteivfix'); // Ini 16 karakter

  // Inisialisasi Encrypter dengan AES dalam mode CBC
  static final Encrypter _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  // Fungsi untuk mengenkripsi teks
  static String encryptAES(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64; // Mengembalikan string base64 dari data terenkripsi
    } catch (e) {
      print('Error encrypting: $e');
      return ''; // Mengembalikan string kosong jika ada error
    }
  }

  // Fungsi untuk mendekripsi teks
  static String decryptAES(String encryptedBase64) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedBase64);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      print('Error decrypting: $e');
      // Mungkin pesan terenkripsi rusak atau kunci/IV tidak cocok
      return 'Pesan tidak dapat didekripsi.';
    }
  }
}