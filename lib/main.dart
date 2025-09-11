import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para SystemChrome
import 'package:supabase_flutter/supabase_flutter.dart'; // Necesario para Supabase
import 'screens/home_screen.dart'; // La pantalla de inicio

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase antes de lanzar la app
  await Supabase.initialize(
    url: 'https://tjjjowhlbcbocktbihie.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqampvd2hsYmNib2NrdGJpaGllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3Mzk1OTIsImV4cCI6MjA3MjMxNTU5Mn0.2pO8vgh7TkVT_iRmu2sSTAJXZLX-rhPCYO4ezRohofY',
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
    // Fuerza orientación horizontal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Activa fullscreen inmersivo
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YuGiOh Card Manager',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
