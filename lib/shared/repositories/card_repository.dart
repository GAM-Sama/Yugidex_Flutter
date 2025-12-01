import 'package:flutter/foundation.dart';
import '../../../models/card_model.dart';
import '../../../models/user_card_model.dart';
import '../../../services/supabase_service.dart';

/// Repositorio para operaciones relacionadas con cartas del catálogo
class CardRepository {
  final SupabaseService _supabaseService;

  CardRepository(this._supabaseService);

  /// Obtiene todas las cartas disponibles en el catálogo
  Future<List<Card>> getAllCards() async {
    try {
      return await _supabaseService.getCards();
    } catch (e) {
      debugPrint('❌ Error en CardRepository.getAllCards: $e');
      throw Exception('No se pudieron obtener las cartas del catálogo');
    }
  }

  /// Obtiene cartas procesadas por jobId
  Future<List<Card>> getCardsByJobId(String jobId) async {
    try {
      return await _supabaseService.getCardsByJobId(jobId);
    } catch (e) {
      debugPrint('❌ Error en CardRepository.getCardsByJobId: $e');
      throw Exception('No se pudieron obtener las cartas del lote $jobId');
    }
  }

  /// Busca cartas por nombre
  Future<List<Card>> searchCards(String query) async {
    try {
      final allCards = await getAllCards();
      final filteredCards = allCards.where((card) {
        final name = (card.nombre ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery);
      }).toList();

      debugPrint('✅ Encontradas ${filteredCards.length} cartas para la búsqueda: $query');
      return filteredCards;
    } catch (e) {
      debugPrint('❌ Error en CardRepository.searchCards: $e');
      throw Exception('Error al buscar cartas');
    }
  }

  /// Obtiene cartas por rarity
  Future<List<Card>> getCardsByRarity(String rarity) async {
    try {
      final allCards = await getAllCards();
      final filteredCards = allCards.where((card) {
        final cardRarity = card.rareza ?? [];
        return cardRarity.contains(rarity);
      }).toList();

      return filteredCards;
    } catch (e) {
      debugPrint('❌ Error en CardRepository.getCardsByRarity: $e');
      throw Exception('Error al filtrar cartas por rarity');
    }
  }

  /// Obtiene cartas por tipo
  Future<List<Card>> getCardsByType(String type) async {
    try {
      final allCards = await getAllCards();
      final filteredCards = allCards.where((card) => card.tipo == type).toList();

      return filteredCards;
    } catch (e) {
      debugPrint('❌ Error en CardRepository.getCardsByType: $e');
      throw Exception('Error al filtrar cartas por tipo');
    }
  }
}

/// Repositorio para operaciones relacionadas con la colección del usuario
class UserCardRepository {
  final SupabaseService _supabaseService;

  UserCardRepository(this._supabaseService);

  /// Obtiene la colección completa del usuario actual
  Future<List<UserCard>> getMyCollection() async {
    try {
      return await _supabaseService.getMyCardCollection();
    } catch (e) {
      debugPrint('❌ Error en UserCardRepository.getMyCollection: $e');
      throw Exception('No se pudo obtener la colección del usuario');
    }
  }

  /// Añade una carta a la colección del usuario
  /// ✅ CORRECTO: Usa 'cardCode' para la función RPC segura
  Future<void> addCardToCollection({
    required String cardCode,
    int quantity = 1,
    String condition = 'mint',
    String? notes,
  }) async {
    try {
      await _supabaseService.addCardToMyCollection(
        cardCode: cardCode,
        quantity: quantity,
        condition: condition,
        notes: notes,
      );
      debugPrint('✅ Carta $cardCode añadida a la colección del usuario');
    } catch (e) {
      debugPrint('❌ Error en UserCardRepository.addCardToCollection: $e');
      rethrow;
    }
  }

  /// Disminuye la cantidad de una carta (o la borra si llega a 0)
  /// 🔥 DESCOMENTADO Y ARREGLADO: Usa el servicio correctamente
  Future<void> decreaseCardQuantity(String userCardId, int currentQuantity, int quantityToRemove) async {
    try {
      debugPrint('🔄 Restando $quantityToRemove a la fila $userCardId');
      await _supabaseService.deleteOrUpdateUserCardQuantity(
        userCardId: userCardId,
        quantityToDelete: quantityToRemove,
        currentQuantity: currentQuantity,
      );
    } catch (e) {
      debugPrint('❌ Error en UserCardRepository.decreaseCardQuantity: $e');
      rethrow;
    }
  }

  /// Elimina una carta de la colección del usuario (Borrado total)
  /// 🔥 DESCOMENTADO Y ARREGLADO
  Future<void> removeCardFromCollection(String userCardId) async {
    try {
      debugPrint('🗑️ Eliminando fila $userCardId de la colección');
      // Usamos un truco: decimos que borre una cantidad enorme para forzar el borrado
      // (O puedes añadir un método deleteUserCard específico en el servicio si prefieres)
      await _supabaseService.deleteOrUpdateUserCardQuantity(
        userCardId: userCardId,
        quantityToDelete: 999999, // Forzamos que sea mayor que la cantidad actual
        currentQuantity: 0, 
      );
    } catch (e) {
      debugPrint('❌ Error en UserCardRepository.removeCardFromCollection: $e');
      rethrow;
    }
  }
}