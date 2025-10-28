// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import 'package:yugioh_scanner/shared/widgets/custom_panel.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _usernameController = TextEditingController(text: authViewModel.userName ?? '');
    _emailController = TextEditingController(text: authViewModel.userEmail ?? '');
    _bioController = TextEditingController(text: 'Me gusta desde siempre, amante del yugioh clásico. Miau'); // Placeholder
    _locationController = TextEditingController(text: 'España'); // Placeholder
    _websiteController = TextEditingController(text: 'https://tu-sitio-web.com'); // Placeholder
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final authViewModel = context.read<AuthViewModel>(); // Read for actions

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil', style: textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CustomPanel(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(
                children: [
                  Icon(Icons.person_outline, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Información Personal', style: textTheme.titleLarge),
                      Text('Actualiza tu información personal y preferencias', style: textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Formulario
              _buildTextField(
                label: 'Nombre de Usuario',
                controller: _usernameController,
                hint: 'Tu nombre de duelista',
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                readOnly: true,
                hint: 'tu-email@ejemplo.com',
                footer: 'El email no se puede cambiar desde aquí',
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                label: 'Biografía',
                controller: _bioController,
                hint: 'Cuéntanos un poco sobre ti...',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                label: 'Ubicación',
                controller: _locationController,
                hint: 'Tu país o ciudad',
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                label: 'Sitio Web',
                controller: _websiteController,
                hint: 'https://tu-sitio-web.com',
              ),
              const SizedBox(height: AppSpacing.xl),

              // Botones de Acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar Cambios'),
                  onPressed: () async {
                    // Recopilar los datos del formulario
                    final Map<String, dynamic> metadata = {
                      'name': _usernameController.text.trim(),
                      'bio': _bioController.text.trim(),
                      'location': _locationController.text.trim(),
                      'website': _websiteController.text.trim(),
                    };

                    // Validar que al menos el nombre esté presente
                    if (metadata['name'].isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El nombre es requerido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      // Almacenar el contexto actual
                      final currentContext = context;
                      
                      // Actualizar los metadatos del usuario
                      await authViewModel.updateUserMetadata(metadata);

                      // Verificar si el widget sigue montado
                      if (!mounted) return;
                      
                      // Mostrar mensaje de éxito
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Perfil actualizado correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // Verificar si el widget sigue montado
                      if (!mounted) return;
                      
                      // Almacenar el contexto actual para el bloque catch
                      final errorContext = context;
                      if (errorContext.mounted) {
                        // Mostrar mensaje de error
                        ScaffoldMessenger.of(errorContext).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar el perfil: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  ),
                  onPressed: () async {
                    // 1. Ejecuta la acción asíncrona
                    await authViewModel.signOut();

                    // Verificar si el widget sigue montado
                    if (!mounted) return;
                    
                    // 2. Usa addPostFrameCallback para navegar en el siguiente frame
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    String? footer,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(footer, style: textTheme.bodySmall),
        ]
      ],
    );
  }
}