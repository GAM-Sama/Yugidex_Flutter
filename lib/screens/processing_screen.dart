import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_cards_list_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ⬇️ IMPORTACIONES DE TU PROYECTO
import '../core/theme/app_theme.dart';
import '../shared/widgets/spinning_card_widget.dart';

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
  String _currentStatusMessage = 'Iniciando proceso...';
  bool _isComplete = false;
  
  // Variable para la imagen dinámica
  String? _lastCardImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.totalCards > 0) {
      _checkProgress(); // Primera comprobación inmediata
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!_isComplete) {
          _checkProgress();
        }
      });
    } else {
      _isComplete = true;
      _navigateToNewCardsScreen();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkProgress() async {
    try {
      // --- Cargar URL completa del .env ---
      // (Asumimos que en el .env tienes la ruta completa hasta /progress)
      final baseUrl = dotenv.env['PROCESS_URL'] ?? '';
      
      if (baseUrl.isEmpty) {
        debugPrint('⚠️ ERROR: La variable PROCESS_URL no está definida en el .env');
        throw Exception('Falta configuración de entorno');
      }

      // Añadimos solo el parámetro jobId
      final url = Uri.parse("$baseUrl?jobId=${widget.jobId}");

      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
      };
      
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && mounted) {
        if (response.body.isEmpty) return;

        final data = jsonDecode(response.body);
        debugPrint('RESPUESTA DE LA API: $data');
        final int processed = data['processed'] as int? ?? 0;
        final lastCardData = data['lastProcessedCard'] as Map<String, dynamic>?;

        setState(() {
          _processedCount = processed;
          if (lastCardData != null) {
            final bool success = lastCardData['success'] as bool? ?? false;
            final String code = lastCardData['code'] ?? 'desconocido';

            if (success) {
              final String name = lastCardData['name'] ?? 'desconocido';
              _currentStatusMessage = 'Buscando $name...';
              
              // Capturamos URL de la imagen
              final String? imageUrl = lastCardData['url'] as String?;
              if (imageUrl != null) {
                _lastCardImageUrl = imageUrl;
              }
              
            } else {
              _currentStatusMessage = 'No se encontró info para $code...';
            }
          }
        });

        if (_processedCount >= widget.totalCards) {
          _pollingTimer?.cancel();
          setState(() {
            _isComplete = true;
            _currentStatusMessage = '¡Lote completado!';
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
      setState(() {
        _currentStatusMessage = 'Error de conexión con el servidor.';
      });
    }
  }

  void _navigateToNewCardsScreen() {
    if (!mounted) return;
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NewCardsListScreen(jobId: widget.jobId),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Decidir imagen: red o asset
    final ImageProvider currentCardImage;
    if (_lastCardImageUrl != null) {
      currentCardImage = NetworkImage(_lastCardImageUrl!);
    } else {
      currentCardImage = const AssetImage('assets/card_placeholder.png');
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, 
            vertical: AppSpacing.sm
          ),
          child: Column(
            children: [
              
              // ⬇️ 1. ESPACIO SUPERIOR (Empuja todo hacia abajo)
              const Spacer(flex: 2), 

              // --- TÍTULO ---
              Text(
                "Identificando Cartas...",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              // ⬇️ 2. Espacio entre Título y Carta
              const Spacer(flex: 1),

              // --- CARTA GIRATORIA ---
              SizedBox(
                width: 75,
                height: 110,
                child: SpinningFlipCardWidget(
                  frontImage: currentCardImage,
                ),
              ),

              // ⬇️ 3. ESPACIO CLAVE: Separa la carta de la barra
              const Spacer(flex: 1), 

              // --- BARRA DE PROGRESO ---
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: widget.totalCards == 0
                        ? 1.0
                        : _processedCount / widget.totalCards,
                    minHeight: 20,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Procesando carta $_processedCount de ${widget.totalCards}...",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),

              // ⬇️ 4. Espacio entre Barra y Textos finales
              const Spacer(flex: 1),

              // --- ZONA DE MENSAJES ---
              Container(
                alignment: Alignment.center,
                // Altura fija para reservar espacio y evitar saltos
                height: 80, 
                child: _isComplete
                    ? 
                    // 🟢 COMPLETADO
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 40, 
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¡Proceso Completado!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : 
                    // 🟠 PROCESANDO
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentStatusMessage.isNotEmpty)
                            Text(
                              _currentStatusMessage,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            "Esto puede tardar unos segundos.\n¡No cierres la Aplicación!",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14), 
                          ),
                        ],
                      ),
              ),

              // ⬇️ 5. ESPACIO INFERIOR (Equilibra con el de arriba)
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}