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

  void selectCard(Card card) {
    // --- ¡AQUÍ ESTÁ EL CAMBIO! ---
    // Usamos el nuevo identificador 'idCarta' para comparar.
    if (_selectedCard?.idCarta != card.idCarta) {
      _selectedCard = card;
      notifyListeners();
    }
  }
}
