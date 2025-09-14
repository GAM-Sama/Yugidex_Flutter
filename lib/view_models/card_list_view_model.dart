import 'package:flutter/material.dart' hide Card;
import '../models/card_model.dart';
import '../services/supabase_service.dart';

class CardListViewModel extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Card> _cards = [];
  Card? _selectedCard;
  bool _isLoading = false;
  String? _errorMessage;

  List<Card> get cards => _cards;
  Card? get selectedCard => _selectedCard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga TODAS las cartas de la colección.
  Future<void> fetchCards() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cards = await _supabaseService.getCards();

      if (_cards.isNotEmpty) {
        _selectedCard = _cards.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MÉTODO NUEVO AÑADIDO AQUÍ ---
  /// Carga solo las cartas de un lote de procesamiento específico.
  Future<void> fetchCardsByJobId(String jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Usamos el método que ya añadimos al SupabaseService
      _cards = await _supabaseService.getCardsByJobId(jobId);

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

  void selectCard(Card card) {
    if (_selectedCard?.idCarta != card.idCarta) {
      _selectedCard = card;
      notifyListeners();
    }
  }
}
