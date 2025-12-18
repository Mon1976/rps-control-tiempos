import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/registros_screen.dart';
import 'screens/import_screen.dart';
import 'screens/dashboard_mejorado_screen.dart';
import 'screens/temporizador_screen.dart';
import 'screens/add_edit_registro_screen.dart';
import 'screens/gestion_comunidades_screen.dart';
import 'screens/gestion_categorias_screen.dart';

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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header compacto
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RPS Control de Tiempos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (_hasRegistros)
                            Text(
                              '${_collections.firstWhere((c) => c.contains('registros_tiempo'), orElse: () => '0 registros').split('(')[1].replaceAll(')', '').replaceAll(' docs', '')} registros',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _checkFirebase,
                      icon: Icon(Icons.refresh, color: Colors.grey[600]),
                      tooltip: 'Actualizar',
                    ),
                  ],
                ),
              ),

              // Lista de acciones principales
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones Principales',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Temporizador
                    _buildListTile(
                      title: 'Temporizador',
                      subtitle: 'Registra tu tiempo en directo',
                      icon: Icons.play_circle_filled,
                      iconColor: const Color(0xFF00C853),
                      iconBgColor: const Color(0xFF00C853).withValues(alpha: 0.1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TemporizadorScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Registro Manual
                    _buildListTile(
                      title: 'Registro Manual',
                      subtitle: 'Añade una actividad pasada',
                      icon: Icons.edit_calendar,
                      iconColor: const Color(0xFF2196F3),
                      iconBgColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditRegistroScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Dashboard
                    _buildListTile(
                      title: 'Dashboard Analítico',
                      subtitle: 'Análisis, gráficas y reportes PDF',
                      icon: Icons.analytics,
                      iconColor: const Color(0xFF7B1FA2),
                      iconBgColor: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardMejoradoScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Registros
                    _buildListTile(
                      title: 'Ver Registros',
                      subtitle: 'Consulta y edita tus actividades',
                      icon: Icons.list_alt,
                      iconColor: const Color(0xFFFF6F00),
                      iconBgColor: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistrosScreen(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Gestión
                    Text(
                      'Gestión',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Comunidades
                    _buildListTile(
                      title: 'Comunidades',
                      subtitle: 'Crear, editar y eliminar comunidades',
                      icon: Icons.apartment,
                      iconColor: const Color(0xFF1976D2),
                      iconBgColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GestionComunidadesScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Categorías
                    _buildListTile(
                      title: 'Categorías',
                      subtitle: 'Crear, editar y eliminar categorías',
                      icon: Icons.category,
                      iconColor: const Color(0xFF7B1FA2),
                      iconBgColor: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GestionCategoriasScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Importar CSV
                    _buildListTile(
                      title: 'Importar CSV',
                      subtitle: 'Cargar registros desde archivo',
                      icon: Icons.upload_file,
                      iconColor: const Color(0xFF00897B),
                      iconBgColor: const Color(0xFF00897B).withValues(alpha: 0.1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImportScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Flecha
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
