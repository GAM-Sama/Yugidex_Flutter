import 'package:flutter/material.dart' hide Card;
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- Imports de tu proyecto ---
import '../services/supabase_service.dart';
import '../view_models/deck_editor_view_model.dart';
import '../view_models/card_filters_view_model.dart';
import '../models/card_model.dart';
import '../models/card_filters.dart'; // Para SortBy
import '../core/theme/app_theme.dart';

// Widgets reutilizables
import 'package:yugioh_scanner/shared/widgets/filters_dialog.dart';
import 'package:yugioh_scanner/shared/widgets/flippable_card.dart'; // 

class DeckEditorScreen extends StatefulWidget {
  final String? deckId;
  final String? deckName;

  const DeckEditorScreen({super.key, this.deckId, this.deckName});

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  final TextEditingController _searchController = TextEditingController();
  
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

  // --- LÓGICA DE FILTRADO Y ORDENACIÓN (CATÁLOGO) ---
  List<Card> _applyFilters(List<Card> rawCards, CardFiltersViewModel filterVM) {
    final filters = filterVM.filters;
    final sortBy = filterVM.sortBy;
    final sortDirection = filterVM.sortDirection;
    
    // 1. Filtrado
    var filteredCards = rawCards.where((card) {
      // Nota: La búsqueda de texto principal se hace en DB desde el DeckEditorViewModel,
      // pero aquí aplicamos los filtros de atributos/tipos sobre lo descargado.
      
      if (filters.cardTypes.isNotEmpty) {
        if (card.marcoCarta == null || !filters.cardTypes.contains(card.marcoCarta)) return false;
      }
      if (filters.attributes.isNotEmpty) {
        if (card.atributo == null || !filters.attributes.contains(card.atributo)) return false;
      }
      if (filters.monsterTypes.isNotEmpty) {
        if (card.tipo == null || !filters.monsterTypes.contains(card.tipo)) return false;
      }
      // ... (Añadir resto de filtros si es necesario)
      return true;
    }).toList();

    // 2. Ordenación
    filteredCards.sort((cardA, cardB) {
      int comparison = 0;
      switch (sortBy) {
        case SortBy.name:
          comparison = (cardA.nombre ?? '').compareTo(cardB.nombre ?? '');
          break;
        case SortBy.atk:
           final atkA = int.tryParse(cardA.atk ?? '0') ?? 0;
           final atkB = int.tryParse(cardB.atk ?? '0') ?? 0;
           comparison = atkA.compareTo(atkB);
           break;
        // ... (Resto de casos simples)
        default:
           comparison = 0;
      }
      if (sortDirection == SortDirection.desc) comparison *= -1;
      return comparison;
    });

    return filteredCards;
  }
  
  // --- UTILS ---
  int _getActiveFiltersCount(CardFiltersViewModel vm) {
    final f = vm.filters;
    return f.cardTypes.length + f.attributes.length + f.monsterTypes.length + f.spellTrapIcons.length + f.subtypes.length; 
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final viewModel = DeckEditorViewModel(
              Provider.of<SupabaseService>(context, listen: false)
            );
            
            // Cargar deck existente o crear nuevo
            if (widget.deckId != null) {
              viewModel.loadData(widget.deckId!);
            } else {
              viewModel.createNewDeck(widget.deckName ?? 'Mi Deck');
            }
            
            return viewModel;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => CardFiltersViewModel(),
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          // Forzar actualización al volver con botón físico
          Navigator.of(context).pop('reload');
          return false;
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Usa tema
          body: SafeArea(
            child: Consumer2<DeckEditorViewModel, CardFiltersViewModel>(
              builder: (context, deckVM, filterVM, child) {
                if (deckVM.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Aplicamos filtros al catálogo de la derecha
                final catalogCards = _applyFilters(deckVM.collection, filterVM);

                return Column(
                  children: [
                    // --- 1. CABECERA SUPERIOR ---
                    _buildTopBar(context, deckVM),
                    
                    Divider(height: 1, color: Theme.of(context).dividerColor),

                    // --- 2. CUERPO DIVIDIDO ---
                    Expanded(
                    child: Row(
                      children: [
                        // === IZQUIERDA: EL DECK ===
                        Expanded(
                          flex: 6,
                          child: Container(
                            color: Theme.of(context).colorScheme.surface, // Usa tema
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 80),
                              child: Column(
                                children: [
                                  _buildDeckSection(context, deckVM, "Main Deck", deckVM.mainCount, 40, deckVM.mainDeck, isExtra: false, isSide: false),
                                  _buildDeckSection(context, deckVM, "Extra Deck", deckVM.extraCount, 15, deckVM.extraDeck, isExtra: true, isSide: false),
                                  _buildDeckSection(context, deckVM, "Side Deck", deckVM.sideCount, 15, deckVM.sideDeck, isExtra: false, isSide: true),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Container(width: 1, color: Theme.of(context).dividerColor),

                        // === DERECHA: CATÁLOGO ===
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              // Barra de Herramientas del Catálogo
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.5), // Usa tema
                                child: Row(
                                  children: [
                                    // Buscador
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                                        decoration: InputDecoration(
                                          hintText: "Buscar carta...",
                                          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                          prefixIcon: Icon(LucideIcons.search, size: 18, color: Theme.of(context).iconTheme.color),
                                          suffixIcon: _searchController.text.isNotEmpty 
                                              ? IconButton(icon: Icon(Icons.clear, size: 18, color: Theme.of(context).iconTheme.color), onPressed: () { 
                                                  _searchController.clear(); 
                                                  deckVM.filterCollection(''); 
                                                }) 
                                              : null,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                          filled: true,
                                          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                                        ),
                                        onChanged: (val) => deckVM.filterCollection(val),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Botón Filtros
                                    IconButton(
                                      icon: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(LucideIcons.filter, size: 20, color: Theme.of(context).iconTheme.color),
                                          if (_getActiveFiltersCount(filterVM) > 0)
                                            const Positioned(top: -2, right: -2, child: CircleAvatar(radius: 4, backgroundColor: AppColors.error))
                                        ],
                                      ),
                                      tooltip: "Filtrar Catálogo",
                                      onPressed: () => showDialog(context: context, builder: (_) => FiltersDialog(viewModel: filterVM)),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    
                                    // Botón Ordenar (Simple toggle)
                                    IconButton(
                                      icon: Icon(
                                        filterVM.sortDirection == SortDirection.asc ? LucideIcons.arrowUp : LucideIcons.arrowDown, 
                                        size: 20, color: Theme.of(context).iconTheme.color
                                      ),
                                      tooltip: "Ordenar",
                                      onPressed: () {
                                        // Alternar ordenación simple
                                        if (filterVM.sortBy == SortBy.name) {
                                          filterVM.setSort(SortBy.atk);
                                        } else {
                                          filterVM.setSort(SortBy.name);
                                        }
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ],
                                ),
                              ),
                              
                              Divider(height: 1, color: Theme.of(context).dividerColor),

                              // Grid de Cartas
                              Expanded(
                                child: DragTarget<Card>(
                                  onWillAccept: (card) {
                                    // Solo aceptar cartas que están en los decks (no del catálogo)
                                    if (card == null) return false;
                                    
                                    // Verificar si la carta está en alguno de los decks
                                    bool isInMainDeck = deckVM.mainDeck.any((c) => c.idCarta == card.idCarta);
                                    bool isInExtraDeck = deckVM.extraDeck.any((c) => c.idCarta == card.idCarta);
                                    bool isInSideDeck = deckVM.sideDeck.any((c) => c.idCarta == card.idCarta);
                                    
                                    return isInMainDeck || isInExtraDeck || isInSideDeck;
                                  },
                                  onAccept: (card) {
                                    // Remover carta del deck
                                    deckVM.removeCardFromDeck(card.idCarta);
                                    
                                    // Mostrar feedback visual
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("${card.nombre} eliminada del deck"),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    final isDraggingOver = candidateData.isNotEmpty;
                                    
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: isDraggingOver 
                                          ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                                          : null,
                                        border: isDraggingOver
                                          ? Border.all(color: Theme.of(context).colorScheme.error, width: 2)
                                          : null,
                                      ),
                                      child: catalogCards.isEmpty
                                          ? Center(child: Text(
                                              isDraggingOver ? "Suelta aquí para eliminar" : "No se encontraron cartas", 
                                              style: TextStyle(
                                                color: isDraggingOver
                                                  ? Theme.of(context).colorScheme.error
                                                  : Theme.of(context).textTheme.bodyMedium?.color
                                              )
                                            ))
                                          : AnimationLimiter(
                                              child: GridView.builder(
                                                padding: const EdgeInsets.all(8),
                                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 6, 
                                                  childAspectRatio: 0.7,
                                                  crossAxisSpacing: 4,
                                                  mainAxisSpacing: 4,
                                                ),
                                                itemCount: catalogCards.length,
                                                itemBuilder: (context, index) {
                                                  final card = catalogCards[index];
                                                  final cleanCard = _sanitizeCard(card); // Limpiamos antes de pintar

                                                  return AnimationConfiguration.staggeredGrid(
                                                    position: index,
                                                    duration: const Duration(milliseconds: 200),
                                                    columnCount: 6,
                                                    child: ScaleAnimation(
                                                      child: FadeInAnimation(
                                                        child: LongPressDraggable<Card>(
                                                          data: cleanCard,
                                                          feedback: Material(
                                                            color: Colors.transparent,
                                                            child: Container(
                                                              width: 80,
                                                              height: 112,
                                                              child: FlippableCard(
                                                                imageUrl: cleanCard.imagen ?? '',
                                                                cardBackAsset: 'assets/back-card.png',
                                                                fit: BoxFit.cover,
                                                                borderRadius: BorderRadius.circular(4),
                                                                cardData: cleanCard,
                                                              ),
                                                            ),
                                                          ),
                                                          childWhenDragging: Container(
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.withOpacity(0.3),
                                                              borderRadius: BorderRadius.circular(4),
                                                              border: Border.all(color: Colors.grey, width: 2),
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        GestureDetector(
                                                          // Al tocar, abrimos el POPUP para añadir
                                                          onTap: () => _showCardOptions(context, deckVM, cleanCard),
                                                          // USAMOS FLIPPABLE CARD
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(4),
                                                              border: Border.all(
                                                                color: deckVM.isCardExhausted(cleanCard.idCarta)
                                                                    ? Colors.red.withOpacity(0.8)
                                                                    : deckVM.isCardLimitReached(cleanCard.idCarta)
                                                                        ? Colors.orange.withOpacity(0.8)
                                                                        : Colors.transparent,
                                                                width: 2,
                                                              ),
                                                            ),
                                                            child: Opacity(
                                                              opacity: deckVM.isCardExhausted(cleanCard.idCarta) ? 0.5 : 1.0,
                                                              child: FlippableCard(
                                                                imageUrl: cleanCard.imagen ?? '',
                                                                cardBackAsset: 'assets/back-card.png',
                                                                fit: BoxFit.cover,
                                                                borderRadius: BorderRadius.circular(4),
                                                                cardData: cleanCard,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        // Recuadro amarillo con cantidad poseída
                                                        if (card.cantidad > 1)
                                                          Positioned(
                                                            top: 4,
                                                            right: 4,
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: Colors.yellow,
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: Colors.black, width: 1),
                                                              ),
                                                              child: Text(
                                                                'x${card.cantidad}',
                                                                style: const TextStyle(
                                                                  color: Colors.black,
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        // Etiqueta de estado (agotado/limite alcanzado)
                                                        if (deckVM.isCardExhausted(cleanCard.idCarta) || deckVM.isCardLimitReached(cleanCard.idCarta))
                                                          Positioned(
                                                            bottom: 4,
                                                            left: 0,
                                                            right: 0,
                                                            child: Center(
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: deckVM.isCardExhausted(cleanCard.idCarta) 
                                                                      ? Colors.red 
                                                                      : Colors.red.shade800,
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(color: Colors.black, width: 1),
                                                                ),
                                                                child: Text(
                                                                  deckVM.getCardStatusText(cleanCard.idCarta),
                                                                  style: const TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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
      ),
    );
  }

  // --- WIDGETS UI ---

  Widget _buildTopBar(BuildContext context, DeckEditorViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8), // Usa tema
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context, 'reload'),
            tooltip: "Salir",
          ),
          const SizedBox(width: 12),
          // Nombre y Color con botones
          GestureDetector(
            onTap: () => _showRenameDialog(context, vm),
            child: Row(
              children: [
                 // Icono de borrar (primero)
                 GestureDetector(
                   onTap: () => _showClearDeckDialog(context, vm),
                   child: Icon(LucideIcons.trash2, size: 14, color: Theme.of(context).colorScheme.error),
                 ),
                 const SizedBox(width: 12), // Espacio para evitar clicks accidentales
                 // Icono de editar (lápiz)
                 Icon(LucideIcons.pencil, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                 const SizedBox(width: 8),
                 Icon(LucideIcons.sword, size: 18, color: Color(vm.deckColor)),
                 const SizedBox(width: 8),
                 Text(
                  vm.deckName.isEmpty ? 'Sin Nombre' : vm.deckName,
                  style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),
          
          // Selector Color
          GestureDetector(
            onTap: () => _showColorDialog(context, vm),
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(color: Color(vm.deckColor), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).dividerColor, width: 1)),
            ),
          ),
          const SizedBox(width: 16),
          
          // Botón Guardar
          IconButton(
            icon: Icon(vm.isDirty ? LucideIcons.save : LucideIcons.checkCircle, 
              color: vm.isDirty ? AppColors.warning : AppColors.success),
            tooltip: "Guardar Deck",
            onPressed: () {
               vm.saveDeck();
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text("Deck guardado", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                 backgroundColor: Theme.of(context).colorScheme.primary,
                 duration: const Duration(seconds: 1)
               ));
               // No salir de la pantalla, solo guardar
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeckSection(BuildContext context, DeckEditorViewModel vm, String title, int current, int max, List<Card> cards, {required bool isExtra, required bool isSide}) {
    final isFull = current > max;
    
    return DragTarget<Card>(
      onWillAccept: (card) {
        if (card == null) return false;
        
        // Verificar que puede añadir la carta
        if (!vm.canAddCard(card.idCarta)) return false;
        
        // Para Side Deck, aceptar cualquier carta hasta 15
        if (isSide) {
          return vm.sideCount < 15;
        }
        
        // Para Extra Deck, solo aceptar cartas compatibles
        if (isExtra) {
          final tipoLower = card.tipo?.toLowerCase() ?? '';
          final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
          final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();
          
          return tipoLower.contains('fusion') || tipoLower.contains('synchro') || 
                 tipoLower.contains('xyz') || tipoLower.contains('link') ||
                 marcoLower.contains('fusion') || marcoLower.contains('synchro') ||
                 marcoLower.contains('xyz') || marcoLower.contains('link') ||
                 subtypesLower.contains('fusion') || subtypesLower.contains('synchro') ||
                 subtypesLower.contains('xyz') || subtypesLower.contains('link');
        }
        
        // Para Main Deck, aceptar cualquier carta que no sea Extra Deck
        final tipoLower = card.tipo?.toLowerCase() ?? '';
        final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
        final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();
        
        bool isExtraCard = tipoLower.contains('fusion') || tipoLower.contains('synchro') || 
                           tipoLower.contains('xyz') || tipoLower.contains('link') ||
                           marcoLower.contains('fusion') || marcoLower.contains('synchro') ||
                           marcoLower.contains('xyz') || marcoLower.contains('link') ||
                           subtypesLower.contains('fusion') || subtypesLower.contains('synchro') ||
                           subtypesLower.contains('xyz') || subtypesLower.contains('link');
        
        return !isExtraCard && current < 40;
      },
      onAccept: (card) {
        vm.addCardToDeck(card, toSide: isSide);
        
        // Mostrar feedback visual
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSide ? "${card.nombre} añadido al Side Deck" : 
              isExtra ? "${card.nombre} añadido al Extra Deck" :
                       "${card.nombre} añadido al Main Deck"
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;
        
        return Container(
          decoration: BoxDecoration(
            color: isDraggingOver 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : null,
            border: isDraggingOver
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
          ),
          child: Column(
            children: [
              // Header Sección
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isDraggingOver
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).dividerColor.withOpacity(0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDraggingOver
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                      ),
                    ),
                    Text(
                      "$current / $max",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isFull 
                          ? AppColors.error 
                          : isDraggingOver
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color
                      ),
                    ),
                  ],
                ),
              ),
              
              cards.isEmpty 
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      isDraggingOver ? "Suelta aquí para añadir" : "No cards found",
                      style: TextStyle(
                        color: isDraggingOver
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                        fontSize: 12,
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6, // Más pequeñas en el mazo
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final cleanCard = _sanitizeCard(card);

                      return LongPressDraggable<Card>(
                        data: cleanCard,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 60,
                            height: 84,
                            child: FlippableCard(
                              imageUrl: cleanCard.imagen ?? '',
                              cardBackAsset: 'assets/back-card.png',
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(4),
                              cardData: cleanCard,
                            ),
                          ),
                        ),
                        childWhenDragging: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: Center(
                            child: Icon(Icons.remove, color: Colors.white, size: 20),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => _showDeckCardOptions(context, vm, cleanCard, isExtra: isExtra, isSide: isSide),
                          child: Stack(
                            children: [
                              // USAMOS FLIPPABLE CARD
                              FlippableCard(
                                imageUrl: cleanCard.imagen ?? '',
                                cardBackAsset: 'assets/back-card.png',
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(4),
                                cardData: cleanCard,
                              ),
                              // Cantidad
                              if (card.cantidad > 1)
                                Positioned(
                                  bottom: 2, right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Theme.of(context).dividerColor)
                                    ),
                                    child: Text(
                                      "x${card.cantidad}",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        );
      },
    );
  }

  void _showCardOptions(BuildContext context, DeckEditorViewModel vm, Card card) {
    bool canAdd = vm.canAddCard(card.idCarta); 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: math.min(MediaQuery.of(context).size.width * 0.9, 600),
          child: Stack(
            children: [
              // Contenido principal
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // === IZQUIERDA: IMAGEN DE LA CARTA ===
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        const SizedBox(height: 8), // Espacio superior
                        if (card.imagen != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: card.imagen!,
                              height: 220,
                              width: 200,
                              fit: BoxFit.contain,
                              placeholder: (_,__) => Container(
                                height: 220, 
                                width: 200,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                        
                        // === BOTONES DE ACCIÓN ===
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Column(
                            children: [
                              // Botones en fila horizontal
                              Row(
                                children: [
                                  // Botón Añadir al Deck
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: canAdd ? () {
                                         vm.addCardToDeck(card);
                                         Navigator.pop(context);
                                      } : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                        textStyle: const TextStyle(fontSize: 12),
                                      ),
                                      child: const Text("Deck"),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // Botón Añadir al Side Deck
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: canAdd ? () {
                                         vm.addCardToDeck(card, toSide: true);
                                         Navigator.pop(context);
                                      } : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                        textStyle: const TextStyle(fontSize: 12),
                                      ),
                                      child: const Text("Side Deck"),
                                    ),
                                  ),
                                ],
                              ),
                              
                              if (!canAdd) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          "Límite alcanzado",
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // === DERECHA: DATOS DE LA CARTA ===
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nombre de la carta
                          Text(
                            card.nombre ?? 'Sin nombre',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Tags y tipo
                          _buildTagsSection(context, card),
                          const SizedBox(height: 8),
                          
                          // Detalles específicos de la carta
                          _buildCardSpecificDetails(context, card),
                          const SizedBox(height: 8),
                          
                          // Código de la carta
                          if (card.idCarta.isNotEmpty)
                            _buildDetailRow(context, 'Código:', card.idCarta),
                          
                          const SizedBox(height: 8),
                          
                          // Descripción
                          if (card.descripcion != null) ...[
                            Text(
                              'Descripción:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 100),
                              child: SingleChildScrollView(
                                child: Text(
                                  _getDescriptionText(card.descripcion),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ],
              ),
              // X de cierre en la esquina
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Cerrar",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, DeckEditorViewModel vm) {
    final controller = TextEditingController(text: vm.deckName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Renombrar", style: Theme.of(context).textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Nombre del deck",
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Cancelar", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))
          ),
          ElevatedButton(
            onPressed: () { 
              if(controller.text.isNotEmpty) { 
                vm.updateName(controller.text); 
                Navigator.pop(context); 
              } 
            }, 
            child: const Text("Guardar")
          )
        ],
      ),
    );
  }

  void _showColorDialog(BuildContext context, DeckEditorViewModel vm) {
    final List<Color> colors = [
      Colors.red,        // Rojo
      Colors.blue,       // Azul  
      Colors.yellow,     // Amarillo
      Colors.green,      // Verde
      Colors.purple,     // Morado
      Colors.black,      // Negro
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Color", style: Theme.of(context).textTheme.titleLarge),
        content: Wrap(spacing: 8, runSpacing: 8, children: colors.map((c) => GestureDetector(
          onTap: () { vm.updateColor(c.value); Navigator.pop(context); },
          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).dividerColor, width: 2))),
        )).toList()),
      ),
    );
  }

  void _showClearDeckDialog(BuildContext context, DeckEditorViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Vaciar Deck", style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("¿Estás seguro de que quieres vaciar todo el deck?"),
            const SizedBox(height: 8),
            Text("Esta acción eliminará todas las cartas del Main Deck, Extra Deck y Side Deck.", 
                 style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
            Text("Esta acción no se puede deshacer.", 
                 style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Cancelar", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))
          ),
          ElevatedButton(
            onPressed: () {
              vm.clearDeck();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Vaciar Deck"),
          ),
        ],
      ),
    );
  }

  void _showDeckCardOptions(BuildContext context, DeckEditorViewModel vm, Card card, {required bool isExtra, required bool isSide}) {
    String deckLocation = isSide ? "Side Deck" : (isExtra ? "Extra Deck" : "Main Deck");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          width: math.min(MediaQuery.of(context).size.width * 0.9, 600),
          child: Stack(
            children: [
              // Contenido principal
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // === IZQUIERDA: IMAGEN DE LA CARTA ===
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        const SizedBox(height: 8), // Espacio superior
                        if (card.imagen != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: card.imagen!,
                              height: 220,
                              width: 200,
                              fit: BoxFit.contain,
                              placeholder: (_,__) => Container(
                                height: 220, 
                                width: 200,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                        
                        // === BOTÓN DE ACCIÓN ===
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Column(
                            children: [
                              // Botón Quitar del Deck
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                     vm.removeCard(card, isExtra: isExtra, isSide: isSide);
                                     Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: AppColors.textPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: const Text("Quitar"),
                                ),
                              ),
                              
                              // Información de ubicación
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        deckLocation,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // === DERECHA: DATOS DE LA CARTA ===
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nombre de la carta
                          Text(
                            card.nombre ?? 'Sin nombre',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Tags y tipo
                          _buildTagsSection(context, card),
                          const SizedBox(height: 8),
                          
                          // Detalles específicos de la carta
                          _buildCardSpecificDetails(context, card),
                          const SizedBox(height: 8),
                          
                          // Código de la carta
                          if (card.idCarta.isNotEmpty)
                            _buildDetailRow(context, 'Código:', card.idCarta),
                          
                          const SizedBox(height: 8),
                          
                          // Descripción
                          if (card.descripcion != null) ...[
                            Text(
                              'Descripción:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 100),
                              child: SingleChildScrollView(
                                child: Text(
                                  _getDescriptionText(card.descripcion),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ],
              ),
              // X de cierre en la esquina
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Cerrar",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER FUNCTIONS PARA EL POPUP ---

  Widget _buildTagsSection(BuildContext context, Card card) {
    final finalColors = _getCardFrameColors(context, card);
    List<Widget> tags = [];
    
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
    
    if (card.tipo != null && card.tipo!.isNotEmpty && card.tipo != 'null') {
      final tipoLower = card.tipo!.toLowerCase();
      if (!tipoLower.contains('spell card') && !tipoLower.contains('trap card')) {
        tags.add(_buildTag(context, card.tipo!, finalColors.backgroundColor, finalColors.textColor));
      }
    }
    
    if (card.clasificacion != null && card.clasificacion!.isNotEmpty && card.clasificacion != 'null') {
      tags.add(_buildTag(context, card.clasificacion!, finalColors.backgroundColor, finalColors.textColor));
    }
    
    return Wrap(spacing: 6.0, runSpacing: 6.0, children: tags);
  }

  Widget _buildTag(BuildContext context, String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withAlpha((textColor.a * 255.0 * 0.5).round() & 0xff), width: 1),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor, 
          fontWeight: FontWeight.bold,
          fontSize: 10,
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(context, 'Atributo:', card.atributo),
          if (isLinkMonster && card.ratioEnlace != null)
            _buildDetailRow(context, 'Link:', card.ratioEnlace?.toString())
          else if (isXyzMonster && card.nivelRankLink != null)
            _buildDetailRow(context, 'Rango:', card.nivelRankLink?.toString())
          else if (card.nivelRankLink != null)
            _buildDetailRow(context, 'Nivel:', card.nivelRankLink?.toString()),
          if (card.atk != null || card.def != null)
            _buildDetailRow(
              context,
              'ATK/DEF:',
              isLinkMonster
                  ? '${card.atk ?? '?'}/-'
                  : '${card.atk ?? '?'}/${card.def ?? '?'}',
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    if (value == null || value.trim().isEmpty || value == 'null') return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  String _getDescriptionText(Map<String, dynamic>? descripcion) {
    String? rawDescription;
    if (descripcion == null || descripcion.isEmpty) return 'Descripción no disponible';
    if (descripcion.containsKey('texto') && descripcion['texto'] != null) {
      rawDescription = descripcion['texto'].toString();
    } else {
      String? extractDescription() {
        if (descripcion.containsKey('es') && descripcion['es'] != null) return descripcion['es'].toString();
        if (descripcion.containsKey('ES') && descripcion['ES'] != null) return descripcion['ES'].toString();
        if (descripcion.containsKey('en') && descripcion['en'] != null) return descripcion['en'].toString();
        if (descripcion.containsKey('EN') && descripcion['EN'] != null) return descripcion['EN'].toString();
        for (var value in descripcion.values) { 
          if (value != null && value.toString().trim().isNotEmpty) return value.toString(); 
        }
        return null;
      }
      rawDescription = extractDescription();
    }
    if (rawDescription == null || rawDescription.trim().isEmpty) return 'Descripción no disponible';
    final formattedDescription = rawDescription.replaceAll(RegExp(r'\s*<br */?>\s*', caseSensitive: false), '\n\n');
    return formattedDescription;
  }

  // Helper class para colores de marco
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
    if (tipoLower == 'spell card' || tipoLower == 'spell' || marcoLower == 'spell') {
      return CardFrameColors(const Color(0xFF1D9E74), Colors.white);
    }
    if (marcoLower.contains('trap') || tipoLower.contains('trap')) return CardFrameColors(const Color(0xFFBC5A84), Colors.white);
    if (marcoLower.contains('monster') || tipoLower.contains('monster')) {
      if (clasificacionLower == 'normal' || subtypesLower.contains('normal')) return CardFrameColors(const Color(0xFFFDE68A), Colors.black);
      return CardFrameColors(const Color(0xFFC07B41), Colors.white);
    }
    return CardFrameColors(theme.dividerColor, theme.textTheme.bodyMedium!.color!);
  }
}

// Helper class para colores
class CardFrameColors {
  final Color backgroundColor;
  final Color textColor;
  CardFrameColors(this.backgroundColor, this.textColor);
}

