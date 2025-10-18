import 'package:flutter/foundation.dart';
import '../../../models/card_model.dart';
import '../../../models/user_card_model.dart';
import '../../../services/supabase_service.dart';

/// Repositorio para operaciones relacionadas con cartas
/// Esta capa separa la lógica de negocio de la implementación de servicios
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

  /// Busca cartas por nombre o texto
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

      debugPrint('✅ Encontradas ${filteredCards.length} cartas de rarity: $rarity');
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

      debugPrint('✅ Encontradas ${filteredCards.length} cartas de tipo: $type');
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
  Future<void> addCardToCollection({
    required int cardId,
    int quantity = 1,
    String condition = 'mint',
    String? notes,
  }) async {
    try {
      await _supabaseService.addCardToMyCollection(
        cardId: cardId,
        quantity: quantity,
        condition: condition,
        notes: notes,
      );
      debugPrint('✅ Carta $cardId añadida a la colección del usuario');
    } catch (e) {
      debugPrint('❌ Error en UserCardRepository.addCardToCollection: $e');
      rethrow;
    }
  }

  /// Actualiza la cantidad de una carta en la colección
  Future<void> updateCardQuantity(int cardId, int newQuantity) async {
    try {
      // Esta funcionalidad necesitaría ser implementada en SupabaseService primero
      debugPrint('🔄 Actualizando cantidad de carta $cardId a $newQuantity');
      // await _supabaseService.updateCardQuantity(cardId, newQuantity);
    } catch (e) {
      debugPrint('❌ Error en UserCardRepository.updateCardQuantity: $e');
      rethrow;
    }
  }

  /// Elimina una carta de la colección del usuario
  Future<void> removeCardFromCollection(int cardId) async {
    try {
      // Esta funcionalidad necesitaría ser implementada en SupabaseService primero
      debugPrint('🗑️ Eliminando carta $cardId de la colección del usuario');
      // await _supabaseService.removeCardFromCollection(cardId);
    } catch (e) {
      debugPrint('❌ Error en UserCardRepository.removeCardFromCollection: $e');
      rethrow;
    }
  }
}
