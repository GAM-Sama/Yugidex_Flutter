import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- CAMBIO 1: Importamos dotenv
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- CAMBIO 2: Importamos Supabase para la sesión

class WebhookService {
  // CAMBIO 3: Leemos la URL desde las variables de entorno.
  // Usamos 'late final' para asegurarnos de que se inicializa una vez y no cambia.
  late final String _webhookUrl;

  WebhookService() {
    // Leemos la variable en el constructor. Si no existe, la app fallará al arrancar
    // lo cual es bueno, porque nos avisa del problema inmediatamente.
    _webhookUrl = dotenv.env['N8N_WEBHOOK_URL']!;
  }

  Future<String?> sendCodes(List<String> codes) async {
    if (codes.isEmpty) return null;

    // CAMBIO 4: Obtenemos la sesión actual del usuario para acceder al token.
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      debugPrint("⚠️ No se pueden enviar códigos: no hay sesión de usuario activa.");
      return null;
    }
    final accessToken = session.accessToken;

    try {
      // CAMBIO 5: Añadimos el token a las cabeceras de la petición.
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken", // Formato estándar para JWT
      };

      // El cuerpo de la petición se mantiene igual.
      final body = jsonEncode({
        "codes": codes,
        "timestamp": DateTime.now().toIso8601String(),
      });

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: headers, // Usamos las nuevas cabeceras
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobId = data['jobId'] as String?;
        debugPrint("✅ Lote iniciado en n8n con Job ID: $jobId para el usuario ${session.user.id}");
        return jobId;
      } else {
        debugPrint(
          "❌ Error al enviar el lote: ${response.statusCode} - ${response.body}",
        );
        return null;
      }
    } catch (e) {
      debugPrint("❌ Excepción en WebhookService: $e");
      return null;
    }
  }
}
