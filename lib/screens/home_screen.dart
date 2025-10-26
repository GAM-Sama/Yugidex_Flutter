// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import 'package:yugioh_scanner/shared/widgets/custom_panel.dart';

// Importa tus otras pantallas y view models
// Needed if you want to display user info later
import '../services/supabase_service.dart';
import '../view_models/card_scanner_view_model.dart';
import '../view_models/card_list_view_model.dart';
import 'card_code_scanner_screen.dart';
import 'card_list_screen.dart';
import 'profile_screen.dart'; // Needed for navigation

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tema para usar los colores y estilos
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yugidex',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary, // Title in yellow
          ),
        ),
        // Eliminamos el botón de perfil de aquí, ya que estará en el body
        actions: const [
          SizedBox(width: kToolbarHeight) // Placeholder to keep title centered if needed
        ],
        centerTitle: true, // Asegura que el título quede centrado
      ),

      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centra los botones
          children: [
            // Botón 1: Escanear Cartas
            _buildHomeButton(
              context: context,
              title: 'Escanear Cartas',
              icon: Icons.camera_alt_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => CardScannerViewModel(),
                      child: const CardCodeScannerScreen(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: AppSpacing.lg), // Espacio

            // Botón 2: Ver Colección
            _buildHomeButton(
              context: context,
              title: 'Ver Mi Colección',
              icon: Icons.style_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      // Aseguramos que el ViewModel se inicialice si es necesario
                      final cardListViewModel = Provider.of<CardListViewModel>(context, listen: false);
                      if (cardListViewModel.cards.isEmpty && !cardListViewModel.isLoading) {
                         cardListViewModel.initialize(Provider.of<SupabaseService>(context, listen: false));
                         cardListViewModel.fetchCards();
                      }
                      return const CardListScreen();
                    },
                  ),
                );
              },
            ),

            const SizedBox(width: AppSpacing.lg), // Espacio

            // --- ¡NUEVO BOTÓN AQUÍ! ---
            // Botón 3: Mi Perfil
            _buildHomeButton(
              context: context,
              title: 'Mi Perfil',
              icon: Icons.account_circle_outlined, // Icono de perfil
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            // --- FIN DEL NUEVO BOTÓN ---
          ],
        ),
      ),
    );
  }

  /// Widget helper para construir los botones del menú
  Widget _buildHomeButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    // Obtenemos las definiciones del tema
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 220, // Ancho fijo
      height: 220, // Alto fijo
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm), // Padding exterior
        child: CustomPanel(
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.md), // Padding interior
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 50, color: colorScheme.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}