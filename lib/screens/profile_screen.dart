import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart'; // Asegúrate de que esta importación es correcta

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Leemos los datos del AuthProvider sin escuchar cambios, ya que no se espera que cambien
    // mientras el usuario está en esta pantalla.
    final authProvider = context.read<AuthProvider>();
    final username = authProvider.userName ?? 'Nombre no disponible';
    final userEmail = authProvider.userEmail ?? 'No hay email disponible';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // 1. Envolvemos todo el cuerpo en un SingleChildScrollView.
      // Esto crea una "caja" deslizable si el contenido de dentro es demasiado grande.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // 2. Mantenemos la Columna dentro para organizar el contenido verticalmente.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              _buildProfileInfoCard(
                icon: Icons.person_outline,
                label: 'Nombre',
                value: username,
              ),
              const SizedBox(height: 16),
              _buildProfileInfoCard(
                icon: Icons.email_outlined,
                label: 'Email',
                value: userEmail,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await authProvider.signOut();
                  // --- CORRECCIÓN APLICADA AQUÍ ---
                  // Verificamos si el widget todavía está en el árbol de widgets antes de usar su BuildContext.
                  if (!context.mounted) return;
                  // Navegamos a la pantalla de login y eliminamos todas las rutas anteriores.
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método de ayuda para no repetir código y mantener un estilo consistente
  Widget _buildProfileInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      // --- CORRECCIÓN DE DEPRECATED ---
      // Usamos withAlpha(128) que es el equivalente a 0.5 de opacidad y es más preciso.
      color: Colors.grey[850]?.withAlpha(128),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}