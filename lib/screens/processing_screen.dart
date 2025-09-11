import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// PANTALLA DE PROGRESO CON POLLING
class ProcessingScreen extends StatefulWidget {
  final String jobId;
  final int totalCards;

  const ProcessingScreen({
    super.key,
    required this.jobId,
    required this.totalCards,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  Timer? _pollingTimer;
  int _processedCount = 0;
  String _statusMessage = "Iniciando proceso...";
  List<Map<String, dynamic>> _processedCardsData = [];

  @override
  void initState() {
    super.initState();
    _checkProgress(); // Hacemos una llamada inicial inmediata
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkProgress(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkProgress() async {
    // Si ya hemos terminado, no hacemos más llamadas
    if (_processedCount >= widget.totalCards) {
      _pollingTimer?.cancel();
      return;
    }

    try {
      // Reemplaza esta URL por la de tu NUEVO webhook de progreso
      final url = Uri.parse(
        "https://primary-production-6c347.up.railway.app/webhook/progress?jobId=${widget.jobId}",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          // n8n debe devolver un número en 'processed' y una lista en 'results'
          _processedCount = data['processed'] ?? _processedCount;
          _processedCardsData = List<Map<String, dynamic>>.from(
            data['results'] ?? [],
          );
          _statusMessage =
              "Procesando... ($_processedCount/${widget.totalCards})";
        });

        // Si hemos terminado, cancelamos el timer y navegamos.
        if (_processedCount >= widget.totalCards) {
          _pollingTimer?.cancel();
          setState(() {
            _statusMessage = "¡Proceso completado!";
          });
          await Future.delayed(const Duration(seconds: 1)); // Pequeña pausa
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => BatchResultScreen(addedCards: _processedCardsData),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error consultando progreso: $e");
      setState(() {
        _statusMessage = "Error de conexión al consultar progreso...";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.totalCards == 0 ? 0.0 : _processedCount / widget.totalCards;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Procesando Lote...",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[300],
                ),
              ),
              const SizedBox(height: 30),
              LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                minHeight: 20,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "$_processedCount de ${widget.totalCards} cartas procesadas",
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              const Text(
                "Esto puede tardar unos segundos.\n¡No cierres la aplicación!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PANTALLA DE RESULTADOS DEL LOTE
class BatchResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> addedCards;

  const BatchResultScreen({super.key, required this.addedCards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lote Procesado (${addedCards.length} cartas)"),
        backgroundColor: Colors.grey[900],
      ),
      body: ListView.builder(
        itemCount: addedCards.length,
        itemBuilder: (context, index) {
          final card = addedCards[index];
          final hasError = card.containsKey('error');

          return ListTile(
            leading:
                hasError
                    ? const Icon(Icons.error, color: Colors.red)
                    : const Icon(Icons.check_circle, color: Colors.green),
            title: Text(card['title'] ?? card['code'] ?? 'Desconocido'),
            subtitle: Text(
              hasError
                  ? card['error'].toString()
                  : 'Añadida o actualizada en la colección',
            ),
          );
        },
      ),
    );
  }
}
