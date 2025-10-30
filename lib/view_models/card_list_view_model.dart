import 'package:flutter/foundation.dart';

import '../models/user_card_model.dart';
import '../services/supabase_service.dart';
// Importa tu clase Card

// Helper typedef (asegúrate de tenerlo definido, usualmente en el archivo del modelo o en un archivo de utilidades)
typedef ValueGetter<T> = T Function();

class CardListViewModel extends ChangeNotifier {
  SupabaseService? _supabaseService;
  bool _isDisposed = false;

  // Tiempo de expiración de la caché (5 minutos en milisegundos)
  final int _cacheDuration;
  
  // Última vez que se cargaron las cartas
  int _lastFetchTime = 0;
  
  CardListViewModel({Duration cacheDuration = const Duration(minutes: 5)})
      : _cacheDuration = cacheDuration.inMilliseconds;
  
  // Bandera para forzar una recarga
  bool _forceRefresh = false;

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
  }

  /// Carga la colección de cartas personal del usuario actual desde Supabase.
  /// [forceRefresh] si es true, ignora la caché y fuerza una recarga
  Future<void> fetchCards({bool forceRefresh = false}) async {
    // Verificar si debemos continuar antes de iniciar operaciones costosas
    if (!_shouldContinue) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Si no es un refresco forzado y los datos están en caché, no hacer nada
    if (!forceRefresh && 
        !_forceRefresh && 
        _cards.isNotEmpty && 
        (now - _lastFetchTime) < _cacheDuration) {
      return;
    }
    
    
    if (_supabaseService == null) {
      setError('Servicio Supabase no disponible.');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _forceRefresh = false; // Reseteamos el flag de refresco forzado
    notifyListeners();

    try {
      
      final fetchedCards = await _supabaseService!.getMyCardCollection();
      
      // Verificar si debemos continuar después de la operación asíncrona
      if (!_shouldContinue) {
        return;
      }
      
      _cards = fetchedCards;
      _lastFetchTime = now; // Actualizamos el tiempo de la última carga
      
      // Selecciona la primera carta por defecto si la lista no está vacía
      if (_cards.isNotEmpty) {
        _selectedCard = _cards.first;
      } else {
        _selectedCard = null; // No hay carta para seleccionar
      }
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = 'Error al cargar la colección: ${e.toString()}';
      _selectedCard = null; // Limpia la selección en caso de error
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Selecciona una carta específica para mostrar sus detalles.
  void selectCard(UserCard userCard) {
    if (_selectedCard?.userCardId != userCard.userCardId) { // Solo notifica si cambia
        _selectedCard = userCard;
        notifyListeners();
    }
  }

  /// Elimina una cantidad específica de una carta o la elimina por completo de la colección.
  Future<void> deleteUserCardQuantity({
    required String userCardId,
    required int quantityToDelete,
    required int currentQuantity,
  }) async {
    if (_supabaseService == null) {
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

      // 2. Actualiza la lista localmente para reflejar el cambio inmediatamente
      if (quantityToDelete >= currentQuantity) {
        // --- Eliminar la carta de la lista local ---
        _cards.removeWhere((card) => card.userCardId == userCardId);
        // Si la carta borrada era la seleccionada, selecciona la primera o ninguna
        if (_selectedCard?.userCardId == userCardId) {
          _selectedCard = _cards.isNotEmpty ? _cards.first : null;
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
          // Si la carta actualizada era la seleccionada, actualiza la selección
          if (_selectedCard?.userCardId == userCardId) {
            _selectedCard = updatedCard;
          }
        }
      }

       notifyListeners(); // Notifica a la UI para que refresque la lista y el panel
    } catch (e) {
      // Guarda el mensaje de error para mostrarlo si es necesario
      setError('Error al actualizar la carta: ${e.toString()}');
      rethrow; // Propaga el error para que la UI (p.ej. CardDetailPanel) pueda reaccionar
    }
  }

  /// Método auxiliar para establecer un mensaje de error y notificar a los listeners.
   void setError(String message) {
     _errorMessage = message;
     _isLoading = false; // Asume que si hay error, la carga ha terminado
     notifyListeners();
   }

  /// Fuerza una recarga de los datos en la próxima llamada a fetchCards
  void refresh() {
    _forceRefresh = true;
  }

  // Controlador para cancelar operaciones asíncronas
  bool _shouldCancelOperations = false;
  
  /// Cancela todas las operaciones pendientes
  void _cancelPendingOperations() {
    if (!_shouldCancelOperations) {
      _shouldCancelOperations = true;
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
      if (kDebugMode) {
        debugPrint('🛑 CardListViewModel: Operaciones canceladas');
      }
    }
  }
  
  /// Verifica si se debe continuar con las operaciones
  bool get _shouldContinue => !_isDisposed && !_shouldCancelOperations;
  
  @override
  void dispose() {
    if (!_isDisposed) {
      // 1. Cancelar operaciones pendientes
      _cancelPendingOperations();
      
      // 2. Limpiar datos
      _cards = [];
      _selectedCard = null;
      _errorMessage = null;
      
      // 3. Desreferenciar el servicio
      _supabaseService = null;
      
      // 4. Marcar como eliminado
      _isDisposed = true;
      
      // 5. Llamar al dispose del padre
      super.dispose();
    }
  }
}
