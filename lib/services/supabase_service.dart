import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your models
import '../models/card_model.dart';
import '../models/user_card_model.dart';
import '../models/deck_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ✅ CORRECCIÓN 1: Exponemos el cliente para que otros ViewModels lo usen
  SupabaseClient get client => _client;

  /// Obtiene la lista completa de cartas (Catálogo)
  Future<List<Card>> getCards() async {
    try {
      final List<Map<String, dynamic>> data = await _client.from('Cartas').select();
      if (data.isNotEmpty) {
        final cards = data.map((item) => Card.fromJson(item)).toList();
        debugPrint('✅ Fetched ${cards.length} cards from Supabase.');
        return cards;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error in SupabaseService.getCards: $e');
      throw Exception('Failed to load cards from Supabase.');
    }
  }

  /// Stream para ver las cartas procesadas en tiempo real
  Stream<List<Card>> streamCardsByJobId(String jobId) {
    return _client
        .from('lotes_procesados')
        .stream(primaryKey: ['id'])
        .eq('job_id', jobId)
        .order('id', ascending: true)
        .map((data) {
          return data.map((itemMap) {
            try {
              return Card.fromJson(itemMap);
            } catch (e) {
              return null;
            }
          }).whereType<Card>().toList();
        });
  }

  // (Método antiguo mantenido por compatibilidad si lo usas en otro sitio)
  Future<List<Card>> getCardsByJobId(String jobId) async {
    return []; 
  }

  /// Obtiene la colección del usuario
  Future<List<UserCard>> getMyCardCollection() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('user_cards')
          .select('id, cantidad, condition, notes, acquired_date, Cartas ( * )')
          .eq('user_id', userId);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response as List);

      return data
          .where((item) => item['Cartas'] != null)
          .map((item) {
            try {
              return UserCard.fromJson(item);
            } catch (e) {
              return null;
            }
          })
          .whereType<UserCard>()
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting collection: $e');
      return [];
    }
  }

  /// Añade carta usando RPC
  Future<void> addCardToMyCollection({
    required String cardCode,
    int quantity = 1,
    String condition = 'mint',
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated.');

    try {
      await _client.rpc('upsert_user_card_qty', params: {
        'p_user_id': userId,
        'p_card_code': cardCode,
        'p_qty_to_add': quantity
      });
      debugPrint('✅ Card $cardCode added via RPC.');
    } catch (e) {
      debugPrint('❌ Error adding card: $e');
      throw Exception('Failed to add card: $e');
    }
  }

  /// Borrar o actualizar cantidad
  Future<void> deleteOrUpdateUserCardQuantity({
    required String userCardId,
    required int quantityToDelete,
    required int currentQuantity,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated.');

    try {
      if (quantityToDelete >= currentQuantity) {
        await _client.from('user_cards').delete().eq('id', userCardId).eq('user_id', userId);
      } else {
        final newQuantity = currentQuantity - quantityToDelete;
        await _client.from('user_cards').update({'cantidad': newQuantity}).eq('id', userCardId).eq('user_id', userId);
      }
    } catch (e) {
      debugPrint('❌ Error updating collection: $e');
      throw Exception('Error updating collection.');
    }
  }

  // --- GESTIÓN DE MAZOS ---

  Stream<List<Deck>> streamMyDecks() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('decks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .map((data) => data.map((json) => Deck.fromJson(json)).toList());
  }

  Future<String> generateUniqueDeckName() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no logueado');

    // Obtener todos los decks del usuario
    final response = await _client
        .from('decks')
        .select('name')
        .eq('user_id', userId);
    
    final existingNames = (response as List<dynamic>)
        .map((row) => row['name'] as String)
        .toList();

    // Generar nombre único
    String baseName = "Mi Deck";
    String uniqueName = baseName;
    int counter = 1;

    while (existingNames.contains(uniqueName)) {
      uniqueName = "$baseName $counter";
      counter++;
    }

    return uniqueName;
  }

  Future<void> createDeck(String name, int colorValue) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no logueado');

    await _client.from('decks').insert({
      'user_id': userId,
      'name': name,
      'color': colorValue,
      'main_deck': [],
      'extra_deck': [],
      'side_deck': [],
    });
  }

  Future<void> deleteDeck(String deckId) async {
    await _client.from('decks').delete().eq('id', deckId);
  }
  
  // ✅ CORRECCIÓN 2: Eliminados los helpers _safeStringList y _parseInt que no se usaban
}