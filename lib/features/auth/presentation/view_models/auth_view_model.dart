import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/base_view_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Estados específicos para autenticación
enum AuthState { uninitialized, authenticated, unauthenticated, loading }

class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;

  User? _user;
  AuthState _authState = AuthState.uninitialized;

  AuthViewModel(this._authRepository) {
    _initialize();
  }

  // Getters públicos
  AuthState get authState => _authState;
  User? get user => _user;
  String? get userName => _user?.userMetadata?['name'];
  String? get userEmail => _user?.email;
  bool get isAuthenticated => _authState == AuthState.authenticated;

  void _initialize() {
    // Escuchamos los cambios de autenticación del repositorio
    _authRepository.authStateChanges.listen((user) {
      _user = user;
      if (_user == null) {
        _authState = AuthState.unauthenticated;
      } else {
        _authState = AuthState.authenticated;
      }
      notifyListeners();
    });
  }

  /// Registra un nuevo usuario
  Future<void> signUp(String name, String email, String password) async {
    await executeWithState(
      () => _authRepository.signUp(name, email, password),
      resetOnStart: false,
    );
  }

  /// Inicia sesión con email y contraseña
  Future<void> signIn(String email, String password) async {
    await executeWithState(
      () => _authRepository.signIn(email, password),
      resetOnStart: false,
    );
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    await executeWithState(
      () => _authRepository.signOut(),
      resetOnStart: false,
    );
  }

  /// Valida si el formulario de registro es válido
  String? validateSignUpForm(String name, String email, String password, String confirmPassword) {
    if (name.trim().isEmpty) return 'El nombre es requerido';
    if (email.trim().isEmpty) return 'El email es requerido';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Ingresa un email válido';
    }
    if (password.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    if (password != confirmPassword) return 'Las contraseñas no coinciden';
    return null;
  }

  /// Valida si el formulario de login es válido
  String? validateSignInForm(String email, String password) {
    if (email.trim().isEmpty) return 'El email es requerido';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Ingresa un email válido';
    }
    if (password.trim().isEmpty) return 'La contraseña es requerida';
    return null;
  }
}
