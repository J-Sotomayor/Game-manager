import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:game_manager_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import '../auth/login_page.dart';
import '../widgets/game_ui.dart';
import '../../providers/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _deletingAccount = false;
  bool _updatingPassword = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  // ===================== ELIMINAR CUENTA =====================

  Future<void> _onDeleteAccountPressed() async {
    if (_deletingAccount) return;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: const Text(
              'Esta acción es permanente.\n\n'
              'Se eliminarán:\n'
              '• Tu cuenta\n'
              '• Tus juegos del catálogo\n'
              '• Tus favoritos\n\n'
              '¿Seguro que quieres continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar definitivamente'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    await _deleteAccountAndData();
  }

  Future<void> _deleteAccountAndData() async {
    final user = _user;
    if (user == null) return;

    setState(() => _deletingAccount = true);

    try {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      // 1) Juegos creados por el usuario
      final gamesSnap = await firestore
          .collection('games')
          .where('createdBy', isEqualTo: uid)
          .get();

      final batch = firestore.batch();
      for (final doc in gamesSnap.docs) {
        batch.delete(doc.reference);
      }

      // 2) Favoritos (subcolección users/{uid}/favorites)
      final favsSnap = await firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();

      for (final doc in favsSnap.docs) {
        batch.delete(doc.reference);
      }

      // 3) Doc del usuario en "users"
      batch.delete(firestore.collection('users').doc(uid));

      await batch.commit();

      // 4) Eliminar cuenta de autenticación
      await user.delete();

      if (!mounted) return;

      // 5) Volver al login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'No se pudo eliminar la cuenta.';
      if (e.code == 'requires-recent-login') {
        msg =
            'Por seguridad, cierra sesión e inicia nuevamente antes de eliminar la cuenta.';
      }

      if (mounted) {
        setState(() => _deletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la cuenta: $e')),
      );
    }
  }

  // ===================== CAMBIAR CONTRASEÑA =====================

  Future<void> _onChangePassword() async {
    if (_updatingPassword) return;
    final user = _user;
    if (user == null || user.email == null) return;

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cambiar contraseña'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa tu contraseña actual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa una nueva contraseña';
                      }
                      if (v.length < 6) {
                        return 'Debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                    ),
                    validator: (v) {
                      if (v != newController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() => _updatingPassword = true);

    try {
      // Reautenticación
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newController.text.trim());

      if (!mounted) return;
      setState(() => _updatingPassword = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'No se pudo cambiar la contraseña.';
      if (e.code == 'wrong-password') {
        msg = 'La contraseña actual es incorrecta.';
      } else if (e.code == 'weak-password') {
        msg = 'La nueva contraseña es demasiado débil.';
      } else if (e.code == 'requires-recent-login') {
        msg =
            'Por seguridad, cierra sesión e inicia nuevamente antes de cambiar la contraseña.';
      }

      if (mounted) {
        setState(() => _updatingPassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingPassword = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar la contraseña: $e')),
      );
    }
  }

  // ===================== CAMBIAR NOMBRE (SIMPLE) =====================

  Future<void> _onChangeName() async {
    final user = _user;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cambiar nombre / apellido'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre para mostrar',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await user.updateDisplayName(controller.text.trim());

      // Opcional: guardar también en colección "users"
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {'displayName': controller.text.trim()},
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el nombre: $e')),
      );
    }
  }

  // ===================== CAMBIAR FOTO (PLACEHOLDER) =====================

  void _onChangePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cambiar foto de perfil: aquí puedes conectar tu lógica de subida de imagen 👾',
        ),
      ),
    );
  }

  // ===================== CERRAR SESIÓN =====================

  Future<void> _onLogout() async {
    final auth = Provider.of<AuthService>(context, listen: false);

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content:
                const Text('¿Seguro que quieres cerrar sesión en Game Manager?'),
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

    await auth.logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER PERFIL
              GameGlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Jugador',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

              const SizedBox(height: 18),

              // SECCIÓN AJUSTES
              GameGlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Cambiar nombre / apellido',
                      onTap: _onChangeName,
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Cambiar contraseña',
                      trailing: _updatingPassword
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : null,
                      onTap: _updatingPassword ? null : _onChangePassword,
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    _SettingsTile(
                      icon: Icons.image_outlined,
                      label: 'Cambiar foto de perfil',
                      onTap: _onChangePhoto,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // CERRAR SESIÓN
              GameGlassCard(
                padding: EdgeInsets.zero,
                child: _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Cerrar sesión',
                  iconColor: Colors.orangeAccent,
                  textColor: Colors.orangeAccent,
                  onTap: _onLogout,
                ),
              ),

              const SizedBox(height: 18),

              // ZONA PELIGROSA
              GameGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zona peligrosa',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Eliminar cuenta',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Esta acción es permanente. Se borrarán tus datos, juegos y favoritos.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GamePalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed:
                            _deletingAccount ? null : _onDeleteAccountPressed,
                        child: _deletingAccount
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.redAccent),
                                ),
                              )
                            : const Text(
                                'Eliminar cuenta',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== WIDGET AUXILIAR =====================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.white,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor ?? Colors.white,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white70,
          ),
      onTap: onTap,
      dense: true,
    );
  }
}
