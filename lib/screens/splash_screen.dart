import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        switch (authViewModel.authState) {
          case AuthState.authenticated:
            return const HomeScreen();
          case AuthState.unauthenticated:
            return const LoginScreen();
          case AuthState.connectionError:
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        size: 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Error de Conexión',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        authViewModel.connectionErrorMessage ?? 'No se puede conectar a la base de datos',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          authViewModel.retryConnection();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          case AuthState.uninitialized:
          case AuthState.loading:
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