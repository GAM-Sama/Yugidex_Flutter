import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_cards_list_screen.dart';

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
  // MODIFICADO: Usamos una variable más genérica para el mensaje de estado.
  String _currentStatusMessage = 'Iniciando proceso...';
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.totalCards > 0) {
      _checkProgress();
    } else {
      _isComplete = true;
      _navigateToNewCardsScreen();
    }
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isComplete) {
        _checkProgress();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkProgress() async {
    try {
      final url = Uri.parse(
        "https://primary-production-6c347.up.railway.app/webhook/progress?jobId=${widget.jobId}",
      );
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
      };
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && mounted) {
        if (response.body.isEmpty) return;

        final data = jsonDecode(response.body);
        final int processed = data['processed'] as int? ?? 0;
        final lastCardData = data['lastProcessedCard'] as Map<String, dynamic>?;

        // --- LÓGICA MODIFICADA PARA INTERPRETAR LA NUEVA RESPUESTA ---
        setState(() {
          _processedCount = processed;
          if (lastCardData != null) {
            final bool success = lastCardData['success'] as bool? ?? false;
            final String code = lastCardData['code'] ?? 'desconocido';

            if (success) {
              final String name = lastCardData['name'] ?? 'desconocido';
              _currentStatusMessage = 'Buscando ${name}...';
            } else {
              _currentStatusMessage = 'No se encontró info para ${code}...';
            }
          }
        });
        // --- FIN DE LA LÓGICA MODIFICADA ---

        if (_processedCount >= widget.totalCards) {
          _pollingTimer?.cancel();
          setState(() {
            _isComplete = true;
          });
          _navigateToNewCardsScreen();
        }
      } else {
        throw Exception(
          'Error en la respuesta del servidor: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint("Error consultando progreso: $e");
      _pollingTimer?.cancel();
      // MODIFICADO: Actualizamos la nueva variable en caso de error
      setState(() {
        _currentStatusMessage = 'Error de conexión con el servidor.';
      });
    }
  }

  void _navigateToNewCardsScreen() {
    print('🔥 ProcessingScreen - _navigateToNewCardsScreen iniciado');
    if (!mounted) {
      print('❌ ProcessingScreen - Widget no está montado');
      return;
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        print('🔥 ProcessingScreen - Navegando a NewCardsListScreen con jobId: ${widget.jobId}');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NewCardsListScreen(jobId: widget.jobId),
          ),
        );
        print('✅ ProcessingScreen - Navegación completada');
      } else {
        print('❌ ProcessingScreen - Widget no está montado durante navegación');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(backgroundColor: Colors.lightBlue, radius: 16),
            SizedBox(width: 8),
            Text(
              'Nombre y logo App',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Identificando Cartas...",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 30),
                LinearProgressIndicator(
                  value:
                      widget.totalCards == 0
                          ? 1.0
                          : _processedCount / widget.totalCards,
                  minHeight: 20,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: Colors.grey[700],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.lightBlue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Procesando carta $_processedCount de ${widget.totalCards}...",
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),

                // --- WIDGET DE TEXTO MODIFICADO ---
                SizedBox(
                  height: 50,
                  child: Center(
                    child:
                        !_isComplete && _currentStatusMessage.isNotEmpty
                            ? Text(
                              _currentStatusMessage, // <-- Ahora solo muestra el mensaje de estado
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            )
                            : const SizedBox.shrink(),
                  ),
                ),

                // --- FIN DE LA MODIFICACIÓN ---
                const SizedBox(height: 20),
                if (!_isComplete)
                  const Text(
                    "Esto puede tardar unos segundos.\n¡No cierres la Aplicación!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (_isComplete)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '¡Proceso Completado!',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
