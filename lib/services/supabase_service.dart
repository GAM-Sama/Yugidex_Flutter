import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart'; // Reutilizamos nuestro modelo de carta

class SupabaseService {
  // Obtenemos el cliente de Supabase que inicializamos en main.dart
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene la lista COMPLETA de cartas desde la tabla de Supabase.
  Future<List<Card>> getCards() async {
    try {
      // 1. Hacemos la consulta a la tabla 'Cartas'.
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

  // --- MÉTODO NUEVO AÑADIDO AQUÍ ---
  /// Obtiene solo las cartas que coinciden con un jobId específico.
  Future<List<Card>> getCardsByJobId(String jobId) async {
    try {
      final response = await _client
          .from('lotes_procesados') // <-- USA TU TABLA 'Cartas'
          .select()
          .eq(
            'job_id',
            jobId,
          ) // Esta es la línea clave que filtra por el job_id
          .order(
            'Nombre',
            ascending: true,
          ); // Ordena alfabéticamente por nombre

      final List<dynamic> data = response as List<dynamic>;
      debugPrint(
        '✅ Se han obtenido ${data.length} cartas para el job_id $jobId.',
      );
      return data.map((json) => Card.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error en SupabaseService.getCardsByJobId: $e');
      throw 'No se pudieron cargar las cartas para el lote: $jobId';
    }
  }
}
