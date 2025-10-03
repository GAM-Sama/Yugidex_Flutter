import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // El Consumer reconstruye este widget CADA VEZ que el AuthProvider
    // llama a notifyListeners().
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.authenticated:
            // Si el usuario está autenticado, vamos a la pantalla principal.
            return const HomeScreen();
          case AuthStatus.unauthenticated:
            // Si no lo está, vamos a la pantalla de login.
            return const LoginScreen();
          case AuthStatus.uninitialized:
            // Mientras se comprueba el estado, mostramos un indicador de carga.
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
    );
  }
}