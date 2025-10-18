import 'package:flutter/material.dart';

/// Estados comunes para todos los ViewModels
enum ViewState { idle, loading, success, error }

/// Clase base para todos los ViewModels que proporciona manejo común de estado
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  /// Establece el estado y notifica a los listeners
  void _setState(ViewState newState, {String? errorMessage}) {
    _state = newState;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  /// Inicia una operación de carga
  void setLoading() {
    _setState(ViewState.loading);
  }

  /// Marca como éxito
  void setSuccess() {
    _setState(ViewState.success);
  }

  /// Marca como error con mensaje
  void setError(String message) {
    _setState(ViewState.error, errorMessage: message);
  }

  /// Resetea al estado inicial
  void resetState() {
    _setState(ViewState.idle);
  }

  /// Ejecuta una operación asíncrona con manejo automático de estado
  Future<T> executeWithState<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    bool resetOnStart = true,
  }) async {
    try {
      if (resetOnStart) {
        setLoading();
      }
      final result = await operation();
      setSuccess();
      return result;
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }
}
