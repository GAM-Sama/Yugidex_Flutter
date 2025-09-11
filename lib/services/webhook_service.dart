import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WebhookService {
  // Mantenemos tu URL actualizada. Apunta al workflow principal.
  static const String _webhookUrl =
      "https://primary-production-6c347.up.railway.app/webhook-test/67ac33b8-be5a-448a-b389-43869a4819d0";

  // --- MÉTODO MODIFICADO ---
  // Antes devolvía: Future<bool>
  // Ahora devuelve: Future<String?> (una promesa de un String, que puede ser nulo)
  Future<String?> sendCodes(List<String> codes) async {
    if (codes.isEmpty) return null;

    try {
      // Esta parte es idéntica, seguimos enviando el lote de códigos
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "codes": codes,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );

      // --- AQUÍ ESTÁ EL CAMBIO ---
      if (response.statusCode == 200) {
        // La petición fue exitosa. Ahora, en lugar de devolver 'true',
        // leemos la respuesta para encontrar el jobId.
        final data = jsonDecode(response.body);
        final jobId = data['jobId'] as String?; // Extraemos el jobId
        debugPrint("✅ Lote iniciado en n8n con Job ID: $jobId");
        return jobId; // Devolvemos el jobId
      } else {
        // Si el servidor falla, no hay jobId, así que devolvemos null.
        debugPrint(
          "Error al enviar el lote: ${response.statusCode} - ${response.body}",
        );
        return null;
      }
    } catch (e) {
      // Si la conexión falla, también devolvemos null.
      debugPrint("Excepción en WebhookService: $e");
      return null;
    }
  }
}
