import 'package:flutter/material.dart' hide Card; // Evita conflicto
import '../models/user_card_model.dart';
import '../services/supabase_service.dart';
import '../models/card_model.dart'; // Importa tu clase Card

// Helper typedef (asegúrate de tenerlo definido, usualmente en el archivo del modelo o en un archivo de utilidades)
typedef ValueGetter<T> = T Function();

class CardListViewModel extends ChangeNotifier {
  SupabaseService? _supabaseService;

  List<UserCard> _cards = []; // Lista principal de cartas de la colección
  UserCard? _selectedCard; // La carta actualmente seleccionada en el panel de detalle
  bool _isLoading = false; // Indica si se están cargando datos
  String? _errorMessage; // Mensaje de error si algo falla

  // --- Getters Públicos ---
  List<UserCard> get cards => _cards;
  UserCard? get selectedCard => _selectedCard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Método para inicializar el ViewModel con el SupabaseService.
  /// Debe llamarse una vez, usualmente desde donde se provee el ViewModel.
  void initialize(SupabaseService supabaseService) {
    _supabaseService = supabaseService;
    print('✅ CardListViewModel inicializado con SupabaseService.');
  }

  /// Carga la colección de cartas personal del usuario actual desde Supabase.
  Future<void> fetchCards() async {
    print('⏳ CardListViewModel: Iniciando fetchCards...');
    if (_supabaseService == null) {
      print('❌ CardListViewModel: Error - SupabaseService no inicializado.');
      setError('Servicio Supabase no disponible.'); // Usa el método setError
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notifica que la carga ha comenzado

    try {
      _cards = await _supabaseService!.getMyCardCollection(); // Llama al servicio
      print('✅ CardListViewModel: Se obtuvieron ${_cards.length} cartas.');

      // Selecciona la primera carta por defecto si la lista no está vacía
      if (_cards.isNotEmpty) {
        _selectedCard = _cards.first;
        print('ℹ️ CardListViewModel: Primera carta seleccionada: ${_selectedCard?.cardDetails.nombre}');
      } else {
        _selectedCard = null; // No hay carta para seleccionar
        print('ℹ️ CardListViewModel: La colección está vacía.');
      }
    } catch (e, stacktrace) {
      print('❌ CardListViewModel: Error en fetchCards: $e');
      print('❌ Stacktrace: $stacktrace');
      setError('Error al cargar la colección: ${e.toString()}'); // Usa el método setError
      _selectedCard = null; // Limpia la selección en caso de error
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica que la carga ha terminado (con éxito o error)
      print('🏁 CardListViewModel: fetchCards finalizado.');
    }
  }

  /// Selecciona una carta específica para mostrar sus detalles.
  void selectCard(UserCard userCard) {
    if (_selectedCard?.userCardId != userCard.userCardId) { // Solo notifica si cambia
        _selectedCard = userCard;
        print('ℹ️ CardListViewModel: Carta seleccionada: ${userCard.cardDetails.nombre}');
        notifyListeners();
    }
  }

  /// Elimina una cantidad específica de una carta o la elimina por completo de la colección.
  Future<void> deleteUserCardQuantity({
    required String userCardId,
    required int quantityToDelete,
    required int currentQuantity,
  }) async {
    print('⏳ CardListViewModel: Iniciando deleteUserCardQuantity para userCardId: $userCardId');
    if (_supabaseService == null) {
      print('❌ CardListViewModel: Error - SupabaseService no inicializado.');
      throw Exception('Servicio Supabase no inicializado');
    }

    // Podrías añadir un estado de carga específico para esta operación si lo deseas
    // _isLoading = true;
    _errorMessage = null;
    // notifyListeners(); // Quizás notificar solo al final

    try {
      // 1. Llama al servicio Supabase para actualizar/borrar en la DB
      await _supabaseService!.deleteOrUpdateUserCardQuantity(
        userCardId: userCardId,
        quantityToDelete: quantityToDelete,
        currentQuantity: currentQuantity,
      );
      print('✅ CardListViewModel: SupabaseService completó deleteOrUpdateUserCardQuantity.');

      // 2. Actualiza la lista localmente para reflejar el cambio inmediatamente
      if (quantityToDelete >= currentQuantity) {
        // --- Eliminar la carta de la lista local ---
        _cards.removeWhere((card) => card.userCardId == userCardId);
        print('ℹ️ CardListViewModel: Carta $userCardId eliminada localmente.');
        // Si la carta borrada era la seleccionada, selecciona la primera o ninguna
        if (_selectedCard?.userCardId == userCardId) {
          _selectedCard = _cards.isNotEmpty ? _cards.first : null;
          print('ℹ️ CardListViewModel: Selección reseteada tras eliminación.');
        }
      } else {
        // --- Actualizar la cantidad en la lista local ---
        final index = _cards.indexWhere((card) => card.userCardId == userCardId);
        if (index != -1) {
          // Usa el método copyWith (¡ASEGÚRATE DE QUE EXISTA EN UserCard!)
          final updatedCard = _cards[index].copyWith(
            quantity: currentQuantity - quantityToDelete
          );
          _cards[index] = updatedCard;
          print('ℹ️ CardListViewModel: Cantidad de $userCardId actualizada localmente a ${updatedCard.quantity}.');
          // Si la carta actualizada era la seleccionada, actualiza la selección
          if (_selectedCard?.userCardId == userCardId) {
            _selectedCard = updatedCard;
            print('ℹ️ CardListViewModel: Selección actualizada tras cambio de cantidad.');
          }
        } else {
           print('⚠️ CardListViewModel: No se encontró la carta $userCardId localmente para actualizar cantidad.');
        }
      }

       // _isLoading = false; // Restablece estado de carga si lo usaste
       notifyListeners(); // Notifica a la UI para que refresque la lista y el panel
       print('✅ CardListViewModel: deleteUserCardQuantity completado exitosamente.');

    } catch (e) {
       print('❌ CardListViewModel: Error en deleteUserCardQuantity: $e');
      // Guarda el mensaje de error para mostrarlo si es necesario
      setError('Error al actualizar la carta: ${e.toString()}'); // Usa el método setError
       // _isLoading = false; // Restablece estado de carga si lo usaste
      // notifyListeners(); // setError ya notifica
      rethrow; // Propaga el error para que la UI (p.ej. CardDetailPanel) pueda reaccionar
    }
  }

  /// Método auxiliar para establecer un mensaje de error y notificar a los listeners.
   void setError(String message) {
     _errorMessage = message;
     _isLoading = false; // Asume que si hay error, la carga ha terminado
     notifyListeners();
     print('❌ CardListViewModel: Error establecido - "$message"');
   }

}
