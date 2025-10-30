// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/view_models/auth_view_model.dart';
import 'services/supabase_service.dart';
import 'view_models/card_list_view_model.dart';
import 'view_models/processed_cards_view_model.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Cargar variables de entorno
    await dotenv.load(fileName: ".env");
    
    // 2. Verificar que las variables de entorno existen
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_KEY'];
    
    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('Las variables de entorno SUPABASE_URL y SUPABASE_KEY son requeridas');
    }
    
    // 3. Inicializar Supabase con manejo de errores
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      debug: true, // Habilitar modo debug para más información
    );
    
    // 4. Verificar conexión con Supabase
    final response = await Supabase.instance.client.from('Cartas').select('count').limit(1);
    debugPrint('✅ Conexión con Supabase establecida correctamente');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Mostrar error detallado en consola
    debugPrint('❌ Error al inicializar la aplicación: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Ejecutar la aplicación en modo error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 20),
                  const Text(
                    'Error de conexión',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyForcedLandscape();
  }

  void _applyForcedLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyForcedLandscape();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- 1. Providers que NO dependen de nada ---
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<SupabaseService>(
          create: (_) => SupabaseService(),
        ),
        ChangeNotifierProvider<ProcessedCardsViewModel>(
          create: (context) => ProcessedCardsViewModel(),
        ),
        ChangeNotifierProvider<CardListViewModel>(
          create: (context) => CardListViewModel(),
        ),

        // --- 2. Providers que SÍ dependen de otros (usando Proxy) ---

        // AuthRepository depende de AuthService
        ProxyProvider<AuthService, AuthRepository>(
          update: (context, authService, previousRepository) =>
              AuthRepository(authService),
        ),

        // AuthViewModel (un ChangeNotifier) depende de AuthRepository
        ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
          // 'create' se llama la primera vez. 'context.read' es seguro aquí
          // porque AuthRepository está definido en el ProxyProvider de arriba.
          create: (context) => AuthViewModel(context.read<AuthRepository>()),
          
          // 'update' se llama si AuthRepository cambia (en tu caso, no lo hará,
          // pero este es el patrón completo).
          update: (context, authRepo, previousViewModel) =>
              AuthViewModel(authRepo),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Yugidex',
        theme: AppTheme.darkTheme, // Tu tema personalizado
        home: const SplashScreen(),
      ),
    );
  }
}