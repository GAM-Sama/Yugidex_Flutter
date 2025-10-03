import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Asumo que tienes un modelo para la carta en sí (Card) y otro para la
// carta en la colección del usuario (UserCard), que puede incluir detalles como cantidad, condición, etc.
import '../models/card_model.dart';
import '../models/user_card_model.dart'; // Necesitarás crear este modelo

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- MÉTODOS EXISTENTES (NO SE TOCAN) ---

  /// Obtiene la lista COMPLETA de cartas desde la tabla de Supabase.
  /// Útil para un catálogo general, no para la colección de un usuario.
  Future<List<Card>> getCards() async {
    try {
      final List<Map<String, dynamic>> data =
          await _client.from('Cartas').select();

      if (data.isNotEmpty) {
        final cards = data.map((item) => Card.fromJson(item)).toList();
        debugPrint('✅ Se han obtenido ${cards.length} cartas de Supabase.');
        return cards;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error en SupabaseService.getCards: $e');
      throw Exception('Fallo al cargar las cartas desde Supabase.');
    }
  }

  /// Obtiene solo las cartas que coinciden con un jobId específico.
  Future<List<Card>> getCardsByJobId(String jobId) async {
    try {
      final response = await _client
          .from('lotes_procesados')
          .select()
          .eq('job_id', jobId)
          .order('Nombre', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      debugPrint('✅ Se han obtenido ${data.length} cartas para el job_id $jobId.');
      return data.map((json) => Card.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error en SupabaseService.getCardsByJobId: $e');
      throw 'No se pudieron cargar las cartas para el lote: $jobId';
    }
  }

  // --- NUEVOS MÉTODOS PARA LA COLECCIÓN DEL USUARIO ---

  /// Obtiene la colección de cartas personal del usuario que ha iniciado sesión.
  Future<List<UserCard>> getMyCardCollection() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ No se puede obtener la colección: no hay usuario logueado.');
      return [];
    }

    try {
      // Hacemos un join para obtener los datos de la carta y de la colección del usuario.
      final response = await _client
          .from('user_cards')
          .select('''
            id,
            cantidad,
            condition,
            notes,
            acquired_date,
            Cartas ( * )
          ''')
          .eq('user_id', userId);

      final cardList = (response as List)
          .map((item) => UserCard.fromJson(item))
          .toList();
      debugPrint('✅ Obtenidas ${cardList.length} cartas para el usuario $userId.');
      return cardList;
    } catch (e) {
      debugPrint('❌ Error al obtener la colección de cartas del usuario: $e');
      return [];
    }
  }

  /// Añade una carta a la colección del usuario actual.
  Future<void> addCardToMyCollection({
    required int cardId, // El id de la tabla 'Cartas'
    int quantity = 1,
    String condition = 'mint',
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
       debugPrint('⚠️ No se puede añadir la carta: no hay usuario logueado.');
       return;
    }

    try {
      await _client.from('user_cards').insert({
        'user_id': userId,
        'carta_id': cardId,
        'cantidad': quantity,
        'condition': condition,
        'notes': notes,
      });
      debugPrint('✅ Carta con id $cardId añadida a la colección del usuario $userId.');
    } catch (e) {
      debugPrint('❌ Error al añadir la carta a la colección: $e');
      rethrow;
    }
  }
}