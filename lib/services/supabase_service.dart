import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart'; // Reutilizamos nuestro modelo de carta

class SupabaseService {
  // Obtenemos el cliente de Supabase que inicializamos en main.dart
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene la lista de cartas desde la tabla de Supabase.
  Future<List<Card>> getCards() async {
    try {
      // 1. Hacemos la consulta a la tabla 'nombre_de_tu_tabla'.
      // ¡Asegúrate de que el nombre de la tabla sea el correcto!
      final List<Map<String, dynamic>> data =
          await _client.from('Cartas').select();

      // 2. Comprobamos si la respuesta no está vacía.
      if (data.isNotEmpty) {
        // 3. Convertimos la lista de mapas a una lista de objetos Card.
        final cards = data.map((item) => Card.fromJson(item)).toList();
        debugPrint('✅ Se han obtenido ${cards.length} cartas de Supabase.');
        return cards;
      }

      // Si no hay datos, devolvemos una lista vacía.
      return [];
    } catch (e) {
      debugPrint('❌ Error en SupabaseService: $e');
      // Relanzamos la excepción para que el ViewModel la pueda manejar.
      throw Exception('Fallo al cargar las cartas desde Supabase.');
    }
  }
}
