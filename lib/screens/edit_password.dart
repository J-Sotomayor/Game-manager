import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'widgets/game_ui.dart';
import '../providers/theme_provider.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay usuario autenticado.')),
      );
      return;
    }

    final currentPassword = _currentController.text.trim();
    final newPassword = _newController.text.trim();

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Reautenticar al usuario por seguridad
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // 2️⃣ Actualizar contraseña
      await user.updatePassword(newPassword);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );

      Navigator.pop(context); // volver a Ajustes
    } on FirebaseAuthException catch (e) {
      String msg = 'No se pudo cambiar la contraseña.';
      if (e.code == 'wrong-password') {
        msg = 'La contraseña actual es incorrecta.';
      } else if (e.code == 'weak-password') {
        msg = 'La nueva contraseña es demasiado débil.';
      } else if (e.code == 'requires-recent-login') {
        msg =
            'Por seguridad, vuelve a iniciar sesión y luego intenta cambiar la contraseña.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al cambiar contraseña')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Cambiar contraseña"),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GameGlassCard(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // encabezado
                      Text(
                        "Protege tu cuenta 🔐",
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Actualiza tu contraseña para mantener tu panel gamer seguro.",
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),

                      // contraseña actual
                      TextFormField(
                        controller: _currentController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: "Contraseña actual",
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrent = !_obscureCurrent;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) {
                            return 'Ingresa tu contraseña actual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // nueva contraseña
                      TextFormField(
                        controller: _newController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: "Nueva contraseña",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNew = !_obscureNew;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) {
                            return 'Ingresa la nueva contraseña';
                          }
                          if (v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          if (v == _currentController.text) {
                            return 'Debe ser distinta a la actual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // confirmar contraseña
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: "Confirmar nueva contraseña",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) {
                            return 'Confirma la nueva contraseña';
                          }
                          if (v != _newController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: PrimaryGameButton(
                          text: "Guardar nueva contraseña",
                          loading: _isLoading,
                          onPressed: _changePassword,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Tu contraseña se almacena de forma segura en Firebase Authentication.",
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                color: GamePalette.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
