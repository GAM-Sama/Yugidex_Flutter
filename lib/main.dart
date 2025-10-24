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
  // Carga las variables de entorno desde el archivo .env
  await dotenv.load(fileName: ".env");

  // Inicializa Supabase usando las variables de entorno
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

  runApp(const MyApp());
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
        title: 'YuGiOh Card Manager',
        theme: AppTheme.darkTheme, // Tu tema personalizado
        home: const SplashScreen(),
      ),
    );
  }
}