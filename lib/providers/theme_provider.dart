import 'package:flutter/material.dart';

/// Paleta de colores para la app gamer
class GamePalette {
  static const Color background = Color(0xFF050816);      // Fondo principal
  static const Color surface = Color(0xFF111827);         // Tarjetas / contenedores
  static const Color surfaceAlt = Color(0xFF1F2937);      // Variación de surface
  static const Color primary = Color(0xFF7C3AED);         // Morado gamer
  static const Color secondary = Color(0xFF22D3EE);       // Cian neón
  static const Color accent = Color(0xFFF97316);          // Naranja detalle
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
}

class ThemeProvider extends ChangeNotifier {
  bool isDark = true; // modo oscuro gamer por defecto

  /// Soporta tanto toggleTheme() como toggleTheme(true/false)
  void toggleTheme([bool? value]) {
    if (value != null) {
      isDark = value;
    } else {
      isDark = !isDark;
    }
    notifyListeners();
  }

  ThemeData get lightTheme => _buildLightTheme();
  ThemeData get darkTheme => _buildDarkTheme();
}

/// Tema oscuro principal (para juegos)
ThemeData _buildDarkTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    scaffoldBackgroundColor: GamePalette.background,
    primaryColor: GamePalette.primary,
    colorScheme: const ColorScheme.dark(
      primary: GamePalette.primary,
      secondary: GamePalette.secondary,
      surface: GamePalette.surface,
      error: Colors.redAccent,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: GamePalette.textPrimary,
      ),
      iconTheme: IconThemeData(color: GamePalette.textPrimary),
    ),

    // 🔧 AQUÍ CAMBIA: CardThemeData en lugar de CardTheme
    cardTheme: CardThemeData(
      color: GamePalette.surface,
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GamePalette.surfaceAlt,
      labelStyle: const TextStyle(color: GamePalette.textSecondary),
      hintStyle: const TextStyle(color: GamePalette.textSecondary),
      prefixIconColor: GamePalette.secondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GamePalette.secondary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GamePalette.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: GamePalette.secondary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: GamePalette.surface,
      selectedItemColor: GamePalette.secondary,
      unselectedItemColor: GamePalette.textSecondary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),

    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: GamePalette.textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        color: GamePalette.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: GamePalette.textSecondary,
      ),
    ),
  );
}

/// Tema claro por si quieres permitir cambiar
ThemeData _buildLightTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF3F4FF),
    primaryColor: GamePalette.primary,
    colorScheme: const ColorScheme.light(
      primary: GamePalette.primary,
      secondary: GamePalette.secondary,
      surface: Colors.white,
      error: Colors.redAccent,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    ),

    // 🔧 También aquí: CardThemeData
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.black54),
      hintStyle: const TextStyle(color: Colors.black38),
      prefixIconColor: GamePalette.primary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GamePalette.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GamePalette.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: GamePalette.secondary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: GamePalette.primary,
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),

    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: Colors.black54,
      ),
    ),
  );
}
