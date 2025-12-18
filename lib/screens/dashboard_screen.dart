import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/registro_tiempo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _categoriaSeleccionada;
  String? _tipoSeleccionado;
  String? _comunidadSeleccionada;
  
  List<RegistroTiempo> _registrosFiltrados = [];
  List<String> _categorias = [];
  List<String> _comunidades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Cargar todos los registros
      final snapshot = await _db
          .collection('registros_tiempo')
          .orderBy('fecha', descending: true)
          .get();

      final registros = snapshot.docs
          .map((doc) => RegistroTiempo.fromFirestore(doc))
          .toList();

      // Extraer categorías únicas
      final categoriasSet = registros.map((r) => r.categoria).toSet();
      _categorias = categoriasSet.toList()..sort();

      // Extraer comunidades únicas
      final comunidadesSet = registros
          .where((r) => r.comunidad != null && r.comunidad!.isNotEmpty)
          .map((r) => r.comunidad!)
          .toSet();
      _comunidades = comunidadesSet.toList()..sort();

      setState(() {
        _registrosFiltrados = registros;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<RegistroTiempo> get registrosFiltrados {
    return _registrosFiltrados.where((registro) {
      // Filtro por fecha
      if (_fechaInicio != null && registro.fecha.isBefore(_fechaInicio!)) {
        return false;
      }
      if (_fechaFin != null && registro.fecha.isAfter(_fechaFin!)) {
        return false;
      }

      // Filtro por categoría
      if (_categoriaSeleccionada != null &&
          registro.categoria != _categoriaSeleccionada) {
        return false;
      }

      // Filtro por tipo
      if (_tipoSeleccionado != null && registro.tipo != _tipoSeleccionado) {
        return false;
      }

      // Filtro por comunidad
      if (_comunidadSeleccionada != null &&
          registro.comunidad != _comunidadSeleccionada) {
        return false;
      }

      return true;
    }).toList();
  }

  Map<String, double> get horasPorCategoria {
    final Map<String, double> map = {};
    for (final registro in registrosFiltrados) {
      map[registro.categoria] =
          (map[registro.categoria] ?? 0) + registro.duracionHoras;
    }
    // Ordenar por horas descendente y tomar top 10
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(10));
  }

  double get totalHoras {
    return registrosFiltrados.fold(0, (sum, r) => sum + r.duracionHoras);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Analítico'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Dashboard Analítico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros
            _buildFiltrosSection(),
            const SizedBox(height: 24),

            // Resumen
            _buildResumenSection(),
            const SizedBox(height: 24),

            // Gráfica de barras
            _buildGraficaBarras(),
            const SizedBox(height: 24),

            // Lista resumida
            _buildListaResumida(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_fechaInicio != null ||
                    _fechaFin != null ||
                    _categoriaSeleccionada != null ||
                    _tipoSeleccionado != null ||
                    _comunidadSeleccionada != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _fechaInicio = null;
                        _fechaFin = null;
                        _categoriaSeleccionada = null;
                        _tipoSeleccionado = null;
                        _comunidadSeleccionada = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Rango de fechas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Fecha inicio
                OutlinedButton.icon(
                  onPressed: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: _fechaInicio ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (fecha != null) {
                      setState(() => _fechaInicio = fecha);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _fechaInicio != null
                        ? 'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}'
                        : 'Fecha inicio',
                  ),
                ),

                // Fecha fin
                OutlinedButton.icon(
                  onPressed: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: _fechaFin ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (fecha != null) {
                      setState(() => _fechaFin = fecha);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _fechaFin != null
                        ? 'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}'
                        : 'Fecha fin',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Categoría
            DropdownButtonFormField<String>(
              value: _categoriaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._categorias.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    )),
              ],
              onChanged: (value) => setState(() => _categoriaSeleccionada = value),
            ),
            const SizedBox(height: 12),

            // Tipo
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'comunidad', child: Text('Comunidad')),
                DropdownMenuItem(value: 'general', child: Text('General')),
              ],
              onChanged: (value) => setState(() => _tipoSeleccionado = value),
            ),
            const SizedBox(height: 12),

            // Comunidad
            if (_tipoSeleccionado == 'comunidad')
              DropdownButtonFormField<String>(
                value: _comunidadSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Comunidad',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ..._comunidades.map((com) => DropdownMenuItem(
                        value: com,
                        child: Text(com),
                      )),
                ],
                onChanged: (value) =>
                    setState(() => _comunidadSeleccionada = value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenSection() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard(
              'Registros',
              registrosFiltrados.length.toString(),
              Icons.list_alt,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Horas',
              totalHoras.toStringAsFixed(1),
              Icons.access_time,
              Colors.green,
            ),
            _buildStatCard(
              'Categorías',
              horasPorCategoria.length.toString(),
              Icons.category,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildGraficaBarras() {
    final datos = horasPorCategoria;
    if (datos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No hay datos para mostrar'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Horas por Categoría (Top 10)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: datos.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final categoria = datos.keys.elementAt(groupIndex);
                        return BarTooltipItem(
                          '$categoria\n${rod.toY.toStringAsFixed(1)}h',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= datos.length) return const Text('');
                          final categoria = datos.keys.elementAt(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              categoria.length > 15
                                  ? '${categoria.substring(0, 12)}...'
                                  : categoria,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: datos.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaResumida() {
    final registros = registrosFiltrados.take(20).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Últimos ${registros.length} registros',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...registros.map((registro) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 20,
                    child: Text(
                      registro.duracionFormateada.split(' ')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    registro.descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${registro.categoria} • ${registro.fechaFormateada}',
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
