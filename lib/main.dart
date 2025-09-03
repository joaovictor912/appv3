import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'services/classificador_service.dart'; // 👈 importa o classificador
import 'screens/tela_principal.dart';
import 'screens/tela_login.dart';

late CameraDescription firstCamera;
final classificador = ClassificadorService(); // 👈 instância global

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  final cameras = await availableCameras();
  firstCamera = cameras.first;

  // 🔑 inicializa o classificador antes de abrir o app
  await classificador.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color corPrincipal = Color(0xFF00295B);
    const Color corDestaque = Color.fromARGB(255, 255, 255, 255);
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'Corretor de Gabaritos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: corPrincipal,
          brightness: Brightness.light,
        ).copyWith(
          primary: corPrincipal,
          secondary: corDestaque,
        ),
        textTheme: GoogleFonts.interTextTheme(textTheme).copyWith(
          displayLarge: GoogleFonts.poppins(textStyle: textTheme.displayLarge, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.poppins(textStyle: textTheme.displayMedium, fontWeight: FontWeight.bold),
          displaySmall: GoogleFonts.poppins(textStyle: textTheme.displaySmall, fontWeight: FontWeight.bold),
          headlineLarge: GoogleFonts.poppins(textStyle: textTheme.headlineLarge, fontWeight: FontWeight.bold),
          headlineMedium: GoogleFonts.poppins(textStyle: textTheme.headlineMedium, fontWeight: FontWeight.bold),
          headlineSmall: GoogleFonts.poppins(textStyle: textTheme.headlineSmall, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.poppins(textStyle: textTheme.titleLarge, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: corPrincipal,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: corPrincipal,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: corPrincipal,
            foregroundColor: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: corPrincipal,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return TelaPrincipal(camera: firstCamera);
        }

        return const TelaLogin();
      },
    );
  }
}
