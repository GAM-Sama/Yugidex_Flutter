import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'view_models/card_list_view_model.dart';

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
    // Envolvemos MaterialApp con MultiProvider para que los ViewModels/Providers
    // estén disponibles en toda la aplicación.
    return MultiProvider(
      providers: [
        // 1. Proveemos una instancia de AuthService.
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // 2. Usamos ChangeNotifierProxyProvider para crear AuthProvider.
        //    Este provider especial puede LEER otros providers (como AuthService)
        //    y pasárselo a AuthProvider en su constructor.
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
          update: (context, authService, previousAuthProvider) =>
              AuthProvider(authService),
        ),
        // 3. Mantenemos tu CardListViewModel existente.
        ChangeNotifierProvider(
          create: (context) => CardListViewModel(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'YuGiOh Card Manager',
        theme: ThemeData.dark(),
        // La app ahora arranca en la SplashScreen, que decide a dónde ir.
        home: const SplashScreen(),
      ),
    );
  }
}