import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Repositorio para operaciones de autenticación
/// Esta capa separa la lógica de negocio de la implementación de servicios
class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  /// Stream que emite cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Usuario actualmente autenticado
  User? get currentUser => _authService.currentUser;

  /// Registra un nuevo usuario
  Future<void> signUp(String name, String email, String password) async {
    try {
      await _authService.signUp(name, email, password);
    } catch (e) {
      throw Exception('Error en el registro: ${e.toString()}');
    }
  }

  /// Inicia sesión con email y contraseña
  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: ${e.toString()}');
    }
  }

  /// Actualiza los metadatos del usuario actual
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      await _authService.updateUserMetadata(metadata);
    } catch (e) {
      throw Exception('Error al actualizar metadatos del usuario: ${e.toString()}');
    }
  }
}