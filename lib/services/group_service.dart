
// lib/services/group_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Membuat grup baru
  Future<void> createGroup(String groupName) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in.");
    }

    String groupId = _uuid.v4(); // Generate ID unik untuk grup
    String currentUserId = currentUser.uid;
    String? currentUserName = (await _firestore.collection('users').doc(currentUserId).get()).data()?['username'];

    await _firestore.collection('groups').doc(groupId).set({
      'groupId': groupId,
      'groupName': groupName,
      'createdAt': Timestamp.now(),
      'createdBy': currentUserId,
      'members': [currentUserId], // Otomatis menambahkan pembuat sebagai anggota
      'memberNames': {currentUserId: currentUserName ?? 'Unknown User'}, // Menyimpan nama anggota
    });
  }

  // Bergabung ke grup yang sudah ada
  Future<void> joinGroup(String groupId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in.");
    }

    String currentUserId = currentUser.uid;
    String? currentUserName = (await _firestore.collection('users').doc(currentUserId).get()).data()?['username'];

    // Perbarui dokumen grup untuk menambahkan anggota
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([currentUserId]),
      'memberNames.${currentUserId}': currentUserName ?? 'Unknown User',
    });
  }

  // Mendapatkan semua grup yang tersedia (atau yang merupakan anggota pengguna)
  Stream<List<Map<String, dynamic>>> getAvailableGroups() {
    // Pengguna yang tidak menjadi anggota masih bisa melihat grup, tapi tidak bisa mengakses chatnya
    return _firestore.collection('groups').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Mendapatkan grup tempat pengguna menjadi anggota
  Stream<List<Map<String, dynamic>>> getUserGroups() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Jika tidak ada pengguna, kembalikan stream kosong
      return Stream.value([]);
    }

    // Hanya mendapatkan grup di mana currentUserId adalah anggota
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}