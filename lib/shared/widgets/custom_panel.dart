// lib/shared/widgets/custom_panel.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart'; // Importa tu tema

/// Un widget reutilizable que muestra un panel con el estilo
/// de fondo y bordes redondeados definidos en el AppTheme.
class CustomPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const CustomPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md), // Usa tu constante!
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;

    // --- CORRECCIÓN AQUÍ ---
    // Obtenemos el BorderRadius de forma segura
    BorderRadius cardBorderRadius = BorderRadius.circular(12); // Valor por defecto
    if (cardTheme.shape is RoundedRectangleBorder) {
      final shape = cardTheme.shape as RoundedRectangleBorder;
      // Nos aseguramos de que sea un BorderRadius y no otro tipo de Geometría
      if (shape.borderRadius is BorderRadius) {
        cardBorderRadius = shape.borderRadius as BorderRadius;
      }
    }
    // --- FIN DE LA CORRECCIÓN ---

    Widget content = Container(
      padding: padding,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardTheme.color ?? theme.cardColor,
        // Usamos la variable corregida (BorderRadius es compatible con BorderRadiusGeometry)
        borderRadius: cardBorderRadius,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        // Usamos la variable corregida (que es del tipo BorderRadius)
        borderRadius: cardBorderRadius,
        child: content,
      );
    }

    return content;
  }
}