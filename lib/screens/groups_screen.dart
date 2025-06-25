
// lib/screens/groups_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan import ini
import 'package:flutterchatencrypt/screens/auth_screen.dart';
import 'package:flutterchatencrypt/screens/create_group_screen.dart';
import 'package:flutterchatencrypt/screens/chat_screen.dart';
import 'package:flutterchatencrypt/services/auth_service.dart';
import 'package:flutterchatencrypt/services/group_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  String? _currentUserId;
  String _currentUserName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      // Mengambil username dari Firestore langsung, bukan melalui _groupService
      var userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userData.exists && userData.data() != null) {
        setState(() {
          _currentUserName = userData.data()!['username'] ?? 'Pengguna';
        });
      }
    } else {
      // Jika tidak ada user, logout
      await _authService.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _joinGroup(String groupId, String groupName) async {
    try {
      await _groupService.joinGroup(groupId);
      _showSnackBar('Anda berhasil bergabung ke grup "$groupName"!');
      // Refresh UI untuk memastikan grup baru muncul di daftar "Grup Anda"
      setState(() {});
    } catch (e) {
      _showSnackBar('Gagal bergabung ke grup: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup Chat Anda'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await _authService.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_currentUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(_authService.getCurrentUser()?.email ?? 'Tidak ada email'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Colors.blueGrey,
                  size: 40,
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Buat Grup Baru'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                );
              },
            ),
            const Divider(),
             Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _groupService.getAvailableGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Tidak ada grup yang tersedia.'));
                  }

                  final allGroups = snapshot.data!;
                  final currentUserId = _currentUserId;

                  return ListView.builder(
                    itemCount: allGroups.length,
                    itemBuilder: (context, index) {
                      final group = allGroups[index];
                      final bool isMember = currentUserId != null && (group['members'] as List).contains(currentUserId);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(group['groupName']),
                          subtitle: Text('Anggota: ${(group['members'] as List).length}'),
                          trailing: isMember
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () => _joinGroup(group['groupId'], group['groupName']),
                                  child: const Text('Gabung'),
                                ),
                          onTap: () { // Ubah ini dari isMember ? () : null
                            Navigator.of(context).pop(); // Tutup drawer
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  groupId: group['groupId'],
                                  groupName: group['groupName'],
                                  isUserMember: isMember, // <<< LEWATKAN PARAMETER INI
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _groupService.getUserGroups(), // Hanya stream grup di mana pengguna adalah anggota
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Anda belum bergabung di grup manapun.\nBuat grup baru atau gabung grup yang tersedia!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                ],
              ),
            );
          }

          final userGroups = snapshot.data!;

          return ListView.builder(
            itemCount: userGroups.length,
            itemBuilder: (context, index) {
              final group = userGroups[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.group, color: Colors.blueAccent),
                  title: Text(group['groupName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Anggota: ${group['members'].length}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          groupId: group['groupId'],
                          groupName: group['groupName'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.green,
      ),
    );
  }
}