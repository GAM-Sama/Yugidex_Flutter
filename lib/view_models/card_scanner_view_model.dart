import 'package:flutter/material.dart' hide Card;
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/ocr_service.dart';
import '../services/webhook_service.dart';

enum ViewState { idle, busy }

class CardScannerViewModel extends ChangeNotifier {
  final WebhookService _webhookService = WebhookService();
  final TextRecognizer _textRecognizer = TextRecognizer();

  ViewState _state = ViewState.idle;
  String _feedbackText = '';
  List<String> _scannedCodes = [];

  static const int batchLimit = 100;

  ViewState get state => _state;
  String get feedbackText => _feedbackText;
  List<String> get scannedCodes => _scannedCodes;

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setFeedback(String text) {
    _feedbackText = text;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      if (_feedbackText == text) {
        _feedbackText = '';
        notifyListeners();
      }
    });
  }

  Future<void> scanAndAddToList(CameraController cameraController) async {
    if (_state == ViewState.busy || !cameraController.value.isInitialized)
      return;
    _setState(ViewState.busy);
    try {
      final picture = await cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        _setFeedback('No se detectó texto');
      } else {
        final String? cardCode = await OcrService.extractCardCode(
          recognizedText.text,
        );
        if (cardCode != null) {
          _scannedCodes.add(cardCode);
          _setFeedback('Añadido: $cardCode');
        } else {
          _setFeedback('No se encontró un código válido');
        }
      }
    } catch (e) {
      debugPrint("Error en scanAndAddToList: $e");
      _setFeedback('Error al escanear: ${e.toString()}');
    } finally {
      _setState(ViewState.idle);
    }
  }

  // --- MÉTODO SENDBATCH ACTUALIZADO ---
  // Ahora devuelve un Future<String?> que será el jobId que nos da n8n.
  Future<String?> sendBatch() async {
    if (_scannedCodes.isEmpty) {
      _setFeedback('No hay códigos para enviar');
      return null; // Devuelve null porque no hay nada que enviar
    }
    _setState(ViewState.busy);

    // Hacemos una copia de la lista para enviarla.
    final codesToSend = List<String>.from(_scannedCodes);

    // Llamamos al WebhookService. Ahora esperamos que nos devuelva un jobId.
    final jobId = await _webhookService.sendCodes(codesToSend);

    if (jobId != null) {
      // Si recibimos un jobId, significa que n8n ha aceptado el trabajo.
      // Limpiamos la lista para el siguiente lote.
      _scannedCodes.clear();
    } else {
      // Si no recibimos jobId, algo ha fallado en la comunicación con n8n.
      _setFeedback('Error al iniciar el lote en el servidor.');
    }

    _setState(ViewState.idle);

    // Devolvemos el jobId (o null si falló) a la pantalla que nos llamó.
    return jobId;
  }
  // --- FIN DEL MÉTODO ACTUALIZADO ---

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
