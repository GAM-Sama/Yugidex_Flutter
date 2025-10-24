import 'package:flutter/material.dart' hide Card;
import '../models/user_card_model.dart';
import '../services/supabase_service.dart';

class CardListViewModel extends ChangeNotifier {
  SupabaseService? _supabaseService;

  List<UserCard> _cards = []; // Renombrado de _userCards
  UserCard? _selectedCard;
  bool _isLoading = false;
  String? _errorMessage;

  // --- ¡CAMBIO IMPORTANTE! ---
  // Este es ahora el getter principal. Devuelve la lista CON cantidades.
  List<UserCard> get cards => _cards;

  UserCard? get selectedCard => _selectedCard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // El getter antiguo 'List<Card> get cards' se ha eliminado.

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
      _cards = await _supabaseService!.getMyCardCollection(); // Carga en _cards

      if (_cards.isNotEmpty) {
        _selectedCard = _cards.first;
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
      _cards = await _supabaseService!.getMyCardsByJobId(jobId); // Carga en _cards

      if (_cards.isNotEmpty) {
        // Seleccionamos la primera carta de la lista por defecto
        _selectedCard = _cards.first;
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
      final cardDetailsList = await _supabaseService!.getCardsByJobId(jobId);

      if (cardDetailsList.isNotEmpty) {
        // Crear UserCards temporales para mostrar las cartas procesadas
        _cards = cardDetailsList.map((card) => UserCard( // Carga en _cards
              userCardId: 'temp_${card.idCarta}',
              quantity: 1, // Asumimos 1 ya que son solo los resultados
              condition: 'mint',
              notes: null,
              acquiredDate: DateTime.now(),
              cardDetails: card,
            )).toList();

        _selectedCard = _cards.first;
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

  // --- ¡CAMBIO IMPORTANTE! ---
  // 'selectCard' ahora acepta un UserCard directamente.
  void selectCard(UserCard userCard) {
    _selectedCard = userCard;
    notifyListeners();
  }
}