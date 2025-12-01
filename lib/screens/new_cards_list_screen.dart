import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:yugioh_scanner/shared/widgets/card_detail_panel.dart';
// import 'package:yugioh_scanner/shared/widgets/collection_toolbar.dart'; // ELIMINADO
import 'package:yugioh_scanner/shared/widgets/filters_dialog.dart';
import 'package:yugioh_scanner/shared/widgets/flippable_card.dart';

import '../core/theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../view_models/processed_cards_view_model.dart';
import '../view_models/card_filters_view_model.dart';
import '../models/card_filters.dart';
import '../models/card_model.dart';
import '../models/user_card_model.dart';

class NewCardsListScreen extends StatefulWidget {
  final String jobId;

  const NewCardsListScreen({super.key, required this.jobId});

  @override
  State<NewCardsListScreen> createState() => _NewCardsListScreenState();
}

class _NewCardsListScreenState extends State<NewCardsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Variable para mantener el Stream estable y evitar parpadeos
  late Stream<List<Card>> _cardsStream;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicialización segura antes de pintar
    if (!_isInit) {
      final vm = Provider.of<ProcessedCardsViewModel>(context, listen: false);
      final supabase = Provider.of<SupabaseService>(context, listen: false);
      
      vm.initialize(supabase);
      // Guardamos el Stream aquí para que no se recargue al hacer setState
      _cardsStream = vm.getProcessedCardsStream(widget.jobId);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- HELPER: LIMPIEZA DE DATOS ---
  Card _sanitizeCard(Card original) {
    bool isValid(String? v) => v != null && v.toLowerCase() != 'null' && v.trim().isNotEmpty;

    return Card(
      idCarta: original.idCarta,
      cantidad: original.cantidad,
      nombre: original.nombre,
      imagen: original.imagen,
      marcoCarta: isValid(original.marcoCarta) ? original.marcoCarta : null,
      tipo: isValid(original.tipo) ? original.tipo : null,
      atributo: isValid(original.atributo) ? original.atributo : null,
      clasificacion: isValid(original.clasificacion) ? original.clasificacion : null,
      iconoCarta: isValid(original.iconoCarta) ? original.iconoCarta : null,
      setExpansion: isValid(original.setExpansion) ? original.setExpansion : null,
      subtipo: original.subtipo?.where((s) => isValid(s)).toList(),
      rareza: original.rareza?.where((s) => isValid(s)).toList(),
      atk: isValid(original.atk) ? original.atk : null,
      def: isValid(original.def) ? original.def : null,
      nivelRankLink: original.nivelRankLink,
      ratioEnlace: original.ratioEnlace,
      escalaPendulo: original.escalaPendulo,
      descripcion: original.descripcion,
    );
  }

  // --- 1. HELPER: VALOR DE ORDENACIÓN ---
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

    String? getDetectedMonsterType() {
      final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
      final tipoLower = card.tipo?.toLowerCase() ?? '';
      final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();

      if (marcoLower.contains('link') || tipoLower.contains('link') || subtypesLower.contains('link')) return 'Link';
      if (marcoLower.contains('xyz') || tipoLower.contains('xyz') || subtypesLower.contains('xyz')) return 'Xyz';
      if (marcoLower.contains('pendulum') || tipoLower.contains('pendulum') || subtypesLower.contains('pendulum')) return 'Pendulum';
      if (marcoLower.contains('fusion') || tipoLower.contains('fusion') || subtypesLower.contains('fusion')) return 'Fusion';
      if (marcoLower.contains('synchro') || tipoLower.contains('synchro') || subtypesLower.contains('synchro')) return 'Synchro';
      if (marcoLower.contains('ritual') || tipoLower.contains('ritual') || subtypesLower.contains('ritual')) return 'Ritual';

      if (card.subtipo?.isNotEmpty == true) return card.subtipo![0];
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

  // --- 2. HELPER: TEXTO DE ESTADO ---
  String _buildStatusText(int validCards, int totalCards, List<Card> allCards) {
    final failedCards = allCards.where((card) => card.nombre == null || card.nombre!.contains('⚠️')).length;
    if (failedCards == 0) {
      return 'Cartas procesadas ($validCards/$totalCards)';
    } else {
      return 'Cartas procesadas ($validCards/$totalCards), errores ($failedCards)';
    }
  }

  // --- 3. HELPER: ETIQUETA DE ORDEN ---
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

  // --- 4. LÓGICA DE FILTRADO Y ORDENACIÓN ---
  List<Card> _applyFilters(List<Card> rawCards, CardFiltersViewModel filterVM) {
    final filters = filterVM.filters;
    final sortBy = filterVM.sortBy;
    final sortDirection = filterVM.sortDirection;

    // A. FILTRADO
    var filteredCards = rawCards.where((card) {
      final query = filters.search.toLowerCase();
      if (query.isNotEmpty) {
        final matchesSearch = (card.nombre?.toLowerCase().contains(query) ?? false) ||
            card.idCarta.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }
      if (filters.cardTypes.isNotEmpty) {
        if (card.marcoCarta == null || !filters.cardTypes.contains(card.marcoCarta)) return false;
      }
      if (filters.attributes.isNotEmpty) {
        if (card.atributo == null || !filters.attributes.contains(card.atributo)) return false;
      }
      // ... resto de filtros
      if (filters.monsterTypes.isNotEmpty) {
        if (card.tipo == null || !filters.monsterTypes.contains(card.tipo)) return false;
      }
      if (filters.spellTrapIcons.isNotEmpty) {
        if (card.clasificacion == null || !filters.spellTrapIcons.contains(card.clasificacion)) return false;
      }
      if (filters.subtypes.isNotEmpty && card.subtipo != null) {
        if (!card.subtipo!.any((s) => filters.subtypes.contains(s))) return false;
      }
      if (filters.minAtk?.isNotEmpty == true) {
        final minAtk = int.tryParse(filters.minAtk!);
        if (minAtk != null) {
          final cardAtk = int.tryParse(card.atk ?? '-1') ?? -1;
          if (cardAtk < minAtk) return false;
        }
      }
      if (filters.minDef?.isNotEmpty == true) {
        final minDef = int.tryParse(filters.minDef!);
        if (minDef != null) {
          final cardDef = int.tryParse(card.def ?? '-1') ?? -1;
          if (cardDef < minDef) return false;
        }
      }
      return true;
    }).toList();

    // B. ORDENACIÓN
    filteredCards.sort((cardA, cardB) {
      int comparison = 0;
      bool sortByMonsterStat = sortBy == SortBy.atk || sortBy == SortBy.def || sortBy == SortBy.level || sortBy == SortBy.rank || sortBy == SortBy.link || sortBy == SortBy.pendulum;

      if (sortByMonsterStat) {
        // Pesos de tipos
        int getWeight(Card card) {
          final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
          final tipoLower = card.tipo?.toLowerCase() ?? '';
          final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();

          final isLink = marcoLower.contains('link') || tipoLower.contains('link') || subtypesLower.contains('link');
          final isXyz = marcoLower.contains('xyz') || tipoLower.contains('xyz') || subtypesLower.contains('xyz');
          final isPendulum = marcoLower.contains('pendulum') || tipoLower.contains('pendulum') || subtypesLower.contains('pendulum');

          switch (sortBy) {
            case SortBy.link: if (isLink) return 0; break;
            case SortBy.pendulum: if (isPendulum) return 0; break;
            case SortBy.rank: if (isXyz) return 0; break;
            case SortBy.level: if (!isLink && !isXyz && !isPendulum && (marcoLower.contains('monster') || marcoLower.contains('monstruo'))) return 0; break;
            default: break;
          }

          if (isLink || isXyz || isPendulum) return 1;
          if (marcoLower.contains('monster') || marcoLower.contains('monstruo')) return 2;
          return 3;
        }

        final int weightA = getWeight(cardA);
        final int weightB = getWeight(cardB);
        comparison = weightA.compareTo(weightB);

        if (comparison == 0) {
          if (weightA <= 1) {
            switch (sortBy) {
              case SortBy.atk:
                final atkA = int.tryParse(cardA.atk ?? '0') ?? 0;
                final atkB = int.tryParse(cardB.atk ?? '0') ?? 0;
                comparison = atkA.compareTo(atkB);
                break;
              case SortBy.def:
                final defA = int.tryParse(cardA.def ?? '0') ?? 0;
                final defB = int.tryParse(cardB.def ?? '0') ?? 0;
                comparison = defA.compareTo(defB);
                break;
              case SortBy.level:
                comparison = (cardA.nivelRankLink ?? 0).compareTo(cardB.nivelRankLink ?? 0);
                break;
              case SortBy.rank:
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
            comparison = (cardA.nombre ?? '').compareTo(cardB.nombre ?? '');
          }
          if (sortDirection == SortDirection.desc) comparison *= -1;
        }
      } else {
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
        if (sortDirection == SortDirection.desc) comparison *= -1;
      }

      return comparison;
    });

    return filteredCards;
  }

  // --- 5. UTILS ---
  int _getActiveFiltersCount(CardFiltersViewModel vm) {
    final f = vm.filters;
    return f.cardTypes.length + f.attributes.length + f.monsterTypes.length +
        f.subtypes.length + f.spellTrapIcons.length +
        ((f.minAtk?.isNotEmpty ?? false) ? 1 : 0) + ((f.minDef?.isNotEmpty ?? false) ? 1 : 0);
  }

  void _showSortDialog(BuildContext context, CardFiltersViewModel vm) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> sortOptions = [
      {'value': SortBy.name, 'label': 'Nombre', 'icon': LucideIcons.type, 'color': AppColors.primary},
      {'value': SortBy.atk, 'label': 'Ataque', 'icon': LucideIcons.sword, 'color': Colors.orangeAccent},
      {'value': SortBy.def, 'label': 'Defensa', 'icon': LucideIcons.shield, 'color': Colors.cyan},
      {'value': SortBy.level, 'label': 'Nivel', 'icon': LucideIcons.star, 'color': Colors.yellowAccent},
      {'value': SortBy.rank, 'label': 'Rango (Xyz)', 'icon': LucideIcons.gem, 'color': Colors.black},
      {'value': SortBy.link, 'label': 'Link (Ratio)', 'icon': LucideIcons.link, 'color': const Color(0xFF0077CC)},
      {'value': SortBy.pendulum, 'label': 'Escala Péndulo', 'icon': LucideIcons.scale, 'color': Colors.purpleAccent},
      {'value': SortBy.cardType, 'label': 'Tipo de Carta', 'icon': LucideIcons.layers, 'color': Colors.grey},
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
                leading: Icon(option['icon'], color: option['color']),
                title: Text(option['label']),
                trailing: isSelected ? Icon(LucideIcons.check, color: AppColors.primary) : null,
                onTap: () {
                  vm.setSort(option['value']);
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
     showDialog(context: context, builder: (_) => FiltersDialog(viewModel: vm));
  }

  // --- INTERFAZ PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ChangeNotifierProvider(
          create: (_) => CardFiltersViewModel(),
          child: Consumer2<ProcessedCardsViewModel, CardFiltersViewModel>(
            builder: (context, processedVM, filterVM, child) {
              
              // 🔥 USAMOS EL STREAM GUARDADO
              return StreamBuilder<List<Card>>(
                stream: _cardsStream, 
                builder: (context, snapshot) {
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppSpacing.md),
                          Text('Cargando...', style: textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                     return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allCards = snapshot.data ?? [];
                  final processedCards = _applyFilters(allCards, filterVM);

                  // Auto-selección
                  if (processedVM.selectedCard == null && processedCards.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (processedVM.selectedCard == null) {
                            processedVM.selectCard(processedCards.first);
                         }
                      });
                  }
                  
                  // 🔥 WRAPPER USER CARD + SANITIZACIÓN
                  UserCard? selectedUserCard;
                  if (processedVM.selectedCard != null) {
                      // 1. Limpiamos la carta de valores "null" molestos
                      final cleanCard = _sanitizeCard(processedVM.selectedCard!);
                      
                      // 2. Creamos el objeto para el panel
                      selectedUserCard = UserCard(
                        userCardId: 'preview', 
                        quantity: cleanCard.cantidad, 
                        condition: 'Mint', 
                        acquiredDate: DateTime.now(),
                        cardDetails: cleanCard 
                      );
                  }

                  if (allCards.isEmpty) {
                     return Center(child: Text("Esperando datos...", style: textTheme.bodyMedium));
                  }

                  return Row(
                    children: [
                      // --- PANEL IZQUIERDO ---
                      selectedUserCard != null 
                          ? CardDetailPanel(userCard: selectedUserCard, isUserCollection: false)
                          : Container(
                              width: 300, color: theme.cardColor,
                              child: Center(child: Text('Selecciona una carta', style: textTheme.bodyMedium)),
                            ),
                      Container(width: 1, color: theme.dividerColor),
                      
                      // --- PANEL DERECHO ---
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            
                            // --- BARRA SUPERIOR MANUAL (Sin CollectionToolbar) ---
                            Container(
                              color: theme.colorScheme.surface,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              child: Row(
                                children: [
                                  // Botón Volver
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    color: AppColors.textSecondary,
                                    onPressed: () => Navigator.of(context).pop(),
                                    tooltip: 'Volver',
                                  ),
                                  // Texto Estado
                                  Expanded(
                                    child: Text(
                                      _buildStatusText(processedCards.length, allCards.length, allCards),
                                      style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Botón Ordenar
                                  Tooltip(
                                    message: 'Ordenar',
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
                                    message: 'Filtros',
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.filter),
                                          color: _getActiveFiltersCount(filterVM) > 0 ? AppColors.primary : AppColors.textSecondary,
                                          iconSize: 20,
                                          onPressed: () => _showFilterDialog(context, filterVM),
                                        ),
                                        if (_getActiveFiltersCount(filterVM) > 0)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: CircleAvatar(
                                              radius: 6,
                                              backgroundColor: AppColors.error,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // --- GRID DE CARTAS ---
                            Expanded(
                              child: processedCards.isEmpty
                                  ? Center(child: Text('No hay cartas con estos filtros'))
                                  : AnimationLimiter(
                                      child: GridView.builder(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 6, childAspectRatio: 0.70,
                                          crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm,
                                        ),
                                        itemCount: processedCards.length,
                                        itemBuilder: (context, index) {
                                          final card = processedCards[index];
                                          final bool isSelected = (processedVM.selectedCard != null) 
                                              ? processedVM.isCardSelected(card) 
                                              : (index == 0);
                                          final isError = card.nombre?.contains('⚠️') ?? false;

                                          return AnimationConfiguration.staggeredGrid(
                                            position: index, duration: const Duration(milliseconds: 375),
                                            columnCount: 6,
                                            child: ScaleAnimation(
                                              child: FadeInAnimation(
                                                child: GestureDetector(
                                                  onTap: () => processedVM.selectCard(card),
                                                  child: Stack(
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                                                          border: Border.all(
                                                            color: isError ? Colors.red : (isSelected ? AppColors.primary : Colors.transparent),
                                                            width: 2.5,
                                                          ),
                                                        ),
                                                        child: FlippableCard(
                                                          imageUrl: card.imagen ?? '',
                                                          cardBackAsset: 'assets/back-card.png',
                                                          fit: BoxFit.cover,
                                                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                                                          cardData: card,
                                                        ),
                                                      ),
                                                      if (card.cantidad > 1)
                                                        Positioned(
                                                          bottom: 4, right: 4,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.yellow,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: Colors.black)
                                                            ),
                                                            child: Text('x${card.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                                                          ),
                                                        ),
                                                       if (isError)
                                                        Positioned(
                                                          top: 4, right: 4,
                                                          child: Icon(LucideIcons.alertTriangle, color: Colors.red, size: 18),
                                                        )
                                                    ],
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
              );
            },
          ),
        ),
      ),
    );
  }
}