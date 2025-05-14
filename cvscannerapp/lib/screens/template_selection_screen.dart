import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TemplateSelectionScreen extends StatefulWidget {
  final String resumeId;

  const TemplateSelectionScreen({Key? key, required this.resumeId})
    : super(key: key);

  @override
  State<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  List<String> _templates = [];
  bool _isLoading = true;
  String? _selectedTemplate;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('http://${dotenv.env['ip']}/api/templates'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _templates = List<String>.from(data['templates']);
          _isLoading = false;
          if (_templates.isNotEmpty) {
            _selectedTemplate = _templates[0];
          }
        });
      } else {
        throw Exception('Failed to load templates');
      }
    } catch (e) {
      print('Error loading templates: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar plantillas')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateFromTemplate() async {
    if (_selectedTemplate == null) return;

    setState(() => _isGenerating = true);

    try {
      final response = await http.post(
        Uri.parse(
          'http://${dotenv.env['ip']}/api/templates/generate/${widget.resumeId}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'templateName': _selectedTemplate}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final downloadUrl = 'http://${dotenv.env['ip']}${data['downloadUrl']}';

        // Download the file
        await _downloadAndOpenFile(downloadUrl, data['fileName']);

        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to generate document');
      }
    } catch (e) {
      print('Error generating document: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar documento')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadAndOpenFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get the documents directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';

        // Write the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Open the file
        await OpenFile.open(filePath);
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al descargar el archivo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleccionar Plantilla')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _templates.isEmpty
              ? Center(child: Text('No hay plantillas disponibles'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Selecciona una plantilla para tu CV:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 8),
                            child: RadioListTile<String>(
                              title: Text(template),
                              value: template,
                              groupValue: _selectedTemplate,
                              onChanged: (value) {
                                setState(() => _selectedTemplate = value);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isGenerating ? null : _generateFromTemplate,
                      child:
                          _isGenerating
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Generando...'),
                                ],
                              )
                              : Text('Generar CV'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
