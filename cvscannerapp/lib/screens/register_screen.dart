import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'scan_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../globals.dart' as globals;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // For debugging, print the configured IP
    print('Server IP for Register: ${dotenv.env['ip']}');
  }

  @override
  void dispose() {
    _documentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_documentController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Por favor, completa todos los campos');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showSnackBar('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Las contraseñas no coinciden');
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

    final url = Uri.parse('http://$ipAddress/api/users');

    final body = {
      "document": _documentController.text.trim(),
      "password": _passwordController.text,
      "confirmPassword": _confirmPasswordController.text,
    };

    try {
      print('Enviando solicitud de registro a: $url');
      print(
        'Datos: {"document": "${_documentController.text.trim()}", "password": "****", "confirmPassword": "****"}',
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 10));

      print('Respuesta recibida. Status code: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 201) {
        // Guardar el documento del usuario recién registrado
        globals.loggedInUserDocument = _documentController.text.trim();

        _showSnackBar('Usuario registrado exitosamente', Colors.green);

        // Esperar un momento para que el usuario vea el mensaje de éxito
        await Future.delayed(Duration(seconds: 1));

        // Navegar a la pantalla principal
        _navigateToHome(context);
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? 'Error al registrar usuario');
      }
    } catch (e) {
      print('Error de registro: $e');
      if (e is SocketException) {
        _showSnackBar(
          'Error de conexión al servidor. Verifica la IP y que el servidor esté en ejecución.',
        );
      } else if (e is TimeoutException) {
        _showSnackBar('Tiempo de espera agotado. El servidor no responde.');
      } else {
        _showSnackBar('Error de registro: ${e.toString()}');
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => ScanScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/logo_cvscanner.png", height: 50),
                    SizedBox(height: 10),
                    Text(
                      "¡Regístrate!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text("Por favor, ingresa tus datos para crear tu cuenta"),
                    SizedBox(height: 20),
                    TextField(
                      controller: _documentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Documento',
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900], // Azul oscuro
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                          ),
                          child: Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ), // Letra blanca
                          ),
                        ),
                    SizedBox(height: 30),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Image.asset(
                        "assets/images/logo_magneto.png",
                        height: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
