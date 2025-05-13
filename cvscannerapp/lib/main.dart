import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Importación de pantallas
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/file_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // Pantalla inicial
        '/': (context) => LoginScreen(),

        // Rutas principales
        '/home': (context) => ScanScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),

        // Para pantallas que requieren parámetros, usamos onGenerateRoute
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/scanCamera') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => CameraScreen(
              ownerDocument: args?['ownerDocument'],
            ),
          );
        } else if (settings.name == '/scanFile') {
          // Asumiendo que FileScreen también necesita parámetros similares
          return MaterialPageRoute(
            builder: (context) => FileScreen(),
          );
        }
        // Ruta de fallback para rutas no definidas
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('Ruta no encontrada')),
          ),
        );
      },
    );
  }
}