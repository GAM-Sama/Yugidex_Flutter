import 'dart:async'; 
import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart'; 

import 'new_cards_list_screen.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets/spinning_card_widget.dart';
import '../services/supabase_service.dart';
import '../models/card_model.dart';

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
  // Sustituimos Timer por StreamSubscription
  StreamSubscription<List<Card>>? _subscription;
  
  int _processedCount = 0;
  String _currentStatusMessage = 'Iniciando proceso...';
  bool _isComplete = false;
  String? _lastCardImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.totalCards > 0) {
      _startListeningToProgress();
    } else {
      _isComplete = true;
      _navigateToNewCardsScreen();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel(); // Cancelamos la escucha al salir
    super.dispose();
  }

  // --- LÓGICA NUEVA: TIEMPO REAL ---
  void _startListeningToProgress() {
    final supabaseService = Provider.of<SupabaseService>(context, listen: false);

    _subscription = supabaseService.streamCardsByJobId(widget.jobId).listen((cards) {
      if (!mounted) return;

      setState(() {
        _processedCount = cards.length;

        // Actualizamos mensaje e imagen con la última carta
        if (cards.isNotEmpty) {
          final lastCard = cards.last;
          _lastCardImageUrl = lastCard.imagen;
          
          if (lastCard.nombre != null && lastCard.nombre!.contains('⚠️')) {
             _currentStatusMessage = 'Error procesando una carta...';
          } else {
             _currentStatusMessage = 'Buscando ${lastCard.nombre ?? "..."}...';
          }
        }
      });

      // Verificamos si ha terminado
      if (_processedCount >= widget.totalCards) {
        _subscription?.cancel();
        
        setState(() {
          _isComplete = true;
          _currentStatusMessage = '¡Lote completado!';
        });
        
        _navigateToNewCardsScreen();
      }
    }, onError: (error) {
      debugPrint("Error stream: $error");
      // No mostramos error en UI para no romper diseño, solo log
    });
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

  // --- TU INTERFAZ ORIGINAL (SIN CAMBIOS ESTRUCTURALES) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              
              // 1. ESPACIO SUPERIOR
              const Spacer(flex: 2), 

              // TÍTULO
              Text(
                "Identificando Cartas...",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              // 2. ESPACIO
              const Spacer(flex: 1),

              // CARTA GIRATORIA
              SizedBox(
                width: 75,
                height: 110,
                child: SpinningFlipCardWidget(
                  frontImage: currentCardImage,
                ),
              ),

              // 3. ESPACIO
              const Spacer(flex: 1), 

              // BARRA DE PROGRESO
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: widget.totalCards == 0
                        ? 1.0
                        : (_processedCount / widget.totalCards).clamp(0.0, 1.0),
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

              // 4. ESPACIO
              const Spacer(flex: 1),

              // ZONA DE MENSAJES
              Container(
                alignment: Alignment.center,
                height: 80, 
                child: _isComplete
                    ? 
                    // COMPLETADO
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
                    // PROCESANDO
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

              // 5. ESPACIO INFERIOR
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}