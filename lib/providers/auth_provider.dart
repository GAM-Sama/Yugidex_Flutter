import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

// El enum para el estado de autenticación se mantiene igual
enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  StreamSubscription<User?>? _userSubscription;

  AuthProvider(this._authService) {
    _initialize();
  }

  // --- GETTERS PÚBLICOS (AQUÍ ESTÁ LA CORRECCIÓN) ---
  AuthStatus get status => _status;
  User? get user => _user;
  String? get userName => _user?.userMetadata?['name'];
  String? get userEmail => _user?.email; // <-- AÑADIDO EL GETTER QUE FALTABA

  void _initialize() {
    // Escuchamos los cambios de autenticación del servicio
    _userSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      if (_user == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.authenticated;
      }
      notifyListeners(); // Notificamos a los widgets que escuchan
    });
  }

  // --- MÉTODOS DE AUTENTICACIÓN (se mantienen igual) ---
  Future<void> signUp(String name, String email, String password) async {
    try {
      await _authService.signUp(name, email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      // Manejar el error si es necesario
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}