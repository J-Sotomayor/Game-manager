import 'dart:io';
import 'package:flutter/material.dart';
import 'package:game_manager_app/screens/services/user_service.dart';
import 'package:image_picker/image_picker.dart';


class EditPhotoScreen extends StatefulWidget {
  const EditPhotoScreen({super.key});

  @override
  State<EditPhotoScreen> createState() => _EditPhotoScreenState();
}

class _EditPhotoScreenState extends State<EditPhotoScreen> {
  final UserService _userService = UserService();
  XFile? _image;
  bool _isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _image = img;
      });
    }
  }

  Future<void> _savePhoto() async {
    if (_image == null) return;
    setState(() => _isLoading = true);
    await _userService.updatePhoto(_image!.path);
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cambiar foto")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_image != null)
                  Image.file(
                    File(_image!.path),
                    width: 150,
                    height: 150,
                  )
                else
                  const CircleAvatar(
                    radius: 75,
                    child: Icon(Icons.person, size: 50),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: pickImage,
                  child: const Text("Seleccionar imagen"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _savePhoto,
                  child: const Text("Guardar"),
                ),
              ],
            ),
    );
  }
}
