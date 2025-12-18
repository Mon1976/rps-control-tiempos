import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/pdf_generator.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/registro_tiempo.dart';

class DashboardMejoradoScreen extends StatefulWidget {
  const DashboardMejoradoScreen({super.key});

  @override
  State<DashboardMejoradoScreen> createState() => _DashboardMejoradoScreenState();
}

class _DashboardMejoradoScreenState extends State<DashboardMejoradoScreen> {
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
  bool _isGeneratingPdf = false;

  // Paleta de colores vibrantes
  final List<Color> _coloresPastel = [
    const Color(0xFF6366F1), // Índigo
    const Color(0xFFEC4899), // Rosa
    const Color(0xFF10B981), // Verde
    const Color(0xFFF59E0B), // Ámbar
    const Color(0xFF8B5CF6), // Violeta
    const Color(0xFF14B8A6), // Turquesa
    const Color(0xFFEF4444), // Rojo
    const Color(0xFF3B82F6), // Azul
    const Color(0xFFF97316), // Naranja
    const Color(0xFF06B6D4), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _db
          .collection('registros_tiempo')
          .orderBy('fecha', descending: true)
          .get();

      final registros = snapshot.docs
          .map((doc) => RegistroTiempo.fromFirestore(doc))
          .toList();

      final categoriasSet = registros.map((r) => r.categoria).toSet();
      _categorias = categoriasSet.toList()..sort();

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

  void _aplicarFiltroRapido(String filtro) {
    final ahora = DateTime.now();
    setState(() {
      switch (filtro) {
        case 'hoy':
          _fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
          _fechaFin = ahora;
          break;
        case 'esta_semana':
          _fechaInicio = ahora.subtract(Duration(days: ahora.weekday - 1));
          _fechaFin = ahora;
          break;
        case 'este_mes':
          _fechaInicio = DateTime(ahora.year, ahora.month, 1);
          _fechaFin = ahora;
          break;
        case 'ultimo_mes':
          final mesAnterior = DateTime(ahora.year, ahora.month - 1, 1);
          _fechaInicio = mesAnterior;
          _fechaFin = DateTime(ahora.year, ahora.month, 0);
          break;
        case 'ultimo_trimestre':
          _fechaInicio = DateTime(ahora.year, ahora.month - 3, ahora.day);
          _fechaFin = ahora;
          break;
      }
    });
  }

  List<RegistroTiempo> get registrosFiltrados {
    return _registrosFiltrados.where((registro) {
      if (_fechaInicio != null && registro.fecha.isBefore(_fechaInicio!)) {
        return false;
      }
      if (_fechaFin != null && registro.fecha.isAfter(_fechaFin!)) {
        return false;
      }
      if (_categoriaSeleccionada != null &&
          registro.categoria != _categoriaSeleccionada) {
        return false;
      }
      if (_tipoSeleccionado != null && registro.tipo != _tipoSeleccionado) {
        return false;
      }
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
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(10));
  }

  Map<String, double> get horasPorComunidad {
    final Map<String, double> map = {};
    for (final registro in registrosFiltrados) {
      if (registro.comunidad != null && registro.comunidad!.isNotEmpty) {
        map[registro.comunidad!] =
            (map[registro.comunidad!] ?? 0) + registro.duracionHoras;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(10));
  }

  Map<String, int> get registrosPorTipo {
    final Map<String, int> map = {};
    for (final registro in registrosFiltrados) {
      map[registro.tipo] = (map[registro.tipo] ?? 0) + 1;
    }
    return map;
  }

  double get totalHoras {
    return registrosFiltrados.fold(0, (sum, r) => sum + r.duracionHoras);
  }

  double get promedioHorasPorRegistro {
    return registrosFiltrados.isEmpty 
        ? 0 
        : totalHoras / registrosFiltrados.length;
  }

  Future<void> _exportarCSV() async {
    try {
      final csv = StringBuffer();
      csv.writeln('ID,Fecha,Hora Inicio,Hora Fin,Duracion (HH:MM:SS),Descripcion,Categoria,Tipo,Comunidad');
      
      for (final registro in registrosFiltrados) {
        final horas = registro.duracionMinutos ~/ 60;
        final minutos = registro.duracionMinutos % 60;
        final duracion = '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:00';
        
        csv.writeln('"${registro.id}","${registro.fechaFormateada}","${registro.horaInicio}","${registro.horaFin}",'
            '"$duracion","${registro.descripcion}","${registro.categoria}","${registro.tipo}","${registro.comunidad ?? ''}"');
      }

      final bytes = utf8.encode(csv.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'registros_tiempo_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ CSV exportado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar CSV: $e')),
        );
      }
    }
  }

  Future<void> _generarPDF() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = await PdfGenerator.generarInformeProfesional(
        registros: registrosFiltrados,
        horasPorCategoria: horasPorCategoria,
        horasPorComunidad: horasPorComunidad,
        registrosPorTipo: registrosPorTipo,
        totalHoras: totalHoras,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        categoriaSeleccionada: _categoriaSeleccionada,
        tipoSeleccionado: _tipoSeleccionado,
        comunidadSeleccionada: _comunidadSeleccionada,
      );

      // Guardar y descargar PDF
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'informe_tiempos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF generado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Analítico')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Dashboard Analítico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportarCSV,
            tooltip: 'Exportar CSV',
          ),
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPdf ? null : _generarPDF,
            tooltip: 'Generar PDF',
          ),
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
            _buildFiltrosRapidos(),
            const SizedBox(height: 16),
            _buildFiltrosAvanzados(),
            const SizedBox(height: 24),
            _buildResumen(),
            const SizedBox(height: 24),
            _buildGraficas(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosRapidos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Filtros Rápidos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFiltroChip('Hoy', 'hoy', Icons.today),
                _buildFiltroChip('Esta Semana', 'esta_semana', Icons.date_range),
                _buildFiltroChip('Este Mes', 'este_mes', Icons.calendar_month),
                _buildFiltroChip('Último Mes', 'ultimo_mes', Icons.calendar_today),
                _buildFiltroChip('Último Trimestre', 'ultimo_trimestre', Icons.event_note),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String label, String filtro, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _aplicarFiltroRapido(filtro),
      backgroundColor: Colors.blue.shade50,
    );
  }

  Widget _buildFiltrosAvanzados() {
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
                  'Filtros Avanzados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                ),
                if (_tipoSeleccionado == 'comunidad') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
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
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen() {
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
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
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

  Widget _buildGraficas() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildGraficaBarras()),
            const SizedBox(width: 16),
            Expanded(child: _buildGraficaPastel()),
          ],
        ),
        if (horasPorComunidad.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildGraficaComunidades(),
        ],
      ],
    );
  }

  Widget _buildGraficaBarras() {
    final datos = horasPorCategoria;
    if (datos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No hay datos')),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          const TextStyle(color: Colors.white, fontSize: 12),
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
                              categoria.length > 12
                                  ? '${categoria.substring(0, 10)}...'
                                  : categoria,
                              style: const TextStyle(fontSize: 9),
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
                            style: const TextStyle(fontSize: 11),
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
                  barGroups: datos.entries.toList().asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: _coloresPastel[entry.key % _coloresPastel.length],
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
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

  Widget _buildGraficaPastel() {
    final datos = horasPorCategoria;
    if (datos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No hay datos')),
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
              'Distribución de Tiempo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: datos.entries.toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final data = entry.value;
                    final porcentaje = (data.value / totalHoras * 100);
                    return PieChartSectionData(
                      color: _coloresPastel[idx % _coloresPastel.length],
                      value: data.value,
                      title: '${porcentaje.toStringAsFixed(1)}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: datos.entries.toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _coloresPastel[idx % _coloresPastel.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.key.length > 20
                          ? '${data.key.substring(0, 18)}...'
                          : data.key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficaComunidades() {
    final datos = horasPorComunidad;
    if (datos.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apartment, color: Colors.purple, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Análisis por Comunidad (Top 10)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
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
                        final comunidad = datos.keys.elementAt(groupIndex);
                        final porcentaje = (rod.toY / totalHoras * 100);
                        return BarTooltipItem(
                          '$comunidad\n${rod.toY.toStringAsFixed(1)}h (${porcentaje.toStringAsFixed(1)}%)',
                          const TextStyle(color: Colors.white, fontSize: 12),
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
                          final comunidad = datos.keys.elementAt(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              comunidad.length > 10
                                  ? '${comunidad.substring(0, 8)}...'
                                  : comunidad,
                              style: const TextStyle(fontSize: 9),
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
                            style: const TextStyle(fontSize: 11),
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
                  barGroups: datos.entries.toList().asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          gradient: LinearGradient(
                            colors: [
                              _coloresPastel[entry.key % _coloresPastel.length],
                              _coloresPastel[entry.key % _coloresPastel.length].withOpacity(0.6),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.purple.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La comunidad "${datos.keys.first}" requiere ${datos.values.first.toStringAsFixed(1)} horas '
                      '(${(datos.values.first / totalHoras * 100).toStringAsFixed(1)}% del tiempo total)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
