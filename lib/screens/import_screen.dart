import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'dart:convert';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  String _status = 'Selecciona el archivo CSV para importar';
  int _imported = 0;
  int _total = 0;
  int _errors = 0;

  Future<void> _pickAndImportFile() async {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;

      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) async {
        final content = reader.result as String;
        await _importCsvContent(content);
      });

      reader.readAsText(file);
    });
  }

  Future<void> _importCsvContent(String csvContent) async {
    setState(() {
      _isImporting = true;
      _status = 'Analizando archivo...';
      _imported = 0;
      _errors = 0;
    });

    try {
      final lines = const LineSplitter().convert(csvContent);
      if (lines.isEmpty) {
        throw Exception('Archivo vacío');
      }

      // Saltar encabezado
      final dataLines = lines.skip(1).toList();
      _total = dataLines.length;

      setState(() {
        _status = 'Importando $_total registros...';
      });

      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      int batchCount = 0;

      for (var i = 0; i < dataLines.length; i++) {
        try {
          final line = dataLines[i];
          if (line.trim().isEmpty) continue;

          // Parsear CSV (considerando campos con comas dentro de comillas)
          final fields = _parseCsvLine(line);
          
          if (fields.length < 9) {
            _errors++;
            continue;
          }

          // Preparar datos
          final docData = {
            'fecha': _parseDate(fields[1]),
            'horaInicio': fields[2],
            'horaFin': fields[3],
            'duracionMinutos': _parseDuration(fields[4]),
            'descripcion': fields[5].replaceAll('"', ''),
            'categoria': fields[6],
            'tipo': fields[7],
            'comunidad': fields[8].replaceAll('"', '').trim(),
          };

          // Usar el ID del CSV
          final docId = fields[0];
          final docRef = db.collection('registros_tiempo').doc(docId);
          batch.set(docRef, docData);

          batchCount++;
          _imported++;

          // Firestore permite máximo 500 operaciones por batch
          if (batchCount >= 500) {
            await batch.commit();
            setState(() {
              _status = 'Importados $_imported de $_total registros...';
            });
            // Crear nuevo batch
            batchCount = 0;
          }
        } catch (e) {
          _errors++;
          debugPrint('Error en línea ${i + 1}: $e');
        }
      }

      // Commit final
      if (batchCount > 0) {
        await batch.commit();
      }

      setState(() {
        _isImporting = false;
        _status = '✅ Importación completada!\n'
            '$_imported registros importados\n'
            '${_errors > 0 ? "$_errors errores" : "Sin errores"}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $_imported registros importados correctamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _status = '❌ Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
        current.write(char);
      } else if (char == ',' && !inQuotes) {
        fields.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }

    fields.add(current.toString());
    return fields;
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  int _parseDuration(String duration) {
    try {
      final parts = duration.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = parts.length > 2 ? int.parse(parts[2]) : 0;
      return hours * 60 + minutes + (seconds ~/ 60);
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Importar CSV'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.upload_file,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (_isImporting) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _total > 0 ? _imported / _total : null,
                ),
                const SizedBox(height: 10),
                Text(
                  '$_imported / $_total',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isImporting ? null : _pickAndImportFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('Seleccionar archivo CSV'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
