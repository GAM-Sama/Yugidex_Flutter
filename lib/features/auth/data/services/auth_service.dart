import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de autenticación que maneja la comunicación directa con Supabase Auth
class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  /// Stream que notifica los cambios en el estado de autenticación.
  /// Emite el objeto [User] cuando el usuario inicia sesión y null cuando cierra sesión.
  Stream<User?> get authStateChanges {
    return _auth.onAuthStateChange.map((data) {
      // El evento 'data' es de tipo AuthState. Extraemos la sesión y de ahí el usuario.
      return data.session?.user;
    });
  }

  /// Registra un nuevo usuario con email y contraseña.
  Future<void> signUp(String name, String email, String password) async {
    try {
      await _auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Guardamos el nombre en los metadatos
      );
    } on AuthException catch (e) {
      // Puedes manejar errores específicos aquí si quieres
      throw Exception('Error en el registro: ${e.message}');
    }
  }

  /// Inicia sesión con email y contraseña.
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception('Error al iniciar sesión: ${e.message}');
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
