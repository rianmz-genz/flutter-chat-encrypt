
// lib/screens/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:flutterchatencrypt/services/group_service.dart';
import 'package:flutterchatencrypt/widgets/custom_text_field.dart';
import 'package:flutterchatencrypt/widgets/loading_indicator.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final GroupService _groupService = GroupService();
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      _showSnackBar('Nama grup tidak boleh kosong!', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _groupService.createGroup(_groupNameController.text.trim());
      _showSnackBar('Grup "${_groupNameController.text.trim()}" berhasil dibuat!');
      // Kembali ke layar sebelumnya (GroupsScreen)
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('Gagal membuat grup: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Grup Baru'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Masukkan nama untuk grup chat Anda.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blueGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _groupNameController,
                  labelText: 'Nama Grup',
                  prefixIcon: const Icon(Icons.group, color: Colors.blueAccent),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _createGroup,
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Grup', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
          if (_isLoading) const LoadingIndicator(),
        ],
      ),
    );
  }
}