import 'package:flutter/material.dart';
import 'package:game_manager_app/screens/services/user_service.dart';


class EditNameScreen extends StatefulWidget {
  const EditNameScreen({super.key});

  @override
  State<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  void _loadCurrentName() async {
    final doc = await _userService.getUser();
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _firstNameCtrl.text = data['firstName'] ?? '';
      _lastNameCtrl.text = data['lastName'] ?? '';
    });
  }

  void _saveName() async {
    setState(() => _isLoading = true);
    await _userService.updateName(_firstNameCtrl.text, _lastNameCtrl.text);
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Nombre")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(labelText: "Nuevo nombre"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameCtrl,
                    decoration: const InputDecoration(labelText: "Nuevo apellido"),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveName,
                    child: const Text("Guardar"),
                  ),
                ],
              ),
            ),
    );
  }
}
