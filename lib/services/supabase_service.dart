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

  /// Obtiene solo las cartas del usuario actual que coinciden con un jobId específico.
  /// Nota: Este método NO se usa para cartas procesadas, solo para la colección permanente del usuario.
  Future<List<UserCard>> getMyCardsByJobId(String jobId) async {
    // Este método no es necesario para el flujo de cartas procesadas
    // Las cartas procesadas se muestran directamente desde lotes_procesados
    debugPrint('⚠️ getMyCardsByJobId no se usa para cartas procesadas');
    return [];
  }

  /// Obtiene solo las cartas procesadas en un lote específico (sin filtrar por usuario).
  /// Este método obtiene las cartas directamente desde la tabla 'lotes_procesados'.
  Future<List<Card>> getCardsByJobId(String jobId) async {
    try {
      print('🔥 SupabaseService - getCardsByJobId iniciado para jobId: $jobId');
      // Obtenemos directamente los datos de cartas procesadas desde lotes_procesados
      final response = await _client
          .from('lotes_procesados')
          .select()
          .eq('job_id', jobId);

      final lotData = response as List<dynamic>;
      print('🔥 SupabaseService - Datos recibidos de lotes_procesados: ${lotData.length} registros');

      if (lotData.isEmpty) {
        print('⚠️ SupabaseService - No hay datos en lotes_procesados para jobId: $jobId');
        return [];
      }

      // Crear objetos Card directamente desde los datos de lotes_procesados
      final cardList = lotData.map((item) {
        // DEBUG: Ver qué campos están llegando
        debugPrint('=== DEBUG ITEM FROM LOTES_PROCESADOS ===');
        debugPrint('Item keys: ${(item as Map<String, dynamic>).keys.toList()}');
        debugPrint('ATK field: "${item['ATK']}" (type: ${item['ATK']?.runtimeType})');
        debugPrint('DEF field: "${item['DEF']}" (type: ${item['DEF']?.runtimeType})');
        debugPrint('Nivel_Rank_Link field: "${item['Nivel_Rank_Link']}" (type: ${item['Nivel_Rank_Link']?.runtimeType})');
        debugPrint('Tipo field: "${item['Tipo']}" (type: ${item['Tipo']?.runtimeType})');
        debugPrint('Subtipo field: "${item['Subtipo']}" (type: ${item['Subtipo']?.runtimeType})');
        debugPrint('Atributo field: "${item['Atributo']}" (type: ${item['Atributo']?.runtimeType})');
        debugPrint('Marco_Carta field: "${item['Marco_Carta']}" (type: ${item['Marco_Carta']?.runtimeType})');

        return Card(
          idCarta: item['ID_Carta']?.toString() ?? '',
          cantidad: item['Cantidad'] as int? ?? 1,
          nombre: item['Nombre']?.toString(),
          imagen: item['Imagen']?.toString(),
          marcoCarta: item['Marco_Carta']?.toString(),
          tipo: item['Tipo']?.toString(),
          subtipo: item['Subtipo'] != null ? [item['Subtipo'].toString()] : null,
          atributo: item['Atributo']?.toString(),
          descripcion: item['Descripcion'] != null ? {'texto': item['Descripcion'].toString()} : null,
          atk: item['ATK']?.toString(),
          def: item['DEF']?.toString(),
          nivelRankLink: item['Nivel_Rank_Link'] as int?,
          ratioEnlace: item['ratio_enlace'] as int?,
          rareza: item['Rareza'] != null ? [item['Rareza'].toString()] : null,
          setExpansion: item['Set_Expansion']?.toString(),
          iconoCarta: item['Icono Carta']?.toString(),
        );
      }).toList();

      debugPrint('✅ SupabaseService - Obtenidas ${cardList.length} cartas procesadas para el job_id $jobId.');
      return cardList;
    } catch (e) {
      debugPrint('❌ SupabaseService - Error al obtener las cartas procesadas por job_id: $e');
      return [];
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

      final List<dynamic> data = response as List<dynamic>;
      print('✅ Respuesta de Supabase: ${data.length} elementos');

      // Log detallado del primer elemento para debugging
      if (data.isNotEmpty) {
        print('✅ Primer elemento de respuesta: ${data.first}');
        // También vamos a ver qué contiene el objeto Cartas dentro del primer elemento
        final firstItem = data.first as Map<String, dynamic>;
        print('✅ Keys del primer elemento: ${firstItem.keys.toList()}');
        if (firstItem.containsKey('Cartas') && firstItem['Cartas'] != null) {
          print('✅ Objeto Cartas del primer elemento: ${firstItem['Cartas']}');
          final cartasObj = firstItem['Cartas'] as Map<String, dynamic>;
          print('✅ Keys del objeto Cartas: ${cartasObj.keys.toList()}');
          print('✅ Valores del objeto Cartas:');
          cartasObj.forEach((key, value) {
            print('  $key: $value (${value.runtimeType})');
          });
        } else {
          print('❌ No se encontró el objeto Cartas en el primer elemento');
        }
      }

      final cardList = data
          .where((item) => item != null && item is Map<String, dynamic>)
          .where((item) => item['Cartas'] != null) // Filtrar solo registros con cartas válidas
          .map((item) {
            try {
              final userCard = UserCard.fromJson(item as Map<String, dynamic>);
              print('✅ UserCard creada correctamente: ${userCard.cardDetails.nombre ?? 'Sin nombre'}');
              return userCard;
            } catch (e) {
              print('❌ Error al crear UserCard desde item: $e');
              print('❌ Item problemático: $item');
              print('❌ Item keys: ${(item as Map<String, dynamic>).keys.toList()}');
              if (item.containsKey('Cartas')) {
                print('❌ Cartas object: ${item['Cartas']}');
                print('❌ Cartas keys: ${(item['Cartas'] as Map<String, dynamic>).keys.toList()}');
              }
              // En lugar de devolver null, vamos a devolver la excepción para que se propague
              throw Exception('Error creando UserCard: $e. Datos: $item');
            }
          })
          .toList();

      debugPrint('✅ Obtenidas ${cardList.length} cartas válidas para el usuario $userId.');
      return cardList;
    } catch (e) {
      debugPrint('❌ Error al obtener la colección de cartas del usuario: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
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