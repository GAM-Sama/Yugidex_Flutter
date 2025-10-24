import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_cards_list_screen.dart';

// ⬇️ 1. IMPORTAR EL TEMA Y EL NUEVO WIDGET
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
  
  // ⬇️ 2. VARIABLE DE ESTADO PARA LA IMAGEN DE LA CARTA
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
      final url = Uri.parse(
        "https://primary-production-6c347.up.railway.app/webhook/progress?jobId=${widget.jobId}",
      );
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
              
              // ⬇️ 3. AQUÍ CAPTURAMOS LA URL DE LA IMAGEN
              // !!! REVISA QUE EL CAMPO SE LLAME 'imageUrl' !!!
              final String? imageUrl = lastCardData['url'] as String?;
              if (imageUrl != null) {
                _lastCardImageUrl = imageUrl;
              }
              // ---
              
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
    // ⬇️ 4. OBTENEMOS EL TEMA
    final theme = Theme.of(context);

    // ⬇️ 5. LÓGICA PARA DECIDIR QUÉ IMAGEN MOSTRAR
    final ImageProvider currentCardImage;
    if (_lastCardImageUrl != null) {
      currentCardImage = NetworkImage(_lastCardImageUrl!);
    } else {
      // Usa tu placeholder si aún no hay imagen
      currentCardImage = const AssetImage('lib/assets/card_placeholder.png');
    }

    return Scaffold(
      // ⬇️ 6. APLICAMOS LOS ESTILOS DEL TEMA
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // El tema ya se aplica solo (color, elevación)
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Usamos el placeholder como un logo temporal
            Image.asset('lib/assets/card_placeholder.png', width: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Yu-Gi-Oh! Scanner', // <-- Puedes cambiar esto
              style: theme.textTheme.titleMedium, // <-- Estilo del Tema
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined), // <-- El color lo da el tema
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl), // <-- Espaciado del Tema
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Identificando Cartas...",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary, // <-- Color del Tema (Amarillo)
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ⬇️ 7. AQUÍ VA LA CARTA GIRATORIA
                SizedBox(
                  width: 75, // Ajusta el tamaño como veas
                  child: SpinningFlipCardWidget(
                    frontImage: currentCardImage,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // ---

                LinearProgressIndicator(
                  value:
                      widget.totalCards == 0
                          ? 1.0
                          : _processedCount / widget.totalCards,
                  minHeight: 20,
                  borderRadius: BorderRadius.circular(AppSpacing.sm), // <-- Tema
                  backgroundColor: AppColors.surface, // <-- Tema
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary, // <-- Tema
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "Procesando carta $_processedCount de ${widget.totalCards}...",
                  style: theme.textTheme.bodyMedium, // <-- Tema
                ),

                SizedBox(
                  height: 50,
                  child: Center(
                    child:
                        !_isComplete && _currentStatusMessage.isNotEmpty
                            ? Text(
                                _currentStatusMessage,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary, // <-- Tema
                                ),
                                textAlign: TextAlign.center,
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                
                if (!_isComplete)
                  Text(
                    "Esto puede tardar unos segundos.\n¡No cierres la Aplicación!",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium, // <-- Tema
                  ),
                  
                if (_isComplete)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success, // <-- Tema
                          size: 60,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '¡Proceso Completado!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.success, // <-- Tema
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