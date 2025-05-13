import 'package:flutter/material.dart';
import 'screens/file_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/scan_screen.dart';
import 'globals.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => LoginScreen(),
      '/home': (context) => ScanScreen(),
      '/login': (context) => LoginScreen(),
      '/register': (context) => RegisterScreen(),
      '/scanCamera': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CameraScreen(ownerDocument: args?['ownerDocument'] ?? loggedInUserDocument);
      },
      '/fileScan': (context) => FileScreen(),
    };
  }
}