import 'package:flutter/material.dart' hide Card; // Evita conflicto
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Añadir Lucide icons

// --- Imports necesarios ---
import 'package:yugioh_scanner/shared/widgets/card_detail_panel.dart';
// import 'package:yugioh_scanner/shared/widgets/collection_toolbar.dart'; // No se usa aquí
import 'package:yugioh_scanner/shared/widgets/filters_dialog.dart';
import '../core/theme/app_theme.dart';
import '../services/supabase_service.dart'; // Importado por si ViewModel lo necesita
import '../view_models/processed_cards_view_model.dart';
import '../view_models/card_filters_view_model.dart';
import '../models/card_filters.dart';
import '../models/card_model.dart'; // Importa tu clase 'Card'

class NewCardsListScreen extends StatefulWidget {
  final String jobId;

  const NewCardsListScreen({super.key, required this.jobId});

  @override
  State<NewCardsListScreen> createState() => _NewCardsListScreenState();
}

class _NewCardsListScreenState extends State<NewCardsListScreen> {
  // Ya no se necesita el search controller aquí
  // final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeViewModel());
  }

   @override
  void dispose() {
    // _searchController.dispose(); // Ya no existe
    super.dispose();
  }

  void _initializeViewModel() async {
    try {
      final vm = Provider.of<ProcessedCardsViewModel>(context, listen: false);
      final supabase = Provider.of<SupabaseService>(context, listen: false);
      vm.initialize(supabase); // Asume que ViewModel usa el servicio
      await vm.fetchCardsByJobId(widget.jobId);
    } catch (e) {
      debugPrint('❌ Error inicializando NewCardsListScreen: $e');
      // Considera mostrar un mensaje de error al usuario aquí si vm.errorMessage no se actualiza
       // ... dentro de catch (e) { ...
     if (mounted) {
       // Asigna directamente a la propiedad errorMessage y notifica
       final vm = Provider.of<ProcessedCardsViewModel>(context, listen: false);
       vm.errorMessage = 'No se pudieron cargar las cartas procesadas.';
       // ¡IMPORTANTE! Asegúrate de que tu ViewModel llame a notifyListeners()
       // cuando se cambie errorMessage. Si no, añade vm.notifyListeners(); aquí.
     }
// ...
    }
  }

  // --- HELPER DE ORDENACIÓN ---
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
  // --- HELPER PARA CONSTRUIR TEXTO DE ESTADO ---
  String _buildStatusText(int validCards, int totalCards, ProcessedCardsViewModel processedVM) {
    // Calcular cartas fallidas: cartas que no tienen nombre (independientemente de filtros)
    final failedCards = processedVM.cards.where((card) => card.nombre == null || card.nombre!.isEmpty).length;

    if (failedCards == 0) {
      return 'Cartas procesadas ($validCards/$totalCards)';
    } else {
      return 'Cartas procesadas ($validCards/$totalCards), cartas fallidas ($failedCards)';
    }
  }
  // --- FIN HELPER ---

  // Helper para obtener el texto del tipo de ordenación
  String _getSortLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.name: return 'Nombre';
      case SortBy.atk: return 'Ataque';
      case SortBy.def: return 'Defensa';
      case SortBy.level: return 'Nivel';
      case SortBy.rank: return 'Rango (Xyz)';
      case SortBy.link: return 'Link (Ratio)';
      case SortBy.pendulum: return 'Escala Péndulo';
      case SortBy.cardType: return 'Tipo de Carta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Usa el color del tema
      body: SafeArea(
        child: ChangeNotifierProvider(
          create: (_) => CardFiltersViewModel(),
          child: Consumer2<ProcessedCardsViewModel, CardFiltersViewModel>(
            builder: (context, processedVM, filterVM, child) {

              // Aplica filtros y ordenación a las cartas del ProcessedCardsViewModel
              final processedCards = _applyFilters(processedVM, filterVM);

              if (processedVM.isLoading) {
                 return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Cargando cartas procesadas...',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              if (processedVM.errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Error al cargar resultados',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          processedVM.errorMessage!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                         const SizedBox(height: AppSpacing.lg),
                         ElevatedButton.icon( // Botón para reintentar
                           icon: const Icon(Icons.refresh),
                           label: const Text('Reintentar'),
                           onPressed: _initializeViewModel,
                         )
                      ],
                    ),
                  ),
                );
              }

              if (processedVM.cards.isEmpty) { // Comprueba sobre las originales
                 return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No se procesaron cartas válidas', // Mensaje más claro
                        style: textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                       const SizedBox(height: AppSpacing.lg),
                       ElevatedButton.icon( // Botón para volver
                         icon: const Icon(Icons.arrow_back),
                         label: const Text('Volver'),
                         onPressed: () => Navigator.of(context).pop(),
                       )
                    ],
                  ),
                );
              }

              // --- Estructura principal con Toolbar restaurada ---
              return Row(
                children: [
                  CardDetailPanel(cardDetails: processedVM.selectedCard),
                  Container(width: 1, color: theme.dividerColor),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        // --- Barra superior Original ---
                        Container(
                          color: theme.colorScheme.surface,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                color: AppColors.textSecondary,
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: 'Volver',
                                splashRadius: 20,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(right: AppSpacing.sm),
                              ),
                              Expanded(
                                child: Text(
                                  // Muestra contador procesadas válidas/totales y fallidas si las hay
                                  _buildStatusText(processedCards.length, processedVM.cards.length, processedVM),
                                  style: textTheme.bodyMedium?.copyWith(fontSize: 14), // Texto más pequeño
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Botón Ordenar
                              Tooltip(
                                message: 'Ordenar por: ${_getSortLabel(filterVM.sortBy)} (${filterVM.sortDirection == SortDirection.asc ? 'Ascendente' : 'Descendente'})',
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                  ),
                                  icon: Icon(
                                    filterVM.sortDirection == SortDirection.asc ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    _getSortLabel(filterVM.sortBy),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  onPressed: () => _showSortDialog(context, filterVM),
                                ),
                              ),
                              // Botón Filtrar
                               Tooltip(
                                message: 'Filtros (${_getActiveFiltersCount(filterVM) > 0 ? '${_getActiveFiltersCount(filterVM)} activos' : 'Ninguno'})',
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.filter),
                                      color: _getActiveFiltersCount(filterVM) > 0 ? AppColors.primary : AppColors.textSecondary,
                                      iconSize: 20,
                                      onPressed: () => _showFilterDialog(context, filterVM),
                                      splashRadius: 20,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                    ),
                                    if (_getActiveFiltersCount(filterVM) > 0)
                                      Positioned(
                                        top: -4,
                                        right: -2,
                                        child: CircleAvatar(
                                          radius: 9,
                                          backgroundColor: AppColors.error,
                                          child: Text(
                                            _getActiveFiltersCount(filterVM).toString(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // --- Fin Barra Superior ---
                        Expanded(
                          child: processedCards.isEmpty // Comprueba sobre las filtradas
                              ? Center(
                                  child: Text(
                                    'No se encontraron cartas con esos filtros',
                                    style: textTheme.bodyMedium,
                                  ),
                                )
                              : AnimationLimiter(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: AppSpacing.sm,
                                      mainAxisSpacing: AppSpacing.sm,
                                      childAspectRatio: 0.70,
                                    ),
                                    itemCount: processedCards.length,
                                    itemBuilder: (context, index) {
                                      final card = processedCards[index];
                                      final bool isSelected = processedVM.selectedCard?.idCarta == card.idCarta;

                                      return AnimationConfiguration.staggeredGrid(
                                        position: index,
                                        duration: const Duration(milliseconds: 375),
                                        columnCount: 6,
                                        child: ScaleAnimation(
                                          child: FadeInAnimation(
                                            child: GestureDetector(
                                              onTap: () => processedVM.selectCard(card),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                                                  border: Border.all(
                                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                                    width: 2.5,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                                                  child: CachedNetworkImage(
                                                    imageUrl: card.imagen ?? '',
                                                    fit: BoxFit.cover,
                                                    placeholder: (c, u) => Container(color: theme.colorScheme.surface),
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
              );
            },
          ),
        ),
      ),
    );
  }


  // --- FUNCIONES DE FILTRADO Y ORDENACIÓN (Adaptadas para List<Card>) ---
  List<Card> _applyFilters( // Devuelve List<Card>
      ProcessedCardsViewModel processedVM, CardFiltersViewModel filterVM) {
    final filters = filterVM.filters;
    final sortBy = filterVM.sortBy;
    final sortDirection = filterVM.sortDirection;

    // 1. Filtrar
    var filteredCards = processedVM.cards.where((card) { // Itera sobre List<Card>
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

    // 2. Ordenar
    filteredCards.sort((cardA, cardB) { // Compara Card directamente
      int comparison = 0;
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

      return comparison;
    });
    return filteredCards;
  }

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

  void _showFilterDialog(BuildContext context, CardFiltersViewModel vm) {
     showDialog(context: context, builder: (_) => FiltersDialog(viewModel: vm),);
  }
} // <-- FIN DE LA CLASE