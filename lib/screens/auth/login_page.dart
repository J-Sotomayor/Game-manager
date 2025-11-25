import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_service.dart';
import '../main/main_app_screen.dart';
import '../widgets/game_ui.dart';
import 'register_page.dart';
import '../../providers/theme_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      await auth.login(email, password);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainAppScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      _showError('Correo o contraseña incorrectos');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Game Manager"),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GameGlassCard(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge superior + icono gamer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.videogame_asset_rounded,
                                  size: 18,
                                  color: GamePalette.secondary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Panel gamer",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: GamePalette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: GamePalette.textSecondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Bienvenido de vuelta 👋',
                        style: theme.textTheme.titleLarge?.copyWith(
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Accede a tu panel para gestionar juegos, precios y favoritos como un pro.',
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 22),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'El correo es obligatorio';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) {
                            return 'La contraseña es obligatoria';
                          }
                          if (v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Filita de "recordatorio" / detalle
                      Row(
                        children: [
                          Icon(
                            Icons.shield_moon_outlined,
                            size: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Tus credenciales están protegidas con Firebase.",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Botón de login
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryGameButton(
                          text: "Iniciar sesión",
                          loading: _isLoading,
                          onPressed: _login,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Mini-features bajo el botón
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _FeaturePill(
                            icon: Icons.storage_rounded,
                            text: "Guarda tu catálogo",
                          ),
                          _FeaturePill(
                            icon: Icons.favorite_rounded,
                            text: "Gestiona favoritos",
                          ),
                          _FeaturePill(
                            icon: Icons.price_change_rounded,
                            text: "Controla precios",
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Link registro
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "¿No tienes cuenta? Regístrate",
                          ),
                        ),
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

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: GamePalette.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: GamePalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
