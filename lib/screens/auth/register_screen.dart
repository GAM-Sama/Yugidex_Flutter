// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/view_models/auth_view_model.dart';
import '../home_screen.dart'; // Para navegar al Home
import 'login_screen.dart'; // Para navegar a la pantalla de login

class TermsAndConditionsDialog extends StatelessWidget {
  const TermsAndConditionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Términos de Uso y Política de Privacidad'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Última actualización: 19 de octubre de 2025.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bienvenido a Yugidex CRM (en adelante, "la Plataforma"). Al crear una cuenta y utilizar nuestros servicios, usted (en adelante, "el Usuario") acepta y se compromete a cumplir los siguientes Términos de Uso y nuestra Política de Privacidad.',
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Términos de Uso',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Cuenta de Usuario: El Usuario es responsable de mantener la confidencialidad de su contraseña y de todas las actividades que ocurran bajo su cuenta. Se compromete a proporcionar información veraz (nombre de usuario y email) y a notificar cualquier uso no autorizado de su cuenta.\n'
              '• Uso Aceptable: La Plataforma se proporciona para la gestión de colecciones personales. Queda prohibido utilizarla para fines ilegales, fraudulentos o que infrinjan los derechos de terceros.\n'
              '• Modificación del Servicio: Nos reservamos el derecho de modificar o interrumpir el servicio (temporal o permanentemente) con o sin previo aviso.',
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Política de Privacidad (Conforme al RGPD)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'En cumplimiento del Reglamento (UE) 2016/679 (RGPD), le informamos sobre el tratamiento de sus datos personales.\n\n'
              '• Responsable del Tratamiento: Yugidex CRM.\n'
              '• Datos Recopilados: Recopilaremos exclusivamente su nombre de usuario y su dirección de correo electrónico.\n\n'
              '• Finalidad y Legitimación del Tratamiento:\n'
              '  1. Prestación del Servicio: Utilizaremos su email y nombre de usuario para gestionar su cuenta, permitirle el acceso a la plataforma, restaurar su contraseña y enviarle comunicaciones transaccionales esenciales sobre el estado del servicio.\n'
              '  2. Comunicaciones Comerciales (Marketing): Utilizaremos su dirección de correo electrónico para enviarle publicidad, promociones y ofertas tanto propias de Yugidex CRM como de terceros colaboradores.\n\n'
              '• Cesión de Datos a Terceros: Usted consiente que podamos ceder su dirección de correo electrónico a empresas colaboradoras del sector para que puedan enviarle sus propias comunicaciones comerciales. No cederemos su nombre de usuario ni su contraseña.\n\n'
              '• Plazo de Conservación: Sus datos se conservarán mientras mantenga activa su cuenta en la Plataforma.\n\n'
              '• Sus Derechos (ARCO-POL): Usted tiene derecho a acceder, rectificar, suprimir, oponerse al tratamiento, limitar el tratamiento, y a la portabilidad de sus datos. Puede retirar su consentimiento para fines comerciales en cualquier momento.',
            ),
            const SizedBox(height: 16),
            const Text(
              '3. Aceptación',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Al marcar la casilla de aceptación, usted declara haber leído, comprendido y aceptado en su totalidad los presentes Términos de Uso y la Política de Privacidad, otorgando su consentimiento explícito para el tratamiento de sus datos en los términos descritos, incluida la recepción de comunicaciones comerciales y la cesión de su email a terceros colaboradores.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authViewModel = context.read<AuthViewModel>();
      await authViewModel.signUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // El Consumer se encargará de la navegación al detectar el cambio de estado.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el registro: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Envolvemos todo en un Consumer para reaccionar a los cambios de estado
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        // Si el estado cambia a autenticado, navegamos de forma segura
        if (authViewModel.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          });
        }

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
                        'Crear Cuenta',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, introduce tu nombre.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                          if (value == null || value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Términos y condiciones
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const TermsAndConditionsDialog(),
                                );
                              },
                              child: const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'He leído y acepto los ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text: 'Términos de Uso y la Política de Privacidad',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Usamos el estado de carga del ViewModel
                      authViewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _agreedToTerms ? _submitForm : null,
                              child: const Text('Registrarse'),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text('¿Ya tienes una cuenta? Inicia sesión'),
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