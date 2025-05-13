import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'scan_screen.dart';
import 'register_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../globals.dart' as globals;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // For debugging, print the configured IP
    print('Server IP: ${dotenv.env['ip']}');
  }

  @override
  void dispose() {
    _documentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser(BuildContext context) async {
    // Validation
    if (_documentController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Por favor, completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    final ipAddress = dotenv.env['ip'];
    if (ipAddress == null || ipAddress.isEmpty) {
      _showSnackBar(
        'Error de configuración: IP no definida en el archivo .env',
      );
      setState(() => _isLoading = false);
      return;
    }

    final url = Uri.parse('http://$ipAddress/api/users/login');

    try {
      print('Enviando solicitud de inicio de sesión a: $url');
      print(
        'Datos: {"document": "${_documentController.text.trim()}", "password": "****"}',
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "document": _documentController.text.trim(),
              "password": _passwordController.text,
            }),
          )
          .timeout(Duration(seconds: 10));

      print('Respuesta recibida. Status code: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // Guardar documento del usuario logueado
        globals.loggedInUserDocument = _documentController.text.trim();

        _showSnackBar('Inicio de sesión exitoso', Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ScanScreen()),
        );
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      print('Error de conexión: $e');
      if (e is SocketException) {
        _showSnackBar(
          'Error de conexión al servidor. Verifica la IP y que el servidor esté en ejecución.',
        );
      } else if (e is TimeoutException) {
        _showSnackBar('Tiempo de espera agotado. El servidor no responde.');
      } else {
        _showSnackBar('Error de conexión: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 50),
                      Image.asset(
                        'assets/images/logo_cvscanner.png',
                        height: 80,
                      ),
                      SizedBox(height: 15),
                      Text(
                        '¡Inicia Sesión!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Por favor, ingresa tus credenciales para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: 350,
                        child: TextField(
                          controller: _documentController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Número de Documento',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      SizedBox(height: 15),
                      SizedBox(
                        width: 350,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      SizedBox(height: 20),
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                            onPressed: () => _loginUser(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 30,
                              ),
                            ),
                            child: Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          '¿No tienes una cuenta? Regístrate aquí',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Image.asset(
                          'assets/images/logo_magneto.png',
                          height: 50,
                        ),
                      ),
                    ],
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
