import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../view_models/card_scanner_view_model.dart';
import '../screens/processing_screen.dart';

class CardCodeScannerScreen extends StatefulWidget {
  const CardCodeScannerScreen({super.key});

  @override
  State<CardCodeScannerScreen> createState() => _CardCodeScannerScreenState();
}

class _CardCodeScannerScreenState extends State<CardCodeScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late Future<void> _initCameraFuture;

  // Variables para mejoras de la cámara
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  bool _isFlashOn = false;
  Offset? _focusPoint;
  late AnimationController _focusAnimationController;

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

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Try different resolution presets if high fails
      ResolutionPreset preset = ResolutionPreset.high;

      _cameraController = CameraController(
        backCamera,
        preset,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();

    } catch (e) {
      debugPrint("Error initializing camera with high resolution: $e");

      // Try with medium resolution if high fails
      try {
        final cameras = await availableCameras();
        final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (!mounted) return;

        _minZoomLevel = await _cameraController!.getMinZoomLevel();
        _maxZoomLevel = await _cameraController!.getMaxZoomLevel();

      } catch (e2) {
        debugPrint("Error initializing camera with medium resolution: $e2");
        if (mounted) {
          _showCameraErrorDialog();
        }
      }
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
          '• Reinicia tu dispositivo\n'
          '• Verifica que la cámara no esté siendo usada por otra aplicación\n'
          '• Asegúrate de que la aplicación tenga permisos de cámara',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
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
      _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    });
  }

  void _onZoomChanged(double value) {
    if (_cameraController == null) return;
    setState(() {
      _currentZoomLevel = value;
      _cameraController!.setZoomLevel(value);
    });
  }

  Future<void> _onFocusTap(TapDownDetails details) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      if (mounted) {
        setState(() {
          _focusPoint = details.localPosition;
        });
        _focusAnimationController.forward(from: 0.0);
      }
      final size = MediaQuery.of(context).size;
      final offset = Offset(
        details.localPosition.dx / size.width,
        details.localPosition.dy / size.height,
      );
      await _cameraController!.setFocusPoint(offset);
      await _cameraController!.setExposurePoint(offset);
    } catch (e) {
      debugPrint("⚠️ Error al enfocar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initCameraFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done ||
                _cameraController == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Consumer<CardScannerViewModel>(
              builder: (context, viewModel, child) {
                return Row(
                  children: [
                    _buildCameraSection(viewModel),
                    // >>>>> CÓDIGO CORREGIDO <<<<<
                    // El widget de controles ha sido reemplazado por la versión correcta.
                    _buildControlsSection(viewModel),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraSection(CardScannerViewModel viewModel) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Añadir Cartas',
              style: TextStyle(
                color: Colors.blueAccent[100],
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onTapDown: _onFocusTap,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                  if (_focusPoint != null) _buildFocusCircle(),
                  _buildCameraOverlay(viewModel),
                ],
              ),
            ),
            _buildZoomSlider(),
          ],
        ),
      ),
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
            border: Border.all(width: 2, color: Colors.yellowAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOverlay(CardScannerViewModel viewModel) {
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${viewModel.scannedCodes.length}/${CardScannerViewModel.batchLimit}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
              color: Colors.white,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
            onPressed: _toggleFlash,
          ),
        ),
        if (viewModel.feedbackText.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                viewModel.feedbackText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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

  Widget _buildZoomSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          thumbColor: Colors.white,
          activeTrackColor: Colors.white70,
          inactiveTrackColor: Colors.white30,
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

  Widget _buildControlsSection(CardScannerViewModel viewModel) {
    final bool isBusy = viewModel.state == ViewState.busy;
    // Guardamos una copia del total de códigos ANTES de que el ViewModel los limpie
    final totalCodesForBatch = viewModel.scannedCodes.length;

    return Padding(
      padding: const EdgeInsets.only(right: 20.0, top: 20, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón de cancelar (este ya estaba bien)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              minimumSize: const Size(150, 60),
            ),
            child: const Text('Cancelar', style: TextStyle(fontSize: 20)),
          ),

          // Botón de escanear (este ya estaba bien)
          ElevatedButton.icon(
            onPressed:
                isBusy
                    ? null
                    : () => viewModel.scanAndAddToList(_cameraController!),
            icon: const Icon(Icons.camera_alt, size: 40),
            label: const Text('Escanear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 90),
              textStyle: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // --- Botón de enviar (CON LA LÓGICA FINAL Y SIN EL .clearCodes()) ---
          ElevatedButton(
            onPressed:
                (isBusy || viewModel.scannedCodes.isEmpty)
                    ? null
                    : () async {
                      // 1. Llama al viewModel para iniciar el lote y espera el jobId
                      final jobId = await viewModel.sendBatch();

                      // 2. Si n8n nos da un jobId y el widget sigue "montado"...
                      if (jobId != null && mounted) {
                        // ¡AQUÍ YA NO HAY LLAMADA A clearCodes(), el ViewModel lo hace solo!

                        // 3. ...navegamos a la pantalla de progreso.
                        Navigator.pushReplacement(
                          // Usamos pushReplacement para que no se pueda volver atrás
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProcessingScreen(
                                  jobId: jobId,
                                  totalCards: totalCodesForBatch,
                                ),
                          ),
                        );
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[900],
              minimumSize: const Size(150, 60),
            ),
            child: const Text('Enviar', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }
}
