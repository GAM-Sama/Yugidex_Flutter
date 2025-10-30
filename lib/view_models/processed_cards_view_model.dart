import 'package:flutter/material.dart' hide Card;
import '../models/card_model.dart';
import '../services/supabase_service.dart';

/// ViewModel específico para cartas procesadas - trabaja directamente con objetos Card
class ProcessedCardsViewModel extends ChangeNotifier {
  SupabaseService? _supabaseService;

  List<Card> _cards = [];
  Card? _selectedCard;
  bool _isLoading = true;  // Estado inicial: está cargando
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

  /// Carga las cartas procesadas de un lote específico
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
    // Usar identical() para comparar referencias de objetos
    if (_selectedCard == card) {
      _selectedCard = null; // Deseleccionar si es la misma instancia
    } else {
      _selectedCard = card; // Seleccionar la nueva instancia
    }
    notifyListeners();
  }

  // Método auxiliar para verificar si una carta está seleccionada
  bool isCardSelected(Card card) {
    return identical(_selectedCard, card);
  }
}
