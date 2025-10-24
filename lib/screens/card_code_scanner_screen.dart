import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../view_models/card_scanner_view_model.dart';
import '../screens/processing_screen.dart';
import '../core/theme/app_theme.dart';

class CardCodeScannerScreen extends StatefulWidget {
  const CardCodeScannerScreen({super.key});

  @override
  State<CardCodeScannerScreen> createState() => _CardCodeScannerScreenState();
}

class _CardCodeScannerScreenState extends State<CardCodeScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late Future<void> _initCameraFuture;

  final GlobalKey _cameraWidgetKey = GlobalKey();

  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  bool _isFlashOn = false;
  Offset? _focusPoint;
  late AnimationController _focusAnimationController;

  final double _cardAspectRatio = 86 / 59;
  final double _cardCornerRadius = AppSpacing.sm; // 8.0

  @override
  void initState() {
    super.initState();
    _initCameraFuture = _initializeCamera();

    _focusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _showHelpDialog());
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _focusAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initCameraFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done ||
                _cameraController == null ||
                !_cameraController!.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return Consumer<CardScannerViewModel>(
              builder: (context, viewModel, child) {
                return Row(
                  children: [
                    _buildCameraSection(viewModel, theme),
                    _buildControlsSection(viewModel, theme),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ==========================
  // CÁMARA + UI
  // ==========================

Widget _buildCameraSection(
  CardScannerViewModel viewModel,
  ThemeData theme,
) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;

          // Altura reservada para texto y padding (~15% del total)
          final reservedHeight = totalHeight * 0.15;

          // Altura disponible para cámara + barra
          final availableHeight = totalHeight - reservedHeight;

          // Altura del marco y la barra
          final zoomBarHeight = 50.0;
          final frameHeight = availableHeight - zoomBarHeight - AppSpacing.sm;

          // Calculamos el ancho según la proporción 86/59
          final frameWidth = frameHeight * _cardAspectRatio;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título
              Text(
                'Añadir Cartas',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // --- Cámara y barra ---
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Marco de cámara ajustado
                  SizedBox(
                    width: frameWidth,
                    height: frameHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(_cardCornerRadius),
                          child: GestureDetector(
                            key: _cameraWidgetKey,
                            onTapDown: (details) =>
                                _onFocusTap(details, _cameraWidgetKey),
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: frameWidth,
                                height: frameHeight,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(child: _buildCardFramePlaceholder()),
                        if (_focusPoint != null) _buildFocusCircle(),
                        _buildCameraOverlay(viewModel, theme),
                      ],
                    ),
                  ),

                  // Barra de zoom exactamente del mismo ancho
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: frameWidth,
                    height: zoomBarHeight,
                    child: _buildFloatingZoomBar(theme),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
}


  Widget _buildCardFramePlaceholder() {
    return Image.asset(
      'lib/assets/ygo_card_frame.png',
      fit: BoxFit.fill,
    );
  }

  Widget _buildFocusCircle() {
    return Positioned(
      left: _focusPoint!.dx - 40,
      top: _focusPoint!.dy - 40,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _focusAnimationController,
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 2, color: AppColors.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOverlay(
    CardScannerViewModel viewModel,
    ThemeData theme,
  ) {
    final overlayColor = AppColors.surface.withAlpha(179);
    final onOverlayColor = AppColors.textPrimary;

    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: overlayColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${viewModel.scannedCodes.length}/${CardScannerViewModel.batchLimit}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onOverlayColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: onOverlayColor,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: overlayColor,
            ),
            onPressed: _toggleFlash,
          ),
        ),
        if (viewModel.feedbackText.isNotEmpty)
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: overlayColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                viewModel.feedbackText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: onOverlayColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (viewModel.state == ViewState.busy)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildFloatingZoomBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: SliderComponentShape.noOverlay,
          activeTrackColor: AppColors.primary.withValues(alpha: 179 / 255),
          inactiveTrackColor: AppColors.primary.withValues(alpha: 76 / 255),
          thumbColor: AppColors.primary,
        ),
        child: Slider(
          value: _currentZoomLevel,
          min: _minZoomLevel,
          max: _maxZoomLevel,
          onChanged: _onZoomChanged,
        ),
      ),
    );
  }

  // ==========================
  // BOTONES DE CONTROL
  // ==========================

  Widget _buildControlsSection(
    CardScannerViewModel viewModel,
    ThemeData theme,
  ) {
    final bool isBusy = viewModel.state == ViewState.busy;
    final totalCodesForBatch = viewModel.scannedCodes.length;

    final primaryButtonStyle = theme.elevatedButtonTheme.style?.copyWith(
      minimumSize: WidgetStateProperty.all(const Size(180, 90)),
      textStyle: WidgetStateProperty.all(
        theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
      ),
    );

    final secondaryButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(150, 60),
      textStyle: theme.textTheme.titleLarge,
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.border;
          }
          return AppColors.surface;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondary;
          }
          return AppColors.textPrimary;
        },
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: secondaryButtonStyle,
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: isBusy
                ? null
                : () => viewModel.scanAndAddToList(_cameraController!),
            icon: const Icon(Icons.camera_alt, size: 40),
            label: const Text('Escanear'),
            style: primaryButtonStyle,
          ),
          ElevatedButton(
            onPressed: (isBusy || viewModel.scannedCodes.isEmpty)
                ? null
                : () async {
                    final jobId = await viewModel.sendBatch();
                    if (jobId != null && mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProcessingScreen(
                                jobId: jobId,
                                totalCards: totalCodesForBatch,
                              ),
                            ),
                          );
                        }
                      });
                    }
                  },
            style: secondaryButtonStyle,
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // ==========================
  // FUNCIONES DE CÁMARA
  // ==========================

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();

      setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      _showCameraErrorDialog();
    }
  }

  Future<void> _onFocusTap(TapDownDetails details, GlobalKey widgetKey) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final RenderBox? renderBox =
        widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localOffset = renderBox.globalToLocal(details.globalPosition);
    final normalized = Offset(
      (localOffset.dx / renderBox.size.width).clamp(0.0, 1.0),
      (localOffset.dy / renderBox.size.height).clamp(0.0, 1.0),
    );

    try {
      setState(() => _focusPoint = localOffset);
      _focusAnimationController.forward(from: 0.0);

      await _cameraController!.setFocusPoint(normalized);
      await _cameraController!.setExposurePoint(normalized);
    } catch (e) {
      debugPrint("⚠️ Error al enfocar: $e");
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Instrucciones"),
        content: const Text(
          'Apunta con la cámara al código de la carta (ej. "SDK-001") y pulsa "Escanear". '
          'Repite para añadir más cartas. Cuando termines, pulsa "Enviar".\n\n'
          '👉 TIP: toca en la pantalla para reenfocar la cámara.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  void _showCameraErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Error de Cámara"),
        content: const Text(
          'No se pudo inicializar la cámara. Esto puede deberse a problemas de compatibilidad con tu dispositivo.\n\n'
          'Posibles soluciones:\n'
          '• Reinicia la aplicación\n'
          '• Verifica los permisos de cámara\n'
          '• Asegúrate de que no esté siendo usada por otra app',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() {
    if (_cameraController == null) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
      _cameraController!
          .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _onZoomChanged(double value) {
    if (_cameraController == null) return;
    setState(() {
      _currentZoomLevel = value;
      _cameraController!.setZoomLevel(value);
    });
  }
}
