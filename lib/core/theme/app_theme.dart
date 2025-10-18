import 'package:flutter/material.dart';

/// Colores principales de la aplicación
class AppColors {
  // Colores principales azul oscuro
  static const Color primary = Color(0xFF1E3A8A); // Azul oscuro profundo
  static const Color primaryDark = Color(0xFF1E40AF); // Azul oscuro más intenso
  static const Color primaryLight = Color(0xFF3B82F6); // Azul medio para hover/estados

  // Elementos seleccionados - Amarillo/Dorado
  static const Color accent = Color(0xFFFFD700); // Dorado
  static const Color accentDark = Color(0xFFFFB300); // Dorado más oscuro para hover
  static const Color accentLight = Color(0xFFFFFF8C); // Dorado claro para estados

  // Estados de éxito y error
  static const Color success = Color(0xFF10B981); // Verde esmeralda
  static const Color error = Color(0xFFEF4444); // Rojo
  static const Color warning = Color(0xFFF59E0B); // Ámbar

  // Fondos y superficies azul oscuro
  static const Color background = Color(0xFF0F172A); // Azul muy oscuro casi negro
  static const Color surface = Color(0xFF1E293B); // Azul grisaceo oscuro
  static const Color cardBackground = Color(0xFF334155); // Azul grisaceo medio

  // Textos blancos
  static const Color textPrimary = Color(0xFFFFFFFF); // Blanco puro
  static const Color textSecondary = Color(0xFFE2E8F0); // Blanco grisaceo
  static const Color textDisabled = Color(0xFF94A3B8); // Gris azulado claro

  // Estados y overlays
  static const Color loadingOverlay = Color(0x800F172A); // Azul oscuro con transparencia

  // Bordes y divisores azul sutil
  static const Color border = Color(0xFF475569); // Azul grisaceo para bordes
  static const Color divider = Color(0xFF334155); // Azul grisaceo para divisores
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
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Card theme
      cardTheme: CardTheme(
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
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        hintStyle: TextStyle(color: AppColors.textDisabled),
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),

      // Text themes
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.xl,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppTextSizes.md,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppTextSizes.sm,
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.accent;
          }
          return AppColors.textDisabled;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.accent.withOpacity(0.5);
          }
          return AppColors.border;
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.accent;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(AppColors.background),
        side: BorderSide(color: AppColors.border),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
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
    );
  }
}

/// Extensiones útiles para colores
extension ColorExtension on Color {
  Color withOpacity(double opacity) {
    return Color.fromRGBO(
      red,
      green,
      blue,
      opacity,
    );
  }
}
