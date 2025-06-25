
// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/crypto_utils.dart'; // Untuk enkripsi/dekripsi

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mengirim pesan ke grup
  Future<void> sendMessage(String groupId, String message) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in.");
    }

    // Mendapatkan username dari Firestore
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    String senderUsername = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['username'] : 'Unknown User';

    // Enkripsi pesan sebelum dikirim
    String encryptedMessage = CryptoUtils.encryptAES(message);

    await _firestore.collection('groups').doc(groupId).collection('messages').add({
      'senderId': currentUser.uid,
      'senderUsername': senderUsername,
      'content': encryptedMessage, // Simpan pesan terenkripsi
      'timestamp': Timestamp.now(),
    });
  }

  // Mendapatkan stream pesan untuk grup tertentu
  Stream<List<Map<String, dynamic>>> getMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Pesan terbaru di atas
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            // Dekripsi pesan saat diterima
            data['content'] = CryptoUtils.decryptAES(data['content']);
            return data;
          }).toList();
        });
  }

  // >>> FUNGSI BARU: Mendapatkan stream pesan tanpa dekripsi <<<
  Stream<List<Map<String, dynamic>>> getRawMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }
}