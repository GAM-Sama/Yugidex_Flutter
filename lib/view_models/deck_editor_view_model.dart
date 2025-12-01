import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import '../models/deck_model.dart';
import '../models/card_model.dart' as m; 
import '../services/supabase_service.dart';

class DeckEditorViewModel extends ChangeNotifier {
  final SupabaseService _supabaseService;
  
  Deck? _currentDeck;
  String _deckName = '';
  int _deckColor = 0xFF455A64;
  bool _isLoading = true;
  bool _isDirty = false;

  // Listas del Mazo (Cantidad = Copias en el mazo)
  List<m.Card> _mainDeck = [];
  List<m.Card> _extraDeck = [];
  List<m.Card> _sideDeck = [];

  // Colección del Usuario (Cantidad = Copias en propiedad)
  List<m.Card> _userCollection = [];
  List<m.Card> _filteredCollection = []; // Para el buscador

  // Getters
  String get deckName => _deckName;
  int get deckColor => _deckColor;
  bool get isLoading => _isLoading;
  bool get isDirty => _isDirty;
  
  List<m.Card> get mainDeck => _mainDeck;
  List<m.Card> get extraDeck => _extraDeck;
  List<m.Card> get sideDeck => _sideDeck;
  List<m.Card> get collection => _filteredCollection; // Mostramos la filtrada

  int get mainCount => _mainDeck.fold(0, (sum, c) => sum + c.cantidad);
  int get extraCount => _extraDeck.fold(0, (sum, c) => sum + c.cantidad);
  int get sideCount => _sideDeck.fold(0, (sum, c) => sum + c.cantidad);
  
  DeckEditorViewModel(this._supabaseService);

  // --- CARGA ---
  Future<void> loadData(String deckId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Cargar TU Colección (Para saber qué tienes)
      final userCards = await _supabaseService.getMyCardCollection();
      // Convertimos UserCard a Card para unificar modelos en la vista
      _userCollection = userCards.map((uc) {
        // Truco: Guardamos la cantidad poseída en el modelo Card
        return m.Card(
          idCarta: uc.cardDetails.idCarta,
          cantidad: uc.quantity, // <--- ESTO ES LO QUE TIENES
          nombre: uc.cardDetails.nombre,
          imagen: uc.cardDetails.imagen,
          marcoCarta: uc.cardDetails.marcoCarta,
          tipo: uc.cardDetails.tipo,
          atk: uc.cardDetails.atk,
          def: uc.cardDetails.def,
          nivelRankLink: uc.cardDetails.nivelRankLink,
          subtipo: uc.cardDetails.subtipo,
          clasificacion: uc.cardDetails.clasificacion,
          descripcion: uc.cardDetails.descripcion,
          rareza: uc.cardDetails.rareza,
        );
      }).toList();
      
      _filteredCollection = List.from(_userCollection);

      // 2. Cargar Mazo
      final response = await Supabase.instance.client
          .from('decks')
          .select()
          .eq('id', deckId)
          .single();
      
      _currentDeck = Deck.fromJson(response);
      _deckName = _currentDeck!.name;
      _deckColor = _currentDeck!.color;

      _hydrateDecks();

    } catch (e) {
      debugPrint("Error cargando: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CREACIÓN NUEVO DECK ---
  Future<void> createNewDeck(String deckName) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Cargar TU Colección (Para saber qué tienes)
      final userCards = await _supabaseService.getMyCardCollection();
      // Convertimos UserCard a Card para unificar modelos en la vista
      _userCollection = userCards.map((uc) {
        return m.Card(
          idCarta: uc.cardDetails.idCarta,
          cantidad: uc.quantity,
          nombre: uc.cardDetails.nombre,
          imagen: uc.cardDetails.imagen,
          marcoCarta: uc.cardDetails.marcoCarta,
          tipo: uc.cardDetails.tipo,
          atk: uc.cardDetails.atk,
          def: uc.cardDetails.def,
          nivelRankLink: uc.cardDetails.nivelRankLink,
          subtipo: uc.cardDetails.subtipo,
          clasificacion: uc.cardDetails.clasificacion,
          descripcion: uc.cardDetails.descripcion,
          rareza: uc.cardDetails.rareza,
        );
      }).toList();
      
      _filteredCollection = List.from(_userCollection);

      // 2. Inicializar deck vacío
      _currentDeck = null; // No existe en BD aún
      _deckName = deckName;
      _deckColor = 0xFF1976D2; // Color por defecto (azul)

      // 3. Inicializar listas vacías
      _mainDeck.clear();
      _extraDeck.clear();
      _sideDeck.clear();

    } catch (e) {
      debugPrint("Error creando nuevo deck: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _hydrateDecks() {
    if (_currentDeck == null) return;
    // Usamos la colección cargada para hidratar, así tenemos los datos cacheados
    // Si una carta del mazo ya no está en la colección, habría que buscarla en catálogo global,
    // pero por simplicidad asumimos que trabajamos con lo que tienes.
    _mainDeck = _mapItemsToCards(_currentDeck!.mainDeckList);
    _extraDeck = _mapItemsToCards(_currentDeck!.extraDeckList);
    _sideDeck = _mapItemsToCards(_currentDeck!.sideDeckList);
  }

  List<m.Card> _mapItemsToCards(List<DeckItem> items) {
    List<m.Card> result = [];
    for (var item in items) {
      try {
        // Buscamos en la colección primero
        final baseCard = _userCollection.firstWhere(
          (c) => c.idCarta == item.cardId,
          // Si no la tengo (la vendí?), creo una dummy visual
          orElse: () => m.Card(idCarta: item.cardId, cantidad: 0, nombre: '???', marcoCarta: 'normal', imagen: ''),
        );
        
        // Creamos copia visual con la cantidad EN EL MAZO
        result.add(m.Card(
          idCarta: baseCard.idCarta,
          cantidad: item.quantity, 
          nombre: baseCard.nombre,
          imagen: baseCard.imagen,
          marcoCarta: baseCard.marcoCarta,
          tipo: baseCard.tipo,
          atk: baseCard.atk,
          def: baseCard.def,
          nivelRankLink: baseCard.nivelRankLink,
          subtipo: baseCard.subtipo,
          clasificacion: baseCard.clasificacion,
          descripcion: baseCard.descripcion,
        ));
      } catch (e) {
        debugPrint("Error mapeando: ${item.cardId}");
      }
    }
    return result;
  }

  // --- FILTRO LOCAL (Buscador) ---
  void filterCollection(String query) {
    if (query.isEmpty) {
      _filteredCollection = List.from(_userCollection);
    } else {
      _filteredCollection = _userCollection.where((c) {
        final name = c.nombre?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  // --- LÓGICA DE VALIDACIÓN ---
  
  // Devuelve cuántas copias de esta carta hay YA en el mazo (total)
  int _getCopiesInDeck(String cardId) {
    int count = 0;
    // Buscar en Main
    for (var c in _mainDeck) if(c.idCarta == cardId) count += c.cantidad;
    // Buscar en Extra
    for (var c in _extraDeck) if(c.idCarta == cardId) count += c.cantidad;
    // Buscar en Side
    for (var c in _sideDeck) if(c.idCarta == cardId) count += c.cantidad;
    return count;
  }

  // Devuelve cuántas tengo en mi colección
  int _getOwnedCopies(String cardId) {
    final card = _userCollection.firstWhere((c) => c.idCarta == cardId, orElse: () => const m.Card(idCarta: '', cantidad: 0));
    return card.cantidad;
  }

  bool canAddCard(String cardId) {
    final currentInDeck = _getCopiesInDeck(cardId);
    final owned = _getOwnedCopies(cardId);
    
    // Regla 1: Máximo 3 copias por mazo
    if (currentInDeck >= 3) return false;
    
    // Regla 2: No puedes poner más de las que tienes
    if (currentInDeck >= owned) return false;

    return true;
  }

  // Métodos auxiliares para estado visual de cartas
  bool isCardExhausted(String cardId) {
    final owned = _getOwnedCopies(cardId);
    return owned == 0;
  }

  bool isCardLimitReached(String cardId) {
    final currentInDeck = _getCopiesInDeck(cardId);
    final owned = _getOwnedCopies(cardId);
    
    // Límite alcanzado si: no tenemos más copias O ya tenemos 3 en deck
    return (currentInDeck >= owned && owned > 0) || currentInDeck >= 3;
  }

  String getCardStatusText(String cardId) {
    final currentInDeck = _getCopiesInDeck(cardId);
    final owned = _getOwnedCopies(cardId);
    
    if (owned == 0) return "Agotado";
    if (currentInDeck >= 3) return "Límite 3/3";
    if (currentInDeck >= owned) return "Sin copias";
    return "";
  }

  // --- EDICIÓN ---

  void addCardToDeck(m.Card card, {bool toSide = false}) {
    if (!canAddCard(card.idCarta)) return; // Doble check de seguridad

    List<m.Card> targetList;

    if (toSide) {
      targetList = _sideDeck;
    } else {
      // Auto-detectar Extra Deck - detección mejorada
      final tipoLower = card.tipo?.toLowerCase() ?? '';
      final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
      final subtypesLower = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();
      
      bool isExtra = tipoLower.contains('fusion') || tipoLower.contains('synchro') || 
                     tipoLower.contains('xyz') || tipoLower.contains('link') ||
                     marcoLower.contains('fusion') || marcoLower.contains('synchro') ||
                     marcoLower.contains('xyz') || marcoLower.contains('link') ||
                     subtypesLower.contains('fusion') || subtypesLower.contains('synchro') ||
                     subtypesLower.contains('xyz') || subtypesLower.contains('link');
      
      targetList = isExtra ? _extraDeck : _mainDeck;
    }

    int index = targetList.indexWhere((c) => c.idCarta == card.idCarta);
    
    if (index != -1) {
      // Sumar cantidad visualmente (chapuza rápida: reemplazar objeto)
       var existing = targetList[index];
       targetList[index] = m.Card(
         idCarta: existing.idCarta, cantidad: existing.cantidad + 1, 
         nombre: existing.nombre, imagen: existing.imagen, marcoCarta: existing.marcoCarta,
         tipo: existing.tipo, atk: existing.atk, def: existing.def, nivelRankLink: existing.nivelRankLink,
         descripcion: existing.descripcion
       );
    } else {
      // Añadir nueva
      targetList.add(m.Card(
           idCarta: card.idCarta, cantidad: 1,
           nombre: card.nombre, imagen: card.imagen, marcoCarta: card.marcoCarta,
           tipo: card.tipo, atk: card.atk, def: card.def, nivelRankLink: card.nivelRankLink,
           descripcion: card.descripcion
      ));
    }
    
    _isDirty = true; // Marcamos que hay cambios
    notifyListeners();
  }

  void removeCardFromDeck(String cardId) {
    // Buscar la carta en todos los decks
    int? mainIndex = _mainDeck.indexWhere((c) => c.idCarta == cardId);
    int? extraIndex = _extraDeck.indexWhere((c) => c.idCarta == cardId);
    int? sideIndex = _sideDeck.indexWhere((c) => c.idCarta == cardId);
    
    if (mainIndex != -1) {
      _removeFromList(_mainDeck, mainIndex);
    } else if (extraIndex != -1) {
      _removeFromList(_extraDeck, extraIndex);
    } else if (sideIndex != -1) {
      _removeFromList(_sideDeck, sideIndex);
    }
  }
  
  void _removeFromList(List<m.Card> list, int index) {
    if (list[index].cantidad > 1) {
      var existing = list[index];
      list[index] = m.Card(
        idCarta: existing.idCarta, cantidad: existing.cantidad - 1,
        nombre: existing.nombre, imagen: existing.imagen, marcoCarta: existing.marcoCarta,
        tipo: existing.tipo, atk: existing.atk, def: existing.def, nivelRankLink: existing.nivelRankLink,
        descripcion: existing.descripcion
      );
    } else {
      list.removeAt(index);
    }
    _isDirty = true;
    notifyListeners();
  }

  void removeCard(m.Card card, {required bool isExtra, required bool isSide}) {
      List<m.Card> targetList = isSide ? _sideDeck : (isExtra ? _extraDeck : _mainDeck);
      int index = targetList.indexWhere((c) => c.idCarta == card.idCarta);
      if (index == -1) return;
      
      if (targetList[index].cantidad > 1) {
         var existing = targetList[index];
         targetList[index] = m.Card(
           idCarta: existing.idCarta, cantidad: existing.cantidad - 1,
           nombre: existing.nombre, imagen: existing.imagen, marcoCarta: existing.marcoCarta,
           tipo: existing.tipo, atk: existing.atk, def: existing.def, nivelRankLink: existing.nivelRankLink,
           descripcion: existing.descripcion
         );
      } else {
        targetList.removeAt(index);
      }
      _isDirty = true;
      notifyListeners();
  }

  // --- GUARDADO MANUAL ---
  Future<void> saveDeck() async {
    final mainJson = _mainDeck.map((c) => {'card_id': c.idCarta, 'quantity': c.cantidad}).toList();
    final extraJson = _extraDeck.map((c) => {'card_id': c.idCarta, 'quantity': c.cantidad}).toList();
    final sideJson = _sideDeck.map((c) => {'card_id': c.idCarta, 'quantity': c.cantidad}).toList();

    try {
      if (_currentDeck == null) {
        // Crear nuevo deck
        await _supabaseService.createDeck(_deckName, _deckColor);
        
        // Recargar el deck para obtener el ID
        final response = await Supabase.instance.client
            .from('decks')
            .select()
            .eq('name', _deckName)
            .eq('color', _deckColor)
            .order('created_at', ascending: false)
            .limit(1)
            .single();
        
        _currentDeck = Deck.fromJson(response);
        
        // Actualizar el deck con las cartas
        await Supabase.instance.client.from('decks').update({
          'main_deck': mainJson,
          'extra_deck': extraJson,
          'side_deck': sideJson,
        }).eq('id', _currentDeck!.id);
      } else {
        // Actualizar deck existente
        await Supabase.instance.client.from('decks').update({
          'name': _deckName,
          'color': _deckColor,
          'main_deck': mainJson,
          'extra_deck': extraJson,
          'side_deck': sideJson,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _currentDeck!.id);
      }
      
      _isDirty = false;
      notifyListeners();
      debugPrint("✅ Mazo guardado exitosamente");
    } catch (e) {
      debugPrint("❌ Error guardando: $e");
      rethrow;
    }
  }

  void updateName(String name) {
    _deckName = name;
    _isDirty = true;
    notifyListeners();
  }

  void updateColor(int color) {
    _deckColor = color;
    _isDirty = true;
    notifyListeners();
  }

  void clearDeck() {
    _mainDeck.clear();
    _extraDeck.clear();
    _sideDeck.clear();
    _isDirty = true;
    notifyListeners();
  }
}