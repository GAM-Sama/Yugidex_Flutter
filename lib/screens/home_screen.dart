// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Recomendado usar Lucide para consistencia
import '../core/theme/app_theme.dart';
import 'package:yugioh_scanner/shared/widgets/custom_panel.dart';

// Importa tus otras pantallas y view models
import '../services/supabase_service.dart';
import '../view_models/card_scanner_view_model.dart';
import '../view_models/card_list_view_model.dart';
import 'card_code_scanner_screen.dart';
import 'card_list_screen.dart';
import 'profile_screen.dart'; 
import 'my_decks_screen.dart'; // <--- IMPORTA LA NUEVA PANTALLA

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yugidex',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        actions: const [
          SizedBox(width: kToolbarHeight) 
        ],
        centerTitle: true,
      ),

      body: Center(
        // Usamos Wrap o SingleChildScrollView si hay muchos botones para evitar overflow
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón 1: Escanear Cartas
              _buildHomeButton(
                context: context,
                title: 'Escanear',
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

              const SizedBox(width: AppSpacing.lg),

              // Botón 2: Ver Colección
              _buildHomeButton(
                context: context,
                title: 'Colección',
                icon: Icons.style_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
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

              const SizedBox(width: AppSpacing.lg),

              // --- NUEVO BOTÓN: MIS DECKS ---
              _buildHomeButton(
                context: context,
                title: 'Mis Decks',
                icon: LucideIcons.layers, // Icono de mazos
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyDecksScreen()),
                  );
                },
              ),
              // -----------------------------

              const SizedBox(width: AppSpacing.lg),

              // Botón 4: Mi Perfil
              _buildHomeButton(
                context: context,
                title: 'Perfil',
                icon: Icons.account_circle_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // He reducido un poco el tamaño para que quepan 4 botones mejor si es tablet horizontal
    // O usa SingleChildScrollView como puse arriba.
    return SizedBox(
      width: 180, // Ligeramente más pequeño para que no sea gigante
      height: 180, 
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs), 
        child: CustomPanel(
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.md), 
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: colorScheme.primary),
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