import 'package:flutter/material.dart' hide Card;
import '../models/card_model.dart';
import '../models/user_card_model.dart';
import '../services/supabase_service.dart';

class CardListViewModel extends ChangeNotifier {
  SupabaseService? _supabaseService;

  List<UserCard> _userCards = [];
  UserCard? _selectedCard;
  bool _isLoading = false;
  String? _errorMessage;

  List<UserCard> get userCards => _userCards;
  UserCard? get selectedCard => _selectedCard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed property to get cards for backward compatibility
  List<Card> get cards => _userCards.map((userCard) => userCard.cardDetails).toList();

  // Método para inicializar con SupabaseService del Provider
  void initialize(SupabaseService supabaseService) {
    _supabaseService = supabaseService;
  }

  /// Carga la colección personal del usuario que ha iniciado sesión.
  Future<void> fetchCards() async {
    if (_supabaseService == null) {
      _errorMessage = 'Servicio no inicializado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userCards = await _supabaseService!.getMyCardCollection();

      if (_userCards.isNotEmpty) {
        _selectedCard = _userCards.first;
      } else {
        _selectedCard = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _selectedCard = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga solo las cartas de un lote de procesamiento específico.
  Future<void> fetchCardsByJobId(String jobId) async {
    if (_supabaseService == null) {
      _errorMessage = 'Servicio no inicializado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Usamos el método que ya añadimos al SupabaseService
      _userCards = await _supabaseService!.getMyCardsByJobId(jobId);

      if (_userCards.isNotEmpty) {
        // Seleccionamos la primera carta de la lista por defecto
        _selectedCard = _userCards.first;
      } else {
        _selectedCard = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga todas las cartas procesadas en un lote específico (no solo las del usuario).
  Future<void> fetchAllCardsByJobId(String jobId) async {
    if (_supabaseService == null) {
      _errorMessage = 'Servicio no inicializado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Obtenemos todas las cartas procesadas en el lote
      final cards = await _supabaseService!.getCardsByJobId(jobId);

      if (cards.isNotEmpty) {
        // Crear UserCards temporales para mostrar las cartas procesadas
        _userCards = cards.map((card) => UserCard(
          userCardId: 'temp_${card.idCarta}',
          quantity: 1,
          condition: 'mint',
          notes: null,
          acquiredDate: DateTime.now(),
          cardDetails: card,
        )).toList();

        _selectedCard = _userCards.first;
      } else {
        _selectedCard = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCard(Card card) {
    // Find the corresponding UserCard for this card
    final userCard = _userCards.where((userCard) => userCard.cardDetails.idCarta == card.idCarta).firstOrNull;
    if (userCard != null) {
      _selectedCard = userCard;
      notifyListeners();
    }
  }
}
