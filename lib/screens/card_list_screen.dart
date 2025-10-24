import 'package:flutter/material.dart' hide Card; // Avoid conflict if Card model exists
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// --- Make sure these imports are correct based on your project structure ---
import 'package:yugioh_scanner/shared/widgets/card_detail_panel.dart';
import 'package:yugioh_scanner/shared/widgets/collection_toolbar.dart';
import 'package:yugioh_scanner/shared/widgets/filters_dialog.dart';
import 'package:yugioh_scanner/core/theme/app_theme.dart';
import 'package:yugioh_scanner/services/supabase_service.dart'; // Mantengo el import aunque no se use directamente aquí
import 'package:yugioh_scanner/view_models/card_list_view_model.dart';
import 'package:yugioh_scanner/view_models/card_filters_view_model.dart';
import 'package:yugioh_scanner/models/card_filters.dart'; // Imports SortBy/SortDirection/CardFilters
import 'package:yugioh_scanner/models/user_card_model.dart'; // Imports UserCardModel
import 'package:yugioh_scanner/models/card_model.dart'; // Imports your 'Card' class
// --- End of imports ---

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardListVM = Provider.of<CardListViewModel>(context, listen: false);
      // Ensure initialize takes SupabaseService if needed by your ViewModel implementation
      // cardListVM.initialize(Provider.of<SupabaseService>(context, listen: false));
      cardListVM.fetchCards(); // Fetch cards on init
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- HELPER FUNCTION FOR SORTING BY CARD TYPE (Sin cambios) ---
  String _getCardSortValue(Card card) {
    const Map<String, int> typeOrder = {'Monster': 1, 'Spell': 2, 'Trap': 3};
    const Map<String, int> monsterSubtypeOrder = {
      'Fusion': 1, 'Synchro': 2, 'Xyz': 3, 'Link': 4, 'Pendulum': 5,
      'Ritual': 6, 'Effect': 7, 'Normal': 8, 'Tuner': 9, 'Flip': 10,
      'Gemini': 11, 'Spirit': 12, 'Toon': 13, 'Union': 14
    };
    const Map<String, int> spellTrapOrder = {
      'Normal': 1, 'Continuous': 2, 'Equip': 3, 'Quick-Play': 4,
      'Field': 5, 'Ritual': 6, 'Counter': 7
    };

    final int primary = typeOrder[card.marcoCarta ?? ''] ?? 99;

    // Detección mejorada de tipos especiales usando múltiples campos (igual que en panel de detalles)
    String? getDetectedMonsterType() {
      final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
      final tipoLower = card.tipo?.toLowerCase() ?? '';
      final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();

      // Detectar tipos especiales
      if (marcoLower.contains('link') || tipoLower.contains('link') || subtypesLower.contains('link')) {
        return 'Link';
      }
      if (marcoLower.contains('xyz') || tipoLower.contains('xyz') || subtypesLower.contains('xyz')) {
        return 'Xyz';
      }
      if (marcoLower.contains('pendulum') || tipoLower.contains('pendulum') || subtypesLower.contains('pendulum')) {
        return 'Pendulum';
      }
      if (marcoLower.contains('fusion') || tipoLower.contains('fusion') || subtypesLower.contains('fusion') || subtypesLower.contains('fusión')) {
        return 'Fusion';
      }
      if (marcoLower.contains('synchro') || tipoLower.contains('synchro') || subtypesLower.contains('synchro')) {
        return 'Synchro';
      }
      if (marcoLower.contains('ritual') || tipoLower.contains('ritual') || subtypesLower.contains('ritual')) {
        return 'Ritual';
      }

      // Si no es tipo especial, usar subtipo o clasificación original
      if (card.subtipo?.isNotEmpty == true) {
        return card.subtipo![0];
      }
      return card.clasificacion;
    }

    int secondary = 99;
    if (card.marcoCarta == 'Monster') {
      final detectedType = getDetectedMonsterType();
      if (detectedType != null && monsterSubtypeOrder.containsKey(detectedType)) {
        secondary = monsterSubtypeOrder[detectedType]!;
      } else if (card.clasificacion != null && monsterSubtypeOrder.containsKey(card.clasificacion)) {
         secondary = monsterSubtypeOrder[card.clasificacion!]!;
      }
    } else if (card.clasificacion != null && spellTrapOrder.containsKey(card.clasificacion)) {
      secondary = spellTrapOrder[card.clasificacion!]!;
    }
    return '${primary.toString().padLeft(2, '0')}-${secondary.toString().padLeft(2, '0')}';
  }
  // --- END OF HELPER FUNCTION ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => CardFiltersViewModel(),
      child: Consumer2<CardListViewModel, CardFiltersViewModel>(
        builder: (context, cardVM, filterVM, _) {
          final processedCards = _applyFilters(cardVM, filterVM);

          if (cardVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cardVM.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${cardVM.errorMessage}',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
            );
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Row(
                children: [
                  CardDetailPanel(
                    cardDetails: cardVM.selectedCard?.cardDetails,
                    isUserCollection: true,
                  ),

                  Container(width: 1, color: theme.dividerColor),

                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        CollectionToolbar(
                          searchController: _searchController,
                          searchText: filterVM.filters.search,
                          onSearchChanged: (value) => filterVM.updateFilter('search', value),
                          onSortPressed: () => _showSortDialog(context, filterVM),
                          onFilterPressed: () => _showFilterDialog(context, filterVM),
                          sortBy: filterVM.sortBy,
                          sortDirection: filterVM.sortDirection,
                          activeFilterCount: _getActiveFiltersCount(filterVM),
                        ),
                        Expanded(
                          child: processedCards.isEmpty
                              ? Center(
                                  child: Text(
                                    filterVM.filters.search.isEmpty && _getActiveFiltersCount(filterVM) == 0
                                        ? 'Tu colección está vacía'
                                        : 'No se encontraron cartas con esos filtros',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                )
                              : AnimationLimiter(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: AppSpacing.sm,
                                      mainAxisSpacing: AppSpacing.sm,
                                      childAspectRatio: 0.70,
                                    ),
                                    itemCount: processedCards.length,
                                    itemBuilder: (context, index) {
                                      final userCard = processedCards[index];
                                      final Card card = userCard.cardDetails;
                                      final bool isSelected = cardVM.selectedCard?.cardDetails.idCarta == card.idCarta;

                                      return AnimationConfiguration.staggeredGrid(
                                        position: index,
                                        duration: const Duration(milliseconds: 375),
                                        columnCount: 6,
                                        child: ScaleAnimation(
                                          child: FadeInAnimation(
                                            child: GestureDetector(
                                              onTap: () => cardVM.selectCard(userCard),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : Colors.transparent,
                                                    width: 2.5,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                                                  child: CachedNetworkImage(
                                                    imageUrl: card.imagen ?? '',
                                                    fit: BoxFit.cover,
                                                    placeholder: (c, u) =>
                                                        Container(color: theme.colorScheme.surface),
                                                    errorWidget: (c, u, e) {
                                                      // Si la carta no tiene nombre (es fallida) o no tiene imagen, mostrar back-card.png
                                                      if (card.nombre == null || card.nombre!.isEmpty || card.imagen == null || card.imagen!.isEmpty) {
                                                        return Image.asset(
                                                          'lib/assets/back-card.png',
                                                          fit: BoxFit.cover,
                                                        );
                                                      }
                                                      // Si hay error de carga pero la carta es válida, mostrar back-card.png en lugar del icono de error
                                                      return Image.asset(
                                                        'lib/assets/back-card.png',
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Applies all configured filters: search, types, attributes, etc., and sorts the results.
  List<UserCard> _applyFilters( // <-- Corregido tipo de retorno
      CardListViewModel cardVM, CardFiltersViewModel filterVM) {
    final filters = filterVM.filters;
    final sortBy = filterVM.sortBy;
    final sortDirection = filterVM.sortDirection;

    // 1. Apply filters (Your existing filter logic - NO CHANGES HERE)
    var filteredCards = cardVM.cards.where((userCard) {
      final Card card = userCard.cardDetails; // Use Card type

      final query = filters.search.toLowerCase();
      if (query.isNotEmpty) {
        final matchesSearch = (card.nombre?.toLowerCase().contains(query) ?? false) ||
            card.idCarta.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }
      if (filters.cardTypes.isNotEmpty) {
        final cardType = card.marcoCarta;
        if (cardType == null || !filters.cardTypes.contains(cardType)) {
           return false;
        }
      }
      if (filters.attributes.isNotEmpty) {
        final attribute = card.atributo;
        if (attribute == null || !filters.attributes.contains(attribute)) {
          return false;
        }
      }
      if (filters.monsterTypes.isNotEmpty) {
        final monsterType = card.tipo;
        if (monsterType == null || !filters.monsterTypes.contains(monsterType)) {
           return false;
        }
      }
      if (filters.spellTrapIcons.isNotEmpty) {
        final classification = card.clasificacion;
        if (classification == null || !filters.spellTrapIcons.contains(classification)) {
           return false;
        }
      }
      if (filters.subtypes.isNotEmpty && card.subtipo != null) {
        final hasMatchingSubtype = card.subtipo!.any((cardSubtype) =>
            filters.subtypes.contains(cardSubtype));
        if (!hasMatchingSubtype) return false;
      }
      if (filters.minAtk?.isNotEmpty == true) {
        final minAtk = int.tryParse(filters.minAtk!);
        if (minAtk != null) {
          final cardAtk = card.atk == '?' ? -1 : (int.tryParse(card.atk ?? '-1') ?? -1);
          if (cardAtk < minAtk) {
            return false;
          }
        }
      }
      if (filters.minDef?.isNotEmpty == true) {
        final minDef = int.tryParse(filters.minDef!);
        if (minDef != null) {
          final cardDef = card.def == '?' ? -1 : (int.tryParse(card.def ?? '-1') ?? -1);
          if (cardDef < minDef) {
            return false;
          }
        }
      }
      return true;
    }).toList();

    // --- ⬇️ 2. SORTING LOGIC MODIFIED ⬇️ ---
    filteredCards.sort((a, b) {
      final Card cardA = a.cardDetails;
      final Card cardB = b.cardDetails;
      int comparison = 0;

      // --- Primary Sort Logic (Monster vs Non-Monster) ---
      // Apply ONLY when sorting by ATK, DEF, Level, Rank, Link, or Pendulum
      bool sortByMonsterStat = sortBy == SortBy.atk || sortBy == SortBy.def || sortBy == SortBy.level || sortBy == SortBy.rank || sortBy == SortBy.link || sortBy == SortBy.pendulum;
      if (sortByMonsterStat) {
        // Sistema de pesos mejorado: cada tipo arriba cuando se ordene por su estadística
        int getWeight(Card card) {
          final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
          final tipoLower = card.tipo?.toLowerCase() ?? '';
          final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();

          // Detectar tipos especiales
          final isLink = marcoLower.contains('link') || tipoLower.contains('link') || subtypesLower.contains('link');
          final isXyz = marcoLower.contains('xyz') || tipoLower.contains('xyz') || subtypesLower.contains('xyz');
          final isPendulum = marcoLower.contains('pendulum') || tipoLower.contains('pendulum') || subtypesLower.contains('pendulum');

          // Prioridad: cada tipo arriba cuando se ordene por su estadística específica
          switch (sortBy) {
            case SortBy.link:
              if (isLink) return 0; // Links arriba cuando se ordene por link
              break;
            case SortBy.pendulum:
              if (isPendulum) return 0; // Péndulos arriba cuando se ordene por péndulo
              break;
            case SortBy.rank:
              if (isXyz) return 0; // Xyz arriba cuando se ordene por rango
              break;
            case SortBy.level:
              if (!isLink && !isXyz && !isPendulum && (marcoLower.contains('monster') || marcoLower.contains('monstruo'))) return 0; // Solo monstruos normales arriba
              break;
            default:
              break;
          }

          // Si no es el tipo específico que se está ordenando, usar jerarquía normal
          if (isLink || isXyz || isPendulum) return 1; // Tipos especiales en medio
          if (marcoLower.contains('monster') || marcoLower.contains('monstruo')) return 2; // Monstruos normales
          return 3; // Magias/Trampas abajo del todo
        }

        final int weightA = getWeight(cardA);
        final int weightB = getWeight(cardB);

        // PRIMERO: Ordenar por peso (tipo específico primero, luego otros)
        comparison = weightA.compareTo(weightB);

        // SEGUNDO: Si son del mismo peso, aplicar ordenación específica
        if (comparison == 0) {
          if (weightA <= 1) {
            // Tipos especiales o monstruos normales - ordenar por estadística específica
            switch (sortBy) {
              case SortBy.atk:
                final atkA = cardA.atk == '?' ? 0 : (int.tryParse(cardA.atk ?? '0') ?? 0);
                final atkB = cardB.atk == '?' ? 0 : (int.tryParse(cardB.atk ?? '0') ?? 0);
                comparison = atkA.compareTo(atkB);
                break;
              case SortBy.def:
                final defA = cardA.def == '?' ? 0 : (int.tryParse(cardA.def ?? '0') ?? 0);
                final defB = cardB.def == '?' ? 0 : (int.tryParse(cardB.def ?? '0') ?? 0);
                comparison = defA.compareTo(defB);
                break;
              case SortBy.level:
                // Solo ordenar monstruos normales por nivel
                comparison = (cardA.nivelRankLink ?? 0).compareTo(cardB.nivelRankLink ?? 0);
                break;
              case SortBy.rank:
                // Solo ordenar Xyz por rango
                comparison = (cardA.nivelRankLink ?? 0).compareTo(cardB.nivelRankLink ?? 0);
                break;
              case SortBy.link:
                comparison = (cardA.ratioEnlace ?? 0).compareTo(cardB.ratioEnlace ?? 0);
                break;
              case SortBy.pendulum:
                comparison = (cardA.escalaPendulo ?? 0).compareTo(cardB.escalaPendulo ?? 0);
                break;
              default:
                comparison = 0;
                break;
            }
          } else {
            // Magias/trampas - ordenar por nombre
            comparison = (cardA.nombre ?? '').compareTo(cardB.nombre ?? '');
          }

          // Aplicar dirección solo a la ordenación específica, no al peso
          if (sortDirection == SortDirection.desc) {
            comparison = comparison * -1;
          }
        }
      } else {
        // Para otros tipos de ordenación (nombre, tipo de carta), usar la lógica normal
        switch (sortBy) {
          case SortBy.name:
            comparison = (cardA.nombre ?? '').compareTo(cardB.nombre ?? '');
            break;
          case SortBy.cardType:
            final valA = _getCardSortValue(cardA);
            final valB = _getCardSortValue(cardB);
            comparison = valA.compareTo(valB);
            break;
          default:
            comparison = 0;
            break;
        }

        // Aplicar dirección a la ordenación normal
        if (sortDirection == SortDirection.desc) {
          comparison = comparison * -1;
        }
      }

      // Apply direction to the final comparison result
      return comparison;
    });
    // --- ⬆️ END OF SORTING MODIFICATION ⬆️ ---

    return filteredCards;
  }

  /// Calculates the number of active filters (excluding search).
  int _getActiveFiltersCount(CardFiltersViewModel vm) {
    final f = vm.filters;
    return f.cardTypes.length +
        f.attributes.length +
        f.monsterTypes.length +
        f.subtypes.length +
        f.spellTrapIcons.length +
        ((f.minAtk?.isNotEmpty ?? false) ? 1 : 0) +
        ((f.minDef?.isNotEmpty ?? false) ? 1 : 0);
  }

  /// Shows the sorting options dialog.
  void _showSortDialog(BuildContext context, CardFiltersViewModel vm) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> sortOptions = [
      {'value': SortBy.name, 'label': 'Nombre', 'icon': Icons.sort_by_alpha, 'color': AppColors.primary},
      {'value': SortBy.atk, 'label': 'Ataque', 'icon': Icons.flash_on, 'color': Colors.orangeAccent},
      {'value': SortBy.def, 'label': 'Defensa', 'icon': Icons.shield, 'color': Colors.cyan},
      {'value': SortBy.level, 'label': 'Nivel', 'icon': Icons.star, 'color': Colors.yellowAccent},
      {'value': SortBy.rank, 'label': 'Rango (Xyz)', 'icon': Icons.diamond, 'color': Colors.black},
      {'value': SortBy.link, 'label': 'Link (Ratio)', 'icon': Icons.link, 'color': const Color(0xFF0077CC)},
      {'value': SortBy.pendulum, 'label': 'Escala Péndulo', 'icon': Icons.balance, 'color': Colors.purpleAccent},
      {'value': SortBy.cardType, 'label': 'Tipo de Carta', 'icon': Icons.style, 'color': Colors.grey},
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor ?? AppColors.surface,
        shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.lg)),
        title: Text('Ordenar por', style: theme.dialogTheme.titleTextStyle),
        contentPadding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sortOptions.map((option) {
              final sortByValue = option['value'] as SortBy;
              final isSelected = vm.sortBy == sortByValue;
              return ListTile(
                leading: Icon(option['icon'] as IconData, color: option['color'] as Color),
                title: Text(option['label'] as String, style: theme.textTheme.bodyLarge),
                trailing: isSelected
                  ? Icon(
                      vm.sortDirection == SortDirection.asc ? Icons.arrow_upward : Icons.arrow_downward,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
                onTap: () {
                  vm.setSort(sortByValue);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text('Cerrar', style: TextStyle(color: AppColors.primary)),
           ),
         ],
      ),
    );
  }

  /// Shows the filters dialog.
  void _showFilterDialog(BuildContext context, CardFiltersViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => FiltersDialog(viewModel: vm),
    );
  }
}