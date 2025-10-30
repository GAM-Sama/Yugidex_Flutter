import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your models
import '../models/card_model.dart';
import '../models/user_card_model.dart';

/// Servicio para interactuar con la base de datos Supabase.
/// Maneja todas las operaciones relacionadas con las cartas y la colección del usuario.
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene la lista completa de cartas desde la tabla 'Cartas' de Supabase.
  /// 
  /// Este método es útil para obtener un catálogo general de cartas, no la colección de un usuario específico.
  /// Retorna una lista de [Card] con todas las cartas disponibles.
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

  /// Obtiene las cartas procesadas en un lote específico (sin filtrar por usuario).
  /// 
  /// Este método obtiene las cartas directamente de la tabla 'lotes_procesados'.
  /// [jobId] El ID del trabajo de procesamiento.
  /// Retorna una lista de [Card] con las cartas del lote especificado.
  Future<List<Card>> getCardsByJobId(String jobId) async {
    try {
      // Fetch processed card data directly from lotes_procesados
      final response = await _client
          .from('lotes_procesados')
          .select()
          .eq('job_id', jobId);

      // Handle potential null response or incorrect type
      final lotData = response as List<dynamic>? ?? [];

      if (lotData.isEmpty) {
        return [];
      }

      // Helper function to safely convert dynamic to List<String>?
      List<String>? safeStringList(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          return value.map((e) => e.toString()).toList();
        }
        return [value.toString()];
      }

      // Create Card objects directly from lotes_procesados data
      final cardList = lotData.map((itemMap) {
        // Ensure itemMap is a Map before proceeding
        if (itemMap is! Map<String, dynamic>) {
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
            // Safely handle Subtipo which might be List, String, or null
            subtipo: safeStringList(item['Subtipo']),
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
            rareza: safeStringList(item['Rareza']),
            setExpansion: item['Set_Expansion']?.toString(),
            iconoCarta: item['Icono Carta']?.toString() ?? item['icono_carta']?.toString(),
          );
        } catch(e) {
            return null; // Skip items that fail parsing
        }
      }).whereType<Card>().toList(); // Filter out any nulls from parsing errors

      return cardList;
    } catch (e) {
      // Rethrow a more specific exception
      throw Exception('Failed to load processed cards for job $jobId.');
    }
  }


  /// Obtiene la colección personal de cartas del usuario actualmente autenticado.
  /// 
  /// Retorna una lista de [UserCard] que representa la colección del usuario.
  /// Si el usuario no está autenticado, retorna una lista vacía.
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


      final cardList = data
          // Ensure the 'Cartas' join object exists and is a map
          .where((item) => item['Cartas'] != null && item['Cartas'] is Map<String, dynamic>)
          .map((item) {
            try {
              // UserCard.fromJson handles parsing the nested 'Cartas' object
              return UserCard.fromJson(item);
            } catch (e) {
               // Return null to filter out problematic items
               return null;
            }
          })
          .whereType<UserCard>() // Filter out any nulls resulted from parsing errors
          .toList();

      debugPrint('✅ Fetched ${cardList.length} valid cards for user $userId.');
      return cardList;
    } catch (e) {
      debugPrint('❌ Error getting user card collection: $e');
      // Rethrow a more specific exception
      throw Exception('Failed to load user collection from database.');
    }
  }

  /// Añade una carta a la colección del usuario actual.
  /// 
  /// [cardId] El ID de la carta en la tabla 'Cartas'.
  /// [quantity] Cantidad de copias a añadir (por defecto 1).
  /// [condition] Condición de la carta (por defecto 'mint').
  /// [notes] Notas opcionales sobre la carta.
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

  /// Elimina o actualiza la cantidad de una entrada específica en la colección del usuario.
  /// 
  /// [userCardId] El ID de la entrada en la tabla 'user_cards'.
  /// [quantityToDelete] Cantidad a eliminar.
  /// [currentQuantity] Cantidad actual de la carta en la colección.
  /// 
  /// Si [quantityToDelete] es mayor o igual que [currentQuantity], se eliminará la entrada.
  /// De lo contrario, se actualizará la cantidad restando [quantityToDelete].
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
        await _client
            .from('user_cards')
            .delete()
            .eq('id', userCardId) // Ensure 'id' is your primary key for user_cards
            .eq('user_id', userId); // Security check

      } else {
        // --- UPDATE QUANTITY ---
        final newQuantity = currentQuantity - quantityToDelete;
        await _client
            .from('user_cards')
            .update({'cantidad': newQuantity})
            .eq('id', userCardId)
            .eq('user_id', userId);
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