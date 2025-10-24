// lib/shared/widgets/card_detail_panel.dart

import 'package:flutter/material.dart' hide Card;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yugioh_scanner/core/theme/app_theme.dart';
import 'package:yugioh_scanner/models/card_model.dart';

// Clase auxiliar
class CardFrameColors {
  final Color backgroundColor;
  final Color textColor;
  CardFrameColors(this.backgroundColor, this.textColor);
}

/// Panel de detalles de carta REUTILIZABLE para ambas pantallas.
class CardDetailPanel extends StatelessWidget {
  final Card? cardDetails;
  final bool isUserCollection;

  const CardDetailPanel({
    super.key,
    required this.cardDetails,
    this.isUserCollection = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Expanded(
      flex: 3,
      child: Container(
        color: theme.cardColor,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: cardDetails == null
            ? Center(
                child: Text('Selecciona una carta', style: textTheme.bodyMedium),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardDetails!.nombre ?? 'Sin nombre',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Llama a la función actualizada
                    _buildTagsSection(context, cardDetails!),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Container(
                        constraints:
                            const BoxConstraints(maxWidth: 150, maxHeight: 208),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (cardDetails!.imagen != null && cardDetails!.imagen!.isNotEmpty && cardDetails!.nombre != null && cardDetails!.nombre!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: cardDetails!.imagen ?? '',
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      Container(color: theme.dividerColor),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                        'lib/assets/back-card.png',
                                        fit: BoxFit.contain,
                                      ),
                                )
                              : Image.asset(
                                  'lib/assets/back-card.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCardSpecificDetails(context, cardDetails!),
                    const SizedBox(height: AppSpacing.lg),
                    // Mostramos 'idCarta' con la etiqueta "Código:"
                    if (cardDetails!.idCarta.isNotEmpty)
                      _buildDetailRow(context, 'Código:', cardDetails!.idCarta),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descripción:',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _getDescriptionText(cardDetails!.descripcion),
                          softWrap: true,
                          style: textTheme.bodySmall
                              ?.copyWith(height: 1.4, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // --- FUNCIONES HELPER ACTUALIZADAS ---

  /// Determina el color del marco basado en la jerarquía correcta.
  CardFrameColors _getCardFrameColors(BuildContext context, Card card) {
    final theme = Theme.of(context);
    // Usamos ?.toLowerCase() ?? '' para evitar errores si son null
    final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
    final tipoLower = card.tipo?.toLowerCase() ?? ''; // Puede ser 'Guerrero', 'Carta Mágica', etc.
    final clasificacionLower = card.clasificacion?.toLowerCase() ?? '';
    // Revisamos también los subtipos por si acaso
    final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();

    // --- ¡LÓGICA CORREGIDA AQUÍ! ---
    // 1. Prioridad MÁXIMA: Tipos específicos (Extra Deck, Ritual, etc.)
    //    Si coincide uno de estos, usamos su color y TERMINAMOS.
    if (marcoLower.contains('fusion') || tipoLower.contains('fusion') || subtypesLower.contains('fusion')) {
      return CardFrameColors(const Color(0xFFA086B7), Colors.white); // Lila
    }
    if (marcoLower.contains('synchro') || tipoLower.contains('synchro') || subtypesLower.contains('synchro')) {
      return CardFrameColors(const Color(0xFFF0F0F0), Colors.black); // Blanco
    }
    if (marcoLower.contains('xyz') || tipoLower.contains('xyz') || subtypesLower.contains('xyz')) {
      return CardFrameColors(const Color(0xFF222222), Colors.white); // Negro
    }
    if (marcoLower.contains('link') || tipoLower.contains('link') || subtypesLower.contains('link')) {
      return CardFrameColors(const Color(0xFF0077CC), Colors.white); // Azul oscuro
    }
    if (marcoLower.contains('ritual') || tipoLower.contains('ritual') || subtypesLower.contains('ritual')) {
      return CardFrameColors(const Color(0xFF9DB5CC), Colors.white); // Azul claro
    }

    // 2. Si NO es de los anteriores, miramos si es Magia o Trampa
    if (marcoLower.contains('spell') || tipoLower.contains('spell')) { // Usamos 'spell' más genérico
      return CardFrameColors(const Color(0xFF1D9E74), Colors.white); // Verde
    }
    if (marcoLower.contains('trap') || tipoLower.contains('trap')) { // Usamos 'trap' más genérico
      return CardFrameColors(const Color(0xFFBC5A84), Colors.white); // Rosáceo
    }

    // 3. Si NO es Magia/Trampa, y NO es especial, ENTONCES es un Monstruo del Main Deck.
    //    Ahora sí miramos la clasificación (Normal/Efecto).
    //    Nos aseguramos que sea monstruo antes de asignar color amarillo/naranja
    if (marcoLower.contains('monster') || tipoLower.contains('monster')) {
      if (clasificacionLower == 'normal' || subtypesLower.contains('normal')) { // Check ambos
        return CardFrameColors(const Color(0xFFFDE68A), Colors.black); // Amarillo
      }
      // Si es monstruo y no es Normal (o no tiene clasificación), asumimos Efecto.
      return CardFrameColors(const Color(0xFFC07B41), Colors.white); // Naranja/Marrón
    }

    // 4. Fallback: Si no coincide nada (muy raro), usamos color del tema
    print("⚠️ Fallback color used for card: ${card.nombre}");
    return CardFrameColors(theme.dividerColor, theme.textTheme.bodyMedium!.color!);
  }

  /// Construye los tags usando el color determinado por _getCardFrameColors.
  Widget _buildTagsSection(BuildContext context, Card card) {
    final theme = Theme.of(context);
    // Obtenemos EL color principal definitivo para esta carta
    final finalColors = _getCardFrameColors(context, card);
    List<Widget> tags = [];

    // 1. Marco de carta (Monstruo, Magia, Trampa) - Usa el color definitivo
    if (card.marcoCarta != null && card.marcoCarta!.isNotEmpty && card.marcoCarta != 'null') {
      final marcoLower = card.marcoCarta!.toLowerCase();
      String marcoDisplay;
      if (marcoLower.contains('monstruo') || marcoLower.contains('monster')) {
        marcoDisplay = 'Monstruo';
      } else if (marcoLower.contains('magia') || marcoLower.contains('spell')) {
        marcoDisplay = 'Magia';
      } else if (marcoLower.contains('trampa') || marcoLower.contains('trap')) {
        marcoDisplay = 'Trampa';
      } else {
        marcoDisplay = card.marcoCarta!;
      }
      tags.add(_buildTag(context, marcoDisplay, finalColors.backgroundColor, finalColors.textColor));
    }

    // 2. Tipo (Guerrero, Dragón...) - Usa el color definitivo
    if (card.tipo != null && card.tipo!.isNotEmpty && card.tipo != 'null') {
      final tipoLower = card.tipo!.toLowerCase();
      if (!tipoLower.contains('spell card') && !tipoLower.contains('trap card')) {
         tags.add(_buildTag(context, card.tipo!, finalColors.backgroundColor, finalColors.textColor));
      }
    }

    // 3. Clasificación (Normal, Efecto, Cantante...) - Usa el color definitivo
    if (card.clasificacion != null && card.clasificacion!.isNotEmpty && card.clasificacion != 'null') {
       tags.add(_buildTag(context, card.clasificacion!, finalColors.backgroundColor, finalColors.textColor));
    }

    // 4. Subtipos (Fusión, Xyz, Volteo...) - Usa el color definitivo
    if (card.subtipo != null) {
      for (var s in card.subtipo!) {
        if (s.isNotEmpty) {
          tags.add(_buildTag(context, s, finalColors.backgroundColor, finalColors.textColor));
        }
      }
    }
    
    // 5. Icono (si no hay subtipos) - Usa el color definitivo
    if ((card.subtipo == null || card.subtipo!.isEmpty) && card.iconoCarta != null && card.iconoCarta!.isNotEmpty && card.iconoCarta != 'null') {
      tags.add(_buildTag(context, card.iconoCarta!, finalColors.backgroundColor, finalColors.textColor));
    }

    // 6. Rareza (ESTE SÍ TIENE ESTILO PROPIO Y DIFERENTE)
    if (card.rareza != null) {
      for (var r in card.rareza!) {
        if (r.isNotEmpty && r != 'null') {
          tags.add(_buildTag(
            context,
            r,
            // Estilo diferente para la rareza
            isUserCollection ? theme.colorScheme.surface : Colors.grey.shade800,
            isUserCollection ? theme.colorScheme.primary : Colors.yellow.shade200,
          ));
        }
      }
    }
    return Wrap(spacing: 6.0, runSpacing: 6.0, children: tags);
  }

  // --- Resto de funciones (_buildTag, _buildDetailRow, etc. SIN CAMBIOS) ---

  Widget _buildTag(BuildContext context, String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
     if (value == null || value.trim().isEmpty || value == 'null') return const SizedBox.shrink();
     final textTheme = Theme.of(context).textTheme;
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 3.0),
       child: RichText(
         text: TextSpan(
           style: textTheme.bodyMedium,
           children: [
             TextSpan(
                 text: '$label ',
                 style: textTheme.bodyMedium
                     ?.copyWith(fontWeight: FontWeight.bold)),
             TextSpan(
                 text: value,
                 style:
                     textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
           ],
         ),
       ),
     );
  }

  Widget _buildCardSpecificDetails(BuildContext context, Card card) {
     final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
     final tipoLower = card.tipo?.toLowerCase() ?? '';
     final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();
     final isMonster = marcoLower.contains('monstruo') || marcoLower.contains('monster');

     if (isMonster) {
       // Detectar tipo de monstruo especial usando múltiples campos (igual que en _getCardFrameColors)
       final isLinkMonster = marcoLower.contains('link') || tipoLower.contains('link') || subtypesLower.contains('link');
       final isXyzMonster = marcoLower.contains('xyz') || tipoLower.contains('xyz') || subtypesLower.contains('xyz');
       final isPendulumMonster = marcoLower.contains('pendulum') || tipoLower.contains('pendulum') || subtypesLower.contains('pendulum');

       return Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _buildDetailRow(context, 'Atributo:', card.atributo),
                 // Para cartas Link: mostrar ratioEnlace con etiqueta "Link:"
                 if (isLinkMonster && card.ratioEnlace != null)
                   _buildDetailRow(context, 'Link:', card.ratioEnlace?.toString())
                 // Para cartas Xyz: mostrar nivelRankLink con etiqueta "Rango:"
                 else if (isXyzMonster && card.nivelRankLink != null)
                   _buildDetailRow(context, 'Rango:', card.nivelRankLink?.toString())
                 // Para cartas de péndulo: mostrar escala de péndulo y nivel
                 else if (isPendulumMonster) ...[
                   if (card.escalaPendulo != null)
                     _buildDetailRow(context, 'Escala Péndulo:', card.escalaPendulo?.toString()),
                   if (card.nivelRankLink != null)
                     _buildDetailRow(context, 'Nivel:', card.nivelRankLink?.toString()),
                 ]
                 // Para otros monstruos: mostrar nivelRankLink con etiqueta "Nivel:"
                 else if (card.nivelRankLink != null)
                   _buildDetailRow(context, 'Nivel:', card.nivelRankLink?.toString()),
               ],
             ),
           ),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 if (card.atk != null || card.def != null)
                   _buildDetailRow(
                     context,
                     'ATK/DEF:',
                     isLinkMonster
                         ? '${card.atk ?? '?'}/-'
                         : '${card.atk ?? '?'}/${card.def ?? '?'}',
                   ),
               ],
             ),
           ),
         ],
       );
     }
     return const SizedBox.shrink();
  }

  String _getDescriptionText(Map<String, dynamic>? descripcion) {
     String? rawDescription;
     if (descripcion == null || descripcion.isEmpty) { return 'Descripción no disponible'; }
     if (descripcion.containsKey('texto') && descripcion['texto'] != null) { rawDescription = descripcion['texto'].toString(); }
     else {
       String? extractDescription() {
         if (descripcion.containsKey('es') && descripcion['es'] != null) { return descripcion['es'].toString(); }
         if (descripcion.containsKey('ES') && descripcion['ES'] != null) { return descripcion['ES'].toString(); }
         if (descripcion.containsKey('en') && descripcion['en'] != null) { return descripcion['en'].toString(); }
         if (descripcion.containsKey('EN') && descripcion['EN'] != null) { return descripcion['EN'].toString(); }
         for (var value in descripcion.values) {
           if (value != null && value.toString().trim().isNotEmpty) {
             return value.toString();
           }
         }
         return null;
       }
       rawDescription = extractDescription();
     }
     if (rawDescription == null || rawDescription.trim().isEmpty) { return 'Descripción no disponible'; }
     final formattedDescription = rawDescription.replaceAll(RegExp(r'\s*<br */?>\s*', caseSensitive: false), '\n');
     return formattedDescription;
  }
}