// file: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart'; // <-- 1. IMPORTAMOS EL AUTH VIEW MODEL
import '../services/supabase_service.dart';
import '../view_models/card_scanner_view_model.dart';
import '../view_models/card_list_view_model.dart';
import 'card_code_scanner_screen.dart';
import 'card_list_screen.dart';
import 'profile_screen.dart'; // <-- 2. IMPORTAMOS LA PANTALLA DE PERFIL

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. OBTENEMOS LA INFORMACIÓN DEL USUARIO DESDE EL VIEW MODEL
    // Usamos context.watch para que el widget se reconstruya si el usuario cambia (ej: al cerrar sesión)
    final authViewModel = context.watch<AuthViewModel>();
    final userName = authViewModel.userName ?? 'Duelista'; // Usamos 'Duelista' como nombre por defecto

    return Scaffold(
      appBar: AppBar(
        // 4. MOSTRAMOS UN SALUDO PERSONALIZADO
        title: Text('¡Hola, $userName!'),
        backgroundColor: Colors.grey[900],
        elevation: 4.0,
        // 5. AÑADIMOS UN BOTÓN DE ACCIÓN PARA IR AL PERFIL
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mi Perfil', // Texto que aparece al mantener pulsado
            onPressed: () {
              // Navegamos a la pantalla de perfil
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel de la Izquierda: Añadir Cartas (sin cambios)
          Expanded(
            child: _buildMenuCard(
              context: context,
              title: 'Añadir Cartas',
              icon: Icons.camera_alt_outlined,
              color: Colors.indigo[700]!,
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
          ),
          // Panel de la Derecha: Ver Cartas (sin cambios)
          Expanded(
            child: _buildMenuCard(
              context: context,
              title: 'Ver Mi Colección', // Pequeño cambio de texto para reflejar que es SU colección
              icon: Icons.style,
              color: Colors.blueGrey[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      // Obtener la instancia existente del Provider global
                      final cardListViewModel = Provider.of<CardListViewModel>(context, listen: false);
                      // Inicializar con SupabaseService si no está inicializado
                      if (cardListViewModel.cards.isEmpty) {
                        cardListViewModel.initialize(Provider.of<SupabaseService>(context, listen: false));
                        cardListViewModel.fetchCards();
                      }
                      return const CardListScreen();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Tu método de ayuda para construir los paneles (sin cambios)
  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16.0),
        elevation: 8.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.2),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}