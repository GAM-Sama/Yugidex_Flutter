// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/view_models/auth_view_model.dart';
import '../home_screen.dart'; // <-- Necesitamos importar HomeScreen para navegar
import 'register_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // No necesitamos _isLoading aquí, el ViewModel lo gestionará
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Ahora _submitForm no necesita manejar el estado de carga
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authViewModel = context.read<AuthViewModel>();
      await authViewModel.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // ¡Ya no hay que hacer nada aquí después del login!
      // El Consumer se encargará de la navegación.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email o contraseña incorrectos: ${e.toString()}'), // Muestra el error real
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ¡CAMBIO CLAVE! ---
    // Envolvemos todo en un Consumer para reaccionar a los cambios de estado
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        
        // Si el estado cambia a autenticado, navegamos DESPUÉS de que la UI se construya
        if (authViewModel.isAuthenticated) {
          // Usamos addPostFrameCallback para navegar de forma segura fuera del build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          });
        }

        // Devolvemos el Scaffold con la UI normal
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Iniciar Sesión',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Por favor, introduce un email válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, introduce tu contraseña.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      // Usamos el estado de carga del ViewModel
                      authViewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submitForm,
                              child: const Text('Iniciar Sesión'),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text('¿No tienes una cuenta? Regístrate'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}