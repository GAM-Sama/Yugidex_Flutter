import 'package:flutter/material.dart' hide Card;
import '../models/card_model.dart';
import '../services/supabase_service.dart';

/// ViewModel específico para cartas procesadas - trabaja directamente con objetos Card
class ProcessedCardsViewModel extends ChangeNotifier {
  SupabaseService? _supabaseService;

  List<Card> _cards = [];
  Card? _selectedCard;
  bool _isLoading = true;
  String? _errorMessage;

  List<Card> get cards => _cards;
  Card? get selectedCard => _selectedCard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  void initialize(SupabaseService supabaseService) {
    _supabaseService = supabaseService;
  }

  /// 🔥 NUEVO MÉTODO: Obtiene el Stream de datos en tiempo real
  /// Este es el que usará tu StreamBuilder en la pantalla
  Stream<List<Card>> getProcessedCardsStream(String jobId) {
    if (_supabaseService == null) {
      // Devolvemos un error como Stream si el servicio no está listo
      return Stream.error('Servicio no inicializado');
    }
    return _supabaseService!.streamCardsByJobId(jobId);
  }

  /// Mantenemos este método por compatibilidad (o para refresco manual)
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
      // Nota: Asegúrate de que tu servicio tenga implementado getCardsByJobId
      // (aunque sea la versión antigua que devuelve Future)
      _cards = await _supabaseService!.getCardsByJobId(jobId);

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

  void selectCard(Card card) {
    if (_selectedCard == card) {
      _selectedCard = null;
    } else {
      _selectedCard = card;
    }
    notifyListeners();
  }

  bool isCardSelected(Card card) {
    return identical(_selectedCard, card);
  }
}