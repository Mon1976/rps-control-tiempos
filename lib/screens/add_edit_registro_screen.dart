import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/registro_tiempo.dart';

class AddEditRegistroScreen extends StatefulWidget {
  final RegistroTiempo? registro;

  const AddEditRegistroScreen({super.key, this.registro});

  @override
  State<AddEditRegistroScreen> createState() => _AddEditRegistroScreenState();
}

class _AddEditRegistroScreenState extends State<AddEditRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late TextEditingController _descripcionController;
  late TextEditingController _horaInicioController;
  late TextEditingController _horaFinController;

  DateTime _fechaSeleccionada = DateTime.now();
  String _categoriaSeleccionada = 'Atención presencial en Despacho';
  String _tipoSeleccionado = 'comunidad';
  String? _comunidadSeleccionada;

  List<String> _comunidades = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _categorias = [
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
    _descripcionController = TextEditingController(
      text: widget.registro?.descripcion ?? '',
    );
    _horaInicioController = TextEditingController(
      text: widget.registro?.horaInicio ?? '09:00',
    );
    _horaFinController = TextEditingController(
      text: widget.registro?.horaFin ?? '10:00',
    );

    if (widget.registro != null) {
      _fechaSeleccionada = widget.registro!.fecha;
      _categoriaSeleccionada = widget.registro!.categoria;
      _tipoSeleccionado = widget.registro!.tipo;
      _comunidadSeleccionada = widget.registro!.comunidad;
    }

    _cargarComunidades();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _horaInicioController.dispose();
    _horaFinController.dispose();
    super.dispose();
  }

  Future<void> _cargarComunidades() async {
    try {
      final snapshot = await _db.collection('comunidades').get();
      setState(() {
        _comunidades = snapshot.docs
            .map((doc) => doc.data()['nombre'] as String? ?? '')
            .where((nombre) => nombre.isNotEmpty)
            .toList()
          ..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar comunidades: $e')),
        );
      }
    }
  }

  int _calcularDuracionMinutos() {
    try {
      final inicio = _parseTimeOfDay(_horaInicioController.text);
      final fin = _parseTimeOfDay(_horaFinController.text);

      final inicioMinutos = inicio.hour * 60 + inicio.minute;
      final finMinutos = fin.hour * 60 + fin.minute;

      return finMinutos - inicioMinutos;
    } catch (e) {
      return 0;
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _seleccionarHora(TextEditingController controller) async {
    final partes = controller.text.split(':');
    final horaActual = TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 9,
      minute: int.tryParse(partes[1]) ?? 0,
    );

    final hora = await showTimePicker(
      context: context,
      initialTime: horaActual,
    );

    if (hora != null) {
      controller.text =
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
      setState(() {}); // Actualizar duración
    }
  }

  Future<void> _guardarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipoSeleccionado == 'comunidad' && _comunidadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una comunidad'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final duracion = _calcularDuracionMinutos();
    if (duracion <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser posterior a la hora de inicio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final docData = {
        'fecha': Timestamp.fromDate(_fechaSeleccionada),
        'horaInicio': _horaInicioController.text,
        'horaFin': _horaFinController.text,
        'duracionMinutos': duracion,
        'descripcion': _descripcionController.text.trim(),
        'categoria': _categoriaSeleccionada,
        'tipo': _tipoSeleccionado,
        'comunidad': _tipoSeleccionado == 'comunidad' ? _comunidadSeleccionada : null,
      };

      if (widget.registro == null) {
        // Crear nuevo
        await _db.collection('registros_tiempo').add(docData);
      } else {
        // Actualizar existente
        await _db.collection('registros_tiempo').doc(widget.registro!.id).update(docData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.registro == null
                  ? '✅ Registro creado correctamente'
                  : '✅ Registro actualizado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true indica que se guardó
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.registro == null ? 'Nuevo Registro' : 'Editar Registro'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final duracion = _calcularDuracionMinutos();
    final duracionHoras = duracion ~/ 60;
    final duracionMinutos = duracion % 60;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.registro == null ? 'Nuevo Registro' : 'Editar Registro'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Fecha
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _seleccionarFecha,
              ),
            ),
            const SizedBox(height: 16),

            // Horas
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.green),
                      title: const Text('Hora Inicio'),
                      subtitle: Text(_horaInicioController.text),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _seleccionarHora(_horaInicioController),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.red),
                      title: const Text('Hora Fin'),
                      subtitle: Text(_horaFinController.text),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _seleccionarHora(_horaFinController),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Duración calculada
            Card(
              color: duracion > 0 ? Colors.blue.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: duracion > 0 ? Colors.blue : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      duracion > 0
                          ? 'Duración: ${duracionHoras}h ${duracionMinutos}m'
                          : 'Duración inválida',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: duracion > 0 ? Colors.blue : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                hintText: 'Describe la actividad realizada...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La descripción es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoría
            DropdownButtonFormField<String>(
              value: _categoriaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categorias.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(
                    cat,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _categoriaSeleccionada = value!);
              },
            ),
            const SizedBox(height: 16),

            // Tipo
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'comunidad',
                  child: Text('Comunidad'),
                ),
                DropdownMenuItem(
                  value: 'general',
                  child: Text('General'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoSeleccionado = value!;
                  if (value == 'general') {
                    _comunidadSeleccionada = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Comunidad
            if (_tipoSeleccionado == 'comunidad')
              DropdownButtonFormField<String>(
                value: _comunidadSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Comunidad *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apartment),
                ),
                items: _comunidades.map((com) {
                  return DropdownMenuItem(
                    value: com,
                    child: Text(com),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _comunidadSeleccionada = value);
                },
              ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardarRegistro,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
