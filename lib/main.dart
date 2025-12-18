import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/registros_screen.dart';
import 'screens/import_screen.dart';
import 'screens/dashboard_mejorado_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPS Control de Tiempos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Verificando Firebase...';
  List<String> _collections = [];
  bool _hasRegistros = false;

  @override
  void initState() {
    super.initState();
    _checkFirebase();
  }

  Future<void> _checkFirebase() async {
    try {
      final db = FirebaseFirestore.instance;
      
      // Verificar colecciones existentes
      final testCollections = ['comunidades', 'siniestros', 'incidencias', 'registros_tiempo'];
      final found = <String>[];
      
      for (final collectionName in testCollections) {
        try {
          final snapshot = await db.collection(collectionName).limit(1).get();
          if (snapshot.docs.isNotEmpty) {
            final count = await db.collection(collectionName).count().get();
            found.add('$collectionName (${count.count} docs)');
            if (collectionName == 'registros_tiempo') {
              _hasRegistros = true;
            }
          }
        } catch (e) {
          debugPrint('Error checking $collectionName: $e');
        }
      }
      
      setState(() {
        _status = found.isEmpty ? 'Firebase conectado - No hay colecciones' : 'Firebase conectado ✅';
        _collections = found;
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RPS Control de Tiempos'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (_collections.isNotEmpty) ...[
                const Text(
                  'Colecciones encontradas:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ..._collections.map((col) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '• $col',
                    style: const TextStyle(fontSize: 16),
                  ),
                )),
              ],
              const SizedBox(height: 30),
              if (_hasRegistros) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardMejoradoScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Dashboard Analítico'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistrosScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Ver Todos los Registros'),
                ),
              ]
              else
                const Text(
                  'No hay registros aún.\nImporta el CSV para comenzar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImportScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _checkFirebase,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
