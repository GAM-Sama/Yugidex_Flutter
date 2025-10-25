import 'package:flutter/material.dart' hide Card;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // Needed to call the ViewModel
import 'package:yugioh_scanner/core/theme/app_theme.dart';
import 'package:yugioh_scanner/models/card_model.dart';
import 'package:yugioh_scanner/models/user_card_model.dart'; // Import UserCard
import 'package:yugioh_scanner/view_models/card_list_view_model.dart'; // Import the ViewModel

// Helper class (unchanged)
class CardFrameColors {
  final Color backgroundColor;
  final Color textColor;
  CardFrameColors(this.backgroundColor, this.textColor);
}

/// REUSABLE card details panel for both screens.
class CardDetailPanel extends StatefulWidget { // Changed to StatefulWidget
  // Now accepts either UserCard (for collection) or Card (for processed cards)
  final UserCard? userCard;
  final Card? card; // New parameter for raw Card objects
  final bool isUserCollection;

  const CardDetailPanel({
    super.key,
    this.userCard, // Optional for collection
    this.card, // Optional for processed cards
    this.isUserCollection = false,
  });

  @override
  State<CardDetailPanel> createState() => _CardDetailPanelState();
}

class _CardDetailPanelState extends State<CardDetailPanel> { // Changed to State
  // State for the quantity to delete
  int _quantityToDelete = 1;

  // Reset quantity to delete if the selected card changes
  @override
  void didUpdateWidget(covariant CardDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the card changed (either UserCard or Card)
    final currentCardId = widget.userCard?.cardDetails.idCarta ?? widget.card?.idCarta;
    final oldCardId = oldWidget.userCard?.cardDetails.idCarta ?? oldWidget.card?.idCarta;

    if (currentCardId != oldCardId) {
      // Use setState in a post-frame callback to avoid issues during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) { // Check if the widget is still in the tree
           setState(() {
             _quantityToDelete = 1; // Reset to 1 when card changes
           });
         }
       });
    }
  }
  // End State

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // Get card details from either userCard or card
    final cardDetails = widget.userCard?.cardDetails ?? widget.card;

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
                physics: const BouncingScrollPhysics(), // Smoother scroll
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardDetails.nombre ?? 'Sin nombre',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTagsSection(context, cardDetails),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Container(
                        constraints:
                            const BoxConstraints(maxWidth: 150, maxHeight: 208), // Smaller image
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.sm), // Consistent radius
                          child: (cardDetails.imagen != null && cardDetails.imagen!.isNotEmpty)
                              ? CachedNetworkImage(
                                   imageUrl: cardDetails.imagen!,
                                   fit: BoxFit.contain, // Use contain to show full art
                                   placeholder: (context, url) =>
                                       Container(color: theme.dividerColor),
                                   errorWidget: (context, url, error) =>
                                       Image.asset( // Use back card as error placeholder
                                         'lib/assets/images/back-card.png',
                                         fit: BoxFit.contain,
                                       ),
                                 )
                              : Image.asset( // Fallback if no image URL
                                   'lib/assets/images/back-card.png',
                                   fit: BoxFit.contain,
                                 ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCardSpecificDetails(context, cardDetails),
                    const SizedBox(height: AppSpacing.lg),
                    if (cardDetails.idCarta.isNotEmpty)
                      _buildDetailRow(context, 'Código:', cardDetails.idCarta),
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
                          _getDescriptionText(cardDetails.descripcion),
                          softWrap: true,
                          style: textTheme.bodySmall
                              ?.copyWith(height: 1.4, fontSize: AppTextSizes.sm), // Use theme size
                        ),
                      ],
                    ),

                    // --- DELETE CARD SECTION (Only if it's user collection and we have a UserCard) ---
                    if (widget.isUserCollection && widget.userCard != null) ...[
                      const SizedBox(height: AppSpacing.xl), // More space before
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Eliminar de la Colección',
                        style: textTheme.titleMedium?.copyWith(color: AppColors.error), // Red
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
                        children: [
                          // --- Quantity Selector ---
                          Row(
                            children: [
                              // Minus Button
                              _buildQuantityButton(
                                context: context,
                                icon: Icons.remove,
                                onPressed: _quantityToDelete > 1
                                    ? () => setState(() => _quantityToDelete--)
                                    : null, // Disabled if 1
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                child: Text(
                                  '$_quantityToDelete / ${widget.userCard!.quantity}', // Show current / total
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Plus Button
                              _buildQuantityButton(
                                context: context,
                                icon: Icons.add,
                                onPressed: _quantityToDelete < widget.userCard!.quantity
                                    ? () => setState(() => _quantityToDelete++)
                                    : null, // Disabled if max
                              ),
                            ],
                          ),
                          // --- Delete Button ---
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_forever, size: 18),
                            label: const Text('Eliminar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error, // Red background
                              foregroundColor: AppColors.textPrimary, // White text
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2), // Slightly taller
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                              ),
                              textStyle: theme.textTheme.labelLarge?.copyWith(color: AppColors.textPrimary) // Ensure correct text style
                            ),
                            onPressed: () => _showDeleteConfirmationDialog(context, cardDetails.nombre ?? 'esta carta'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md), // Space at the end
                    ]
                    // --- END DELETE SECTION ---
                  ],
                ),
              ),
      ),
    );
  }

  // --- NEW: Button for +/- ---
  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 36, height: 36, // Fixed size
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          backgroundColor: AppColors.surface, // Dark background
          foregroundColor: onPressed != null ? AppColors.textPrimary : AppColors.textDisabled, // White or grey
          side: BorderSide(color: onPressed != null ? AppColors.border : AppColors.divider), // Border
        ).copyWith(
           // Remove shadow if disabled
           elevation: WidgetStateProperty.resolveWith<double>((states) {
             return states.contains(WidgetState.disabled) ? 0 : 2;
           })
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      ),
    );
  }

  // --- NEW: Confirmation Dialog ---
  void _showDeleteConfirmationDialog(BuildContext context, String cardName) {
    final theme = Theme.of(context);
    final quantity = _quantityToDelete;
    final totalQuantity = widget.userCard?.quantity ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor ?? AppColors.surface,
          shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.lg)),
          title: Text(
            'Confirmar Eliminación',
            style: theme.dialogTheme.titleTextStyle?.copyWith(color: AppColors.error),
          ),
          content: Text(
            '¿Seguro que quieres eliminar $quantity ${quantity == 1 ? 'copia' : 'copias'} de "$cardName"?\n\n${quantity >= totalQuantity ? 'Esto eliminará la carta de tu colección.' : 'Te quedarás con ${totalQuantity - quantity}.'}',
            style: theme.dialogTheme.contentTextStyle,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close only the dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textPrimary // Ensure white text
              ),
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _performDelete(context); // Call the function that executes the action
              },
            ),
          ],
        );
      },
    );
  }

  // --- NEW: Calls ViewModel to delete ---
  void _performDelete(BuildContext context) async {
    // Use listen: false because we are in a callback, not the build method
    final cardListVM = Provider.of<CardListViewModel>(context, listen: false);
    final userCardId = widget.userCard?.userCardId;
    final currentQuantity = widget.userCard?.quantity;

    if (userCardId != null && currentQuantity != null) {
      try {
        await cardListVM.deleteUserCardQuantity(
          userCardId: userCardId,
          quantityToDelete: _quantityToDelete,
          currentQuantity: currentQuantity,
        );
        // Optional: Show success Snackbar
        if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Carta actualizada/eliminada'), duration: Duration(seconds: 2))
         );
         // Reset quantity to 1 just in case
          // Use setState in a post-frame callback here as well
         WidgetsBinding.instance.addPostFrameCallback((_) {
           if(mounted) {
             setState(() => _quantityToDelete = 1);
           }
         });
        }
      } catch (e) {
         // Optional: Show error Snackbar
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al eliminar: ${e.toString()}'), backgroundColor: AppColors.error),
           );
         }
      }
    } else {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Error: No se pudo identificar la carta a eliminar.'), backgroundColor: AppColors.error),
         );
       }
    }
  }


  // --- HELPER FUNCTIONS (Unchanged) ---
  CardFrameColors _getCardFrameColors(BuildContext context, Card card) {
     final theme = Theme.of(context);
     final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
     final tipoLower = card.tipo?.toLowerCase() ?? '';
     final clasificacionLower = card.clasificacion?.toLowerCase() ?? '';
     final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();

     if (marcoLower.contains('fusion') || tipoLower.contains('fusion') || subtypesLower.contains('fusion')) return CardFrameColors(const Color(0xFFA086B7), Colors.white);
     if (marcoLower.contains('synchro') || tipoLower.contains('synchro') || subtypesLower.contains('synchro')) return CardFrameColors(const Color(0xFFF0F0F0), Colors.black);
     if (marcoLower.contains('xyz') || tipoLower.contains('xyz') || subtypesLower.contains('xyz')) return CardFrameColors(const Color(0xFF222222), Colors.white);
     if (marcoLower.contains('link') || tipoLower.contains('link') || subtypesLower.contains('link')) return CardFrameColors(const Color(0xFF0077CC), Colors.white);
     if (marcoLower.contains('ritual') || tipoLower.contains('ritual') || subtypesLower.contains('ritual')) return CardFrameColors(const Color(0xFF9DB5CC), Colors.white);
     if (marcoLower.contains('spell') || tipoLower.contains('spell')) return CardFrameColors(const Color(0xFF1D9E74), Colors.white);
     if (marcoLower.contains('trap') || tipoLower.contains('trap')) return CardFrameColors(const Color(0xFFBC5A84), Colors.white);
     if (marcoLower.contains('monster') || tipoLower.contains('monster')) {
       if (clasificacionLower == 'normal' || subtypesLower.contains('normal')) return CardFrameColors(const Color(0xFFFDE68A), Colors.black);
       return CardFrameColors(const Color(0xFFC07B41), Colors.white);
     }
     print("⚠️ Fallback color used for card: ${card.nombre}");
     return CardFrameColors(theme.dividerColor, theme.textTheme.bodyMedium!.color!);
  }

  Widget _buildTagsSection(BuildContext context, Card card) {
     final theme = Theme.of(context);
     final finalColors = _getCardFrameColors(context, card);
     List<Widget> tags = [];
     if (card.marcoCarta != null && card.marcoCarta!.isNotEmpty && card.marcoCarta != 'null') {
       final marcoLower = card.marcoCarta!.toLowerCase();
       String marcoDisplay;
       if (marcoLower.contains('monstruo') || marcoLower.contains('monster')) marcoDisplay = 'Monstruo';
       else if (marcoLower.contains('magia') || marcoLower.contains('spell')) marcoDisplay = 'Magia';
       else if (marcoLower.contains('trampa') || marcoLower.contains('trap')) marcoDisplay = 'Trampa';
       else marcoDisplay = card.marcoCarta!;
       tags.add(_buildTag(context, marcoDisplay, finalColors.backgroundColor, finalColors.textColor));
     }
     if (card.tipo != null && card.tipo!.isNotEmpty && card.tipo != 'null') {
       final tipoLower = card.tipo!.toLowerCase();
       if (!tipoLower.contains('spell card') && !tipoLower.contains('trap card')) {
         tags.add(_buildTag(context, card.tipo!, finalColors.backgroundColor, finalColors.textColor));
       }
     }
     if (card.clasificacion != null && card.clasificacion!.isNotEmpty && card.clasificacion != 'null') {
       tags.add(_buildTag(context, card.clasificacion!, finalColors.backgroundColor, finalColors.textColor));
     }
     if (card.subtipo != null) {
       for (var s in card.subtipo!) { if (s.isNotEmpty) tags.add(_buildTag(context, s, finalColors.backgroundColor, finalColors.textColor)); }
     }
     if ((card.subtipo == null || card.subtipo!.isEmpty) && card.iconoCarta != null && card.iconoCarta!.isNotEmpty && card.iconoCarta != 'null') {
       tags.add(_buildTag(context, card.iconoCarta!, finalColors.backgroundColor, finalColors.textColor));
     }
     if (card.rareza != null) {
       for (var r in card.rareza!) {
         if (r.isNotEmpty && r != 'null') {
           tags.add(_buildTag(context, r, theme.colorScheme.surface, theme.colorScheme.primary)); // Different style for rarity
         }
       }
     }
     // Show quantity if it's user collection and card has quantity info
     if(widget.isUserCollection && widget.userCard != null && widget.userCard!.quantity > 0) {
        tags.add(_buildTag(context, 'x${widget.userCard!.quantity}', AppColors.border, AppColors.textSecondary));
     }
     return Wrap(spacing: 6.0, runSpacing: 6.0, children: tags);
  }

  Widget _buildTag(BuildContext context, String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.5), width: 1), // Use opacity instead of alpha
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
           style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary), // Ensure default text color
           children: [
             TextSpan(
                 text: '$label ',
                 style: const TextStyle(fontWeight: FontWeight.bold)), // Keep label bold
             TextSpan(
                 text: value,
                 style: const TextStyle(color: AppColors.textSecondary)), // Value in secondary color
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
       final isLinkMonster = marcoLower.contains('link') || tipoLower.contains('link') || subtypesLower.contains('link');
       final isXyzMonster = marcoLower.contains('xyz') || tipoLower.contains('xyz') || subtypesLower.contains('xyz');
       // Assume 'escalaPendulo' exists on Card model if needed
       // final isPendulumMonster = marcoLower.contains('pendulum') || tipoLower.contains('pendulum') || subtypesLower.contains('pendulum');

       return Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _buildDetailRow(context, 'Atributo:', card.atributo),
                 if (isLinkMonster && card.ratioEnlace != null)
                   _buildDetailRow(context, 'Link:', card.ratioEnlace?.toString())
                 else if (isXyzMonster && card.nivelRankLink != null)
                   _buildDetailRow(context, 'Rango:', card.nivelRankLink?.toString())
                 // else if (isPendulumMonster) ...[
                 //   if (card.escalaPendulo != null) _buildDetailRow(context, 'Escala Péndulo:', card.escalaPendulo?.toString()),
                 //   if (card.nivelRankLink != null) _buildDetailRow(context, 'Nivel:', card.nivelRankLink?.toString()),
                 // ]
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
     return const SizedBox.shrink(); // Return empty for non-monsters
  }

  String _getDescriptionText(Map<String, dynamic>? descripcion) {
     String? rawDescription;
     if (descripcion == null || descripcion.isEmpty) return 'Descripción no disponible';
     if (descripcion.containsKey('texto') && descripcion['texto'] != null) rawDescription = descripcion['texto'].toString();
     else {
       String? extractDescription() {
         if (descripcion.containsKey('es') && descripcion['es'] != null) return descripcion['es'].toString();
         if (descripcion.containsKey('ES') && descripcion['ES'] != null) return descripcion['ES'].toString();
         if (descripcion.containsKey('en') && descripcion['en'] != null) return descripcion['en'].toString();
         if (descripcion.containsKey('EN') && descripcion['EN'] != null) return descripcion['EN'].toString();
         for (var value in descripcion.values) { if (value != null && value.toString().trim().isNotEmpty) return value.toString(); }
         return null;
       }
       rawDescription = extractDescription();
     }
     if (rawDescription == null || rawDescription.trim().isEmpty) return 'Descripción no disponible';
     // Replace HTML breaks with newlines
     final formattedDescription = rawDescription.replaceAll(RegExp(r'\s*<br */?>\s*', caseSensitive: false), '\n\n');
     return formattedDescription;
  }
} // End of _CardDetailPanelState