import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../globals.dart'; // Import globals.dart to set loggedInUserDocument

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _document = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final ip = dotenv.env['ip'] ?? 'localhost:4000';
        final response = await http.post(
          Uri.parse('http://$ip/api/users/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'document': _document, 'password': _password}),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          // Set the global loggedInUserDocument variable
          loggedInUserDocument = _document;

          // Print for debugging
          print('Usuario conectado con documento: $loggedInUserDocument');

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['message'] ?? 'Error al iniciar sesión'),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error de conexión. Verifica tu conexión a internet o el servidor.',
            ),
          ),
        );
        print('Error de login: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.all(20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo_cvscanner.png',
                        height: 80,
                      ),
                      SizedBox(height: 30),
                      Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Documento',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu número de documento';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _document = value!;
                              },
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _password = value!;
                              },
                            ),
                            SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0D47A1),
                                  foregroundColor: Colors.white,
                                ),
                                child:
                                    _isLoading
                                        ? CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        )
                                        : Text('INGRESAR'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('¿No tienes una cuenta?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text('Registrarse'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Image.asset('assets/images/logo_magneto.png', height: 40),
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
