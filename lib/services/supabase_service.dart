import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your models
import '../models/card_model.dart';
import '../models/user_card_model.dart'; // Ensure this model exists and path is correct

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches the COMPLETE list of cards from the Supabase table.
  /// Useful for a general catalog, not a user's collection.
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

  /// Fetches only the cards processed in a specific batch (without user filtering).
  /// This method gets cards directly from the 'lotes_procesados' table.
  Future<List<Card>> getCardsByJobId(String jobId) async {
    try {
      print('🔥 SupabaseService - getCardsByJobId started for jobId: $jobId');
      // Fetch processed card data directly from lotes_procesados
      final response = await _client
          .from('lotes_procesados')
          .select()
          .eq('job_id', jobId);

      // Handle potential null response or incorrect type
      final lotData = response as List<dynamic>? ?? [];
      print('🔥 SupabaseService - Data received from lotes_procesados: ${lotData.length} records');

      if (lotData.isEmpty) {
        print('⚠️ SupabaseService - No data in lotes_procesados for jobId: $jobId');
        return [];
      }

      // Create Card objects directly from lotes_procesados data
      final cardList = lotData.map((itemMap) {
        // Ensure itemMap is a Map before proceeding
        if (itemMap is! Map<String, dynamic>) {
           print('❌ SupabaseService - Invalid item format in lotes_procesados: $itemMap');
           return null; // Skip invalid items
        }
        final item = itemMap;
        try {
          // Parse fields safely, handling potential type mismatches
          return Card(
            idCarta: item['ID_Carta']?.toString() ?? '',
            cantidad: 1, // Default quantity for processed cards display
            nombre: item['Nombre']?.toString(),
            imagen: item['Imagen']?.toString(),
            marcoCarta: item['Marco_Carta']?.toString(),
            tipo: item['Tipo']?.toString(),
            // Safely handle Subtipo which might be List or String
            subtipo: (item['Subtipo'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? (item['Subtipo'] != null ? [item['Subtipo'].toString()] : null),
            atributo: item['Atributo']?.toString(),
            clasificacion: item['Clasificacion']?.toString(),
            // Simplify description parsing
            descripcion: item['Descripcion'] != null ? {'texto': item['Descripcion'].toString()} : null,
            atk: item['ATK']?.toString(),
            def: item['DEF']?.toString(),
            // Safely parse nivelRankLink as int, handling String or int
            nivelRankLink: item['Nivel_Rank_Link'] is int
                ? item['Nivel_Rank_Link']
                : (item['Nivel_Rank_Link'] is String ? int.tryParse(item['Nivel_Rank_Link']) : null),
            // Ensure ratioEnlace is int
            ratioEnlace: item['ratio_enlace'] is int ? item['ratio_enlace'] : null,
            // Safely handle Rareza which might be List or String
            rareza: (item['Rareza'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? (item['Rareza'] != null ? [item['Rareza'].toString()] : null),
            setExpansion: item['Set_Expansion']?.toString(),
            iconoCarta: item['Icono Carta']?.toString() ?? item['icono_carta']?.toString(),
          );
        } catch(e) {
            print('❌ SupabaseService - Error parsing item into Card: $e');
            print('❌ Problematic item data: $item');
            return null; // Skip items that fail parsing
        }
      }).whereType<Card>().toList(); // Filter out any nulls from parsing errors

      debugPrint('✅ SupabaseService - Fetched ${cardList.length} valid processed cards for job_id $jobId.');
      return cardList;
    } catch (e) {
      debugPrint('❌ SupabaseService - Error fetching processed cards by job_id: $e');
      // Rethrow a more specific exception
      throw Exception('Failed to load processed cards for job $jobId.');
    }
  }


  /// Fetches the personal card collection of the currently logged-in user.
  Future<List<UserCard>> getMyCardCollection() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ Cannot get collection: no logged-in user.');
      // Consider throwing an AuthException or returning an empty list based on app logic
      return [];
      // throw Exception('User not authenticated.');
    }

    try {
      // Perform a join to get data from both user_cards and the related Cartas entry.
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

       // Explicitly cast to List<Map<String, dynamic>> for type safety
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response as List);

      print('✅ Supabase getMyCardCollection response: ${data.length} items');
      if (data.isNotEmpty) print('✅ First response item sample: ${data.first}');

      final cardList = data
          // Ensure the 'Cartas' join object exists and is a map
          .where((item) => item['Cartas'] != null && item['Cartas'] is Map<String, dynamic>)
          .map((item) {
            try {
              // UserCard.fromJson handles parsing the nested 'Cartas' object
              return UserCard.fromJson(item);
            } catch (e) {
               print('❌ Error creating UserCard from item in getMyCardCollection: $e');
               print('❌ Problematic item data: $item');
               // Return null to filter out problematic items later
               return null;
            }
          })
          .whereType<UserCard>() // Filter out any nulls resulted from parsing errors
          .toList();

      debugPrint('✅ Fetched ${cardList.length} valid cards for user $userId.');
      return cardList;
    } catch (e, stacktrace) { // Catch stacktrace for debugging
      debugPrint('❌ Error getting user card collection: $e');
      debugPrint('❌ Stack trace: $stacktrace');
      // Rethrow a more specific exception
      throw Exception('Failed to load user collection from database.');
    }
  }

  /// Adds a card to the current user's collection.
  Future<void> addCardToMyCollection({
    required int cardId, // The id from the 'Cartas' table
    int quantity = 1,
    String condition = 'mint', // Default condition
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
       debugPrint('⚠️ Cannot add card: no logged-in user.');
       throw Exception('User not authenticated.');
    }

    try {
      // Assumes your 'user_cards' table columns are named correctly
      await _client.from('user_cards').insert({
        'user_id': userId,
        'carta_id': cardId, // Foreign key to 'Cartas' table
        'cantidad': quantity,
        'condition': condition,
        'notes': notes,
        // 'acquired_date' likely defaults to now() in the database
      });
      debugPrint('✅ Card with id $cardId added to collection for user $userId.');
    } catch (e) {
      debugPrint('❌ Error adding card to collection: $e');
      // Rethrow for the ViewModel to handle
      throw Exception('Failed to add card to collection: ${e.toString()}');
    }
  }

  // --- NEW METHOD TO DELETE/UPDATE QUANTITY ---
  /// Deletes or updates the quantity of a specific card entry in the user's collection.
  Future<void> deleteOrUpdateUserCardQuantity({
    required String userCardId, // The 'id' (UUID) from the 'user_cards' table
    required int quantityToDelete,
    required int currentQuantity,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    try {
      if (quantityToDelete >= currentQuantity) {
        // --- DELETE THE ROW ---
        print('🔥 SupabaseService - Deleting user_card with id: $userCardId');
        final response = await _client
            .from('user_cards')
            .delete()
            .eq('id', userCardId) // Ensure 'id' is your primary key for user_cards
            .eq('user_id', userId); // Security check

        // Optional: Check response if needed, Supabase delete doesn't return data by default
        print('✅ SupabaseService - Row deleted.');

      } else {
        // --- UPDATE QUANTITY ---
        final newQuantity = currentQuantity - quantityToDelete;
        print('🔥 SupabaseService - Updating quantity of user_card $userCardId to: $newQuantity');
        final response = await _client
            .from('user_cards')
            .update({'cantidad': newQuantity})
            .eq('id', userCardId)
            .eq('user_id', userId)
            .select(); // Select to confirm update if needed

        // Optional: Check response if needed
        print('✅ SupabaseService - Quantity updated. Response: $response');
      }
    } on PostgrestException catch (e) {
      // Catch specific Supabase errors
      debugPrint('❌ Supabase error deleting/updating quantity: ${e.message}');
      debugPrint('❌ Error code: ${e.code}');
      debugPrint('❌ Details: ${e.details}');
      // Provide a more user-friendly message or rethrow specific error type
      throw Exception('Error updating collection in database: ${e.message}');
    } catch (e) {
      // Catch any other unexpected errors
      debugPrint('❌ Unexpected error deleting/updating quantity: $e');
      throw Exception('Unexpected error updating collection.');
    }
  }
  // --- END NEW METHOD ---
}