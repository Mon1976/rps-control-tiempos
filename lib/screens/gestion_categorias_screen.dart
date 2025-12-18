import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionCategoriasScreen extends StatefulWidget {
  const GestionCategoriasScreen({super.key});

  @override
  State<GestionCategoriasScreen> createState() => _GestionCategoriasScreenState();
}

class _GestionCategoriasScreenState extends State<GestionCategoriasScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading = true;

  final List<String> _categoriasPredefinidas = [
    'Atención presencial en Despacho',
    'Atención Telefónica',
    'Contabilidad',
    'Gestiones fuera del Despacho',
    'Gestiones Bancarias',
    'Preparación Juntas de Propietarios',
    'Reuniones',
    'Redacción de Actas',
    'Registro de incidencias',
    'Seguros (presupuestos, consultas, etc)',
    'Siniestros',
    'Formación',
    'Gestión General Despacho',
    'Comunicados y comunicaciones',
    'Remesas de Recibos',
    'Gestión extrajudicial deudas propietarios',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final snapshot = await _db.collection('categorias').get();
      
      if (snapshot.docs.isEmpty) {
        // Si no hay categorías en Firebase, usar las predefinidas
        setState(() {
          _categorias = _categoriasPredefinidas
              .map((nombre) => {'id': '', 'nombre': nombre, 'predefinida': true})
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _categorias = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'nombre': doc.data()['nombre'] as String? ?? '',
                    'predefinida': false,
                  })
              .toList()
            ..sort((a, b) => (a['nombre'] as String).compareTo(b['nombre'] as String));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    }
  }

  Future<void> _crearCategoria() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.category, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            const Text('Nueva Categoría'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Asesoría Legal',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) {
                Navigator.pop(context, nombre);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _db.collection('categorias').add({'nombre': result});
        _cargarCategorias();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Categoría "$result" creada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
  }

  Future<void> _editarCategoria(String id, String nombreActual) async {
    final controller = TextEditingController(text: nombreActual);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Editar Categoría'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) {
                Navigator.pop(context, nombre);
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != nombreActual) {
      try {
        await _db.collection('categorias').doc(id).update({'nombre': result});
        _cargarCategorias();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Categoría actualizada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
  }

  Future<void> _eliminarCategoria(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('¿Eliminar categoría?'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar "$nombre"?\n\nEsta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.collection('categorias').doc(id).delete();
        _cargarCategorias();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Categoría "$nombre" eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.category, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Gestión de Categorías',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay categorías',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primera categoría',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categorias.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final categoria = _categorias[index];
                    final esPredefinida = categoria['predefinida'] as bool? ?? false;
                    
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.category, color: Colors.purple, size: 28),
                        ),
                        title: Text(
                          categoria['nombre'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: esPredefinida 
                            ? Text(
                                'Categoría predefinida',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              )
                            : null,
                        trailing: esPredefinida 
                            ? null 
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _editarCategoria(
                                      categoria['id'] as String,
                                      categoria['nombre'] as String,
                                    ),
                                    icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    onPressed: () => _eliminarCategoria(
                                      categoria['id'] as String,
                                      categoria['nombre'] as String,
                                    ),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearCategoria,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Categoría',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
