// file: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/card_scanner_view_model.dart';
import '../view_models/card_list_view_model.dart'; // <-- Importa el ViewModel de la lista
import 'card_code_scanner_screen.dart';
import 'card_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YuGiOh! Card Manager'),
        // Usamos un color oscuro para el AppBar que encaje con el tema general
        backgroundColor: Colors.grey[900],
        elevation: 4.0,
      ),
      // El cuerpo ahora será una Fila (Row) para poner los elementos uno al lado del otro
      body: Row(
        // Indicamos que los elementos se estiren para ocupar todo el alto
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel de la Izquierda: Añadir Cartas
          Expanded(
            child: _buildMenuCard(
              context: context,
              title: 'Añadir Cartas',
              icon: Icons.camera_alt_outlined,
              color: Colors.indigo[700]!,
              onTap: () {
                // Navegamos a la pantalla del escáner
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChangeNotifierProvider(
                          create: (_) => CardScannerViewModel(),
                          child: const CardCodeScannerScreen(),
                        ),
                  ),
                );
              },
            ),
          ),
          // Panel de la Derecha: Ver Cartas
          Expanded(
            child: _buildMenuCard(
              context: context,
              title: 'Ver Cartas',
              icon: Icons.style,
              color: Colors.blueGrey[700]!,
              onTap: () {
                // Navegamos a la pantalla de la lista de cartas
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // ¡Importante! La pantalla de lista también necesita su propio ViewModel.
                    builder:
                        (context) => ChangeNotifierProvider(
                          create: (_) => CardListViewModel(),
                          child: const CardListScreen(),
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Un método de ayuda para construir nuestros paneles de menú.
  /// Así evitamos repetir el mismo código dos veces (Principio DRY).
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
