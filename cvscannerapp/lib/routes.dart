import 'package:flutter/material.dart';
import 'screens/file_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/scan_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => LoginScreen(),
      '/home': (context) => ScanScreen(),
      '/login': (context) => LoginScreen(),
      '/register': (context) => RegisterScreen(),
      '/scanCamera': (context) => CameraScreen(),
      '/fileScan': (context) => FileScreen(),
    };
  }
}