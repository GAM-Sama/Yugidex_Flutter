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