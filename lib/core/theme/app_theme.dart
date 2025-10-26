// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores principales de la aplicación
class AppColors {
  // --- DEFINICIÓN DE COLORES (PALETA AZUL) ---
  static const Color _scaffoldBg = Color(0xFF0A192F); // Azul marino muy oscuro
  static const Color _cardBg = Color(0xFF172A46);     // Azul medianoche
  static const Color _accentYellow = Color(0xFFFDE047); // Acento dorado
  static const Color _textPrimary = Color(0xFFFFFFFF); // Texto blanco
  static const Color _textSecondary = Color(0xFFA9B0BC); // Texto gris
  static const Color _darkText = Color(0xFF0A192F); // Texto oscuro (para botones)

  // Fondos y superficies
  static const Color background = _scaffoldBg;
  static const Color surface = _cardBg;
  static const Color cardBackground = _cardBg;

  // Textos
  static const Color textPrimary = _textPrimary;
  static const Color textSecondary = _textSecondary;
  static const Color textDisabled = _textSecondary;
  static const Color darkText = _darkText;

  // Estados y overlays
  static const Color loadingOverlay = Color(0x800A192F); // Con transparencia

  // Bordes y divisores
  static const Color border = Color(0xFF475569);
  static const Color divider = Color(0xFF334155);

  // Estados de éxito y error
  static const Color success = Color(0xFF10B981); // Verde
  static const Color error = Color(0xFFEF4444); // Rojo
  static const Color warning = Color(0xFFF59E0B); // Ámbar

  // Colores principales
  static const Color primary = _accentYellow;
  static const Color accent = _accentYellow;
}

/// Espaciado consistente en toda la aplicación
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Tamaños de texto tipográficos
class AppTextSizes {
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double md = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

/// Configuración de tema personalizado para la aplicación
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      cardColor: AppColors.cardBackground,

      // Esquema de color global
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: AppColors._darkText,
        onSurface: AppColors.textPrimary, // Texto sobre superficies (tarjetas)
      ),

// AppBar theme
      appBarTheme: AppBarTheme( // Quitamos el const para poder usar AppColors
        backgroundColor: AppColors.surface, // Tu color de fondo actual
        elevation: 0,
        centerTitle: true,
        // --- ¡AÑADIDO AQUÍ! ---
        scrolledUnderElevation: 0.0, // Evita que aparezca sombra al hacer scroll
        surfaceTintColor: AppColors.surface, // Asegura que el tinte sea el mismo color
        // --- FIN DEL AÑADIDO ---
        titleTextStyle: GoogleFonts.poppins( // Usar GoogleFonts aquí también
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        margin: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Fondo amarillo
          foregroundColor: AppColors._darkText, // Texto oscuro
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background, // Fondo principal (más oscuro)
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Sin borde
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2), // Borde amarillo al enfocar
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // Text themes
      textTheme: TextTheme(
        titleLarge: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.xl,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.md,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: AppTextSizes.sm,
        ),
        bodySmall: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: AppTextSizes.xs,
        ),
        displayMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: 36,
        ),
        labelLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors._darkText,
          fontSize: 16,
        ),
        labelSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.xs,
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) { // <-- CAMBIO AQUÍ
          if (states.contains(WidgetState.selected)) { // <-- CAMBIO AQUÍ
            return AppColors.accent;
          }
          return AppColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) { // <-- CAMBIO AQUÍ
          if (states.contains(WidgetState.selected)) { // <-- CAMBIO AQUÍ
            return AppColors.accent.withValues(alpha: 0.5);
          }
          return AppColors.border;
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) { // <-- CAMBIO AQUÍ
          if (states.contains(WidgetState.selected)) { // <-- CAMBIO AQUÍ
            return AppColors.accent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.background), // <-- CAMBIO AQUÍ
        side: const BorderSide(color: AppColors.border),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) { // <-- CAMBIO AQUÍ
          if (states.contains(WidgetState.selected)) { // <-- CAMBIO AQUÍ
            return AppColors.accent;
          }
          return Colors.transparent;
        }),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),

      // --- ¡BONUS AÑADIDO! ---
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBackground, // Fondo de panel
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: AppTextSizes.md,
        ),
      ),
    );
  }
}

/// Extensiones útiles para colores
extension ColorExtension on Color {
  Color withOpacity(double opacity) {
    return withValues(alpha: opacity);
  }
}