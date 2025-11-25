import 'dart:ui';
import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';

/// Fondo con gradiente gamer + luces tipo neón
class GameBackground extends StatelessWidget {
  final Widget child;

  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF020617),
            Color(0xFF050816),
            Color(0xFF020617),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Luces de ambiente
          Positioned(
            top: -80,
            left: -40,
            child: _NeonBlob(
              size: 200,
              color: GamePalette.primary.withOpacity(0.45),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -30,
            child: _NeonBlob(
              size: 220,
              color: GamePalette.secondary.withOpacity(0.40),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: _NeonBlob(
              size: 160,
              color: GamePalette.accent.withOpacity(0.35),
            ),
          ),

          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NeonBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _NeonBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

/// Título de sección (ej: “Tus favoritos”, “Explora juegos”, etc.)
class GameSectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;

  const GameSectionTitle({
    super.key,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GamePalette.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: GamePalette.secondary, size: 20),
          ),
        if (icon != null) const SizedBox(width: 10),
        Text(
          text,
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}

/// Card "glass" con blur y borde neón suave
class GameGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GameGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 26,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Botón principal con efecto neón y gradiente
class PrimaryGameButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool loading;

  const PrimaryGameButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = loading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isDisabled ? 0.7 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [
              GamePalette.primary,
              GamePalette.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: GamePalette.primary.withOpacity(0.6),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}
