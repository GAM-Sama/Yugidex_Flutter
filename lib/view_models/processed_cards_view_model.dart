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

  void initialize(SupabaseService supabaseService) {
    _supabaseService = supabaseService;
  }

  /// Carga las cartas procesadas de un lote específico
  Future<void> fetchCardsByJobId(String jobId) async {
    print('🔥 ProcessedCardsViewModel - fetchCardsByJobId iniciado para jobId: $jobId');
    if (_supabaseService == null) {
      _errorMessage = 'Servicio no inicializado';
      print('❌ ProcessedCardsViewModel - Servicio no inicializado');
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    print('🔥 ProcessedCardsViewModel - Estado de carga iniciado');
    notifyListeners();

    try {
      print('🔥 ProcessedCardsViewModel - Llamando a getCardsByJobId...');
      _cards = await _supabaseService!.getCardsByJobId(jobId);
      print('✅ ProcessedCardsViewModel - Datos obtenidos: ${_cards.length} cartas');

      if (_cards.isNotEmpty) {
        _selectedCard = _cards.first;
        print('✅ ProcessedCardsViewModel - Primera carta seleccionada: ${_selectedCard?.nombre}');
      } else {
        _selectedCard = null;
        print('⚠️ ProcessedCardsViewModel - No hay cartas disponibles');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _selectedCard = null;
      print('❌ ProcessedCardsViewModel - Error al cargar cartas: $e');
    } finally {
      _isLoading = false;
      print('🔥 ProcessedCardsViewModel - Estado de carga finalizado. Cartas: ${_cards.length}, Loading: $_isLoading');
      notifyListeners();
    }
  }

  void selectCard(Card card) {
    _selectedCard = card;
    notifyListeners();
  }
}
