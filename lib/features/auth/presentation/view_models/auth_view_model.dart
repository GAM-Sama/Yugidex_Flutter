// lib/features/auth/presentation/view_models/auth_view_model.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/base_view_model.dart'; // Adjust path if needed
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

  // --- ¡CAMBIO AQUÍ! ---
  // Leemos 'username' en lugar de 'name'
  String? get userName => _user?.userMetadata?['username'];
  // --- FIN DEL CAMBIO ---

  String? get userEmail => _user?.email;
  bool get isAuthenticated => _authState == AuthState.authenticated;

  void _initialize() {
    // Escuchamos los cambios de autenticación del repositorio
    _authRepository.authStateChanges.listen((user) {
      _user = user;
      if (_user == null) {
        _authState = AuthState.unauthenticated;
      } else {
        // Aseguramos que los datos se lean aquí también si es necesario
        // (aunque el getter ya lo hace bajo demanda)
        _authState = AuthState.authenticated;
      }
      notifyListeners();
    });
    // Forzamos una comprobación inicial por si ya hay un usuario
     _checkCurrentUser();
  }

  // Función para comprobar el usuario al inicio
  void _checkCurrentUser() {
     _user = _authRepository.currentUser; // Asumiendo que AuthRepository tiene este getter
      if (_user == null) {
        _authState = AuthState.unauthenticated;
      } else {
        _authState = AuthState.authenticated;
      }
      notifyListeners();
  }


  /// Registra un nuevo usuario
  /// Asegúrate de que AuthRepository.signUp pase el 'username' en options: { data: { 'username': name } }
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

  // --- Función para actualizar perfil (NUEVA) ---
  /// Actualiza los metadatos del usuario actual.
  Future<void> updateUserProfile({
    String? username,
    String? bio,
    String? location,
    String? website,
  }) async {
    // Creamos el mapa de datos solo con los valores que no son null
    final Map<String, dynamic> dataToUpdate = {};
    if (username != null) dataToUpdate['username'] = username;
    if (bio != null) dataToUpdate['bio'] = bio;
    if (location != null) dataToUpdate['location'] = location;
    if (website != null) dataToUpdate['website'] = website;

    if (dataToUpdate.isEmpty) return; // No hay nada que actualizar

    await executeWithState(
      () => _authRepository.updateUserMetadata(dataToUpdate),
      // Podrías poner un estado específico como 'updatingProfile' si quieres
      // loadingState: AuthState.updatingProfile,
      resetOnStart: false, // Mantenemos el estado de autenticado
    );

    // Forzamos una recarga del usuario para que el getter 'userName' se actualice
    if (state != ViewState.error) {
       _checkCurrentUser();
    }
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

  /// Actualiza los metadatos del usuario
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await executeWithState(
      () => _authRepository.updateUserMetadata(metadata),
      resetOnStart: false,
    );
  }
}