import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/game_ui.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_service.dart';
import 'auth/login_page.dart';
import 'edit_password.dart';
import 'services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userService = UserService();
  bool _processing = false;

  Future<void> _changeNameDialog() async {
    final userDoc = await _userService.getUser();
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final currentName = (data['displayName'] ?? '').toString().trim();

    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar nombre / apellido'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre completo / Nickname',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() => _processing = true);
    try {
      final parts = result.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : result;
      final lastName =
          parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await _userService.updateName(firstName, lastName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar nombre: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => _processing = true);
    try {
      await _userService.updateProfileImage(File(picked.path).path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthService>(context, listen: false);

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text(
              '¿Seguro que quieres cerrar sesión en este dispositivo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _processing = true);
    try {
      await auth.logout();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay usuario autenticado.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: const Text(
              'Esta acción es permanente.\n\n'
              'Se eliminarán tu cuenta, tus datos y tus favoritos.\n\n'
              '¿Estás seguro de que deseas continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar definitivamente'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _processing = true);

    try {
      await auth.deleteAccountCompletely();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la cuenta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GameGlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.person_outline,
                              label: 'Cambiar nombre / apellido',
                              onTap: _changeNameDialog,
                            ),
                            const Divider(height: 1),
                            _SettingsTile(
                              icon: Icons.lock_outline,
                              label: 'Cambiar contraseña',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const EditPasswordScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _SettingsTile(
                              icon: Icons.image_outlined,
                              label: 'Cambiar foto de perfil',
                              onTap: _changeProfilePhoto,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      GameGlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.logout,
                              label: 'Cerrar sesión',
                              onTap: _logout,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      GameGlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zona peligrosa',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _deleteAccount,
                              child: const Text(
                                'Eliminar cuenta',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Esta acción es permanente. Se borrarán tus datos y favoritos.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: GamePalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_processing)
              Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: GamePalette.textPrimary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: GamePalette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
