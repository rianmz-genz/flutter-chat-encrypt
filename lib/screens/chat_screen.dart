// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterchatencrypt/services/chat_service.dart';
import 'package:flutterchatencrypt/widgets/message_bubble.dart';


class ChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isUserMember; // <<< TAMBAH PARAMETER INI

  const ChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.isUserMember = true, // <<< BERIKAN NILAI DEFAULT TRUE JIKA TIDAK DILEWATKAN
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(() {
        // Ini adalah logika untuk scroll saat pesan baru datang, biasanya di akhir.
        // Jika Anda menggunakan `reverse: true`, 0.0 adalah paling atas.
        // Anda mungkin ingin scroll ke `_scrollController.position.maxScrollExtent` jika pesan terbaru di bawah.
        // Untuk sekarang, biarkan seperti ini karena `sendMessage` sudah mengaturnya.
      });
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }
    // Pastikan hanya anggota yang bisa mengirim pesan
    if (!widget.isUserMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus bergabung dengan grup untuk mengirim pesan.')),
      );
      _messageController.clear();
      return;
    }

    try {
      await _chatService.sendMessage(widget.groupId, _messageController.text.trim());
      _messageController.clear();
      // Scroll ke bawah setelah mengirim pesan baru (jika reverse: true, 0.0 adalah atas)
      // Jika ingin otomatis scroll ke bawah saat list bertambah, biasanya scroll ke maxScrollExtent
      _scrollController.animateTo(
        0.0, // Scroll ke paling atas (pesan terbaru ada di atas karena descending: true)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: widget.isUserMember // <<< CEK APAKAH PENGGUNA ADALAH ANGGOTA
                ? StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatService.getMessages(widget.groupId), // Ini akan mendekripsi
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'Belum ada pesan di grup ini. Ayo mulai percakapan!',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        );
                      }

                      final messages = snapshot.data!;
                      return ListView.builder(
                        reverse: true, // Menampilkan pesan terbaru di bagian bawah
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final bool isMe = message['senderId'] == _currentUserId;
                          return MessageBubble(
                            message: message['content'], // Sudah didekripsi oleh ChatService
                            sender: message['senderUsername'],
                            senderId: message['senderId'],
                            isMe: isMe,
                          );
                        },
                      );
                    },
                  )
                : StreamBuilder<List<Map<String, dynamic>>>( // <<< JIKA BUKAN ANGGOTA, TAMPILKAN VERSI TERENKRIPSI
                    stream: _chatService.getRawMessages(widget.groupId), // Perlu fungsi baru di ChatService
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'Belum ada pesan di grup ini. Bergabung untuk melihat isinya!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        );
                      }

                      final messages = snapshot.data!;
                      return ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final bool isMe = message['senderId'] == _currentUserId;
                          return MessageBubble(
                            message: '${message['content']}', // Tampilkan langsung yang terenkripsi
                            sender: message['senderUsername'],
                            senderId: message['senderId'],
                            isMe: isMe,
                            // Anda mungkin ingin tampilan yang berbeda untuk pesan terenkripsi
                            // Misalnya, warna abu-abu atau ikon gembok
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: widget.isUserMember, // Non-aktifkan input jika bukan anggota
                    decoration: InputDecoration(
                      hintText: widget.isUserMember ? 'Ketik pesan...' : 'Gabung grup untuk mengirim pesan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.blueGrey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: widget.isUserMember ? (_) => _sendMessage() : null, // Non-aktifkan submit
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: widget.isUserMember ? Colors.blueAccent : Colors.grey, // Warna tombol kirim
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: widget.isUserMember ? _sendMessage : null, // Non-aktifkan tombol kirim
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}