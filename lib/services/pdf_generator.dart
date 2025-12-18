import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/registro_tiempo.dart';

class PdfGenerator {
  static Future<pw.Document> generarInformeProfesional({
    required List<RegistroTiempo> registros,
    required Map<String, double> horasPorCategoria,
    required Map<String, double> horasPorComunidad,
    required Map<String, int> registrosPorTipo,
    required double totalHoras,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? categoriaSeleccionada,
    String? tipoSeleccionado,
    String? comunidadSeleccionada,
  }) async {
    final pdf = pw.Document();

    // Generar conclusiones automáticas
    final conclusiones = _generarConclusiones(
      registros: registros,
      horasPorCategoria: horasPorCategoria,
      horasPorComunidad: horasPorComunidad,
      totalHoras: totalHoras,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // PORTADA
          _buildPortada(),
          pw.SizedBox(height: 12),

          // PERÍODO DEL INFORME
          _buildPeriodoInfo(
            fechaInicio,
            fechaFin,
            categoriaSeleccionada,
            tipoSeleccionado,
            comunidadSeleccionada,
          ),
          pw.SizedBox(height: 12),

          // RESUMEN EJECUTIVO
          _buildResumenEjecutivo(
            registros.length,
            totalHoras,
            horasPorCategoria.length,
            registros.isEmpty ? 0 : totalHoras / registros.length,
          ),
          pw.SizedBox(height: 12),

          // GRÁFICO: DISTRIBUCIÓN POR CATEGORÍA
          _buildGraficoBarrasCategoria(horasPorCategoria, totalHoras),
          pw.SizedBox(height: 12),

          // TABLA: ANÁLISIS POR CATEGORÍA
          _buildTablaCategoria(horasPorCategoria, totalHoras),
          pw.SizedBox(height: 12),

          // ANÁLISIS POR COMUNIDAD (si hay datos)
          if (horasPorComunidad.isNotEmpty) ...[
            _buildAnalisisComunidades(horasPorComunidad, totalHoras),
            pw.SizedBox(height: 12),
          ],

          // DISTRIBUCIÓN POR TIPO
          _buildDistribucionTipo(registrosPorTipo, registros.length),
          pw.SizedBox(height: 12),

          // CONCLUSIONES Y RECOMENDACIONES
          _buildConclusiones(conclusiones),
          pw.SizedBox(height: 12),

          // PIE DE PÁGINA
          _buildPiePagina(),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildPortada() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.blue900, PdfColors.blue600],
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RPS ADMINISTRACIÓN DE FINCAS',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: 80,
            height: 2,
            color: PdfColors.orange,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'INFORME ANALÍTICO - Control de Tiempos',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPeriodoInfo(
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? categoria,
    String? tipo,
    String? comunidad,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 20,
                color: PdfColors.blue700,
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'PERÍODO Y FILTROS APLICADOS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem(
                  'Desde:',
                  fechaInicio != null
                      ? DateFormat('dd/MM/yyyy').format(fechaInicio)
                      : 'Todos los registros',
                ),
              ),
              pw.Expanded(
                child: _buildInfoItem(
                  'Hasta:',
                  fechaFin != null
                      ? DateFormat('dd/MM/yyyy').format(fechaFin)
                      : 'Hasta la fecha',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem('Categoría:', categoria ?? 'Todas'),
              ),
              pw.Expanded(
                child: _buildInfoItem('Tipo:', tipo ?? 'Todos'),
              ),
            ],
          ),
          if (comunidad != null)
            _buildInfoItem('Comunidad:', comunidad),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildResumenEjecutivo(
    int totalRegistros,
    double totalHoras,
    int numCategorias,
    double promedioHoras,
  ) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 20,
                color: PdfColors.green700,
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'RESUMEN EJECUTIVO',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox(
                'Total Registros',
                totalRegistros.toString(),
                PdfColors.blue700,
                'actividades registradas',
              ),
              _buildStatBox(
                'Total Horas',
                totalHoras.toStringAsFixed(1),
                PdfColors.green700,
                'horas trabajadas',
              ),
              _buildStatBox(
                'Categorías',
                numCategorias.toString(),
                PdfColors.orange700,
                'tipos de actividades',
              ),
              _buildStatBox(
                'Promedio',
                promedioHoras.toStringAsFixed(2),
                PdfColors.purple700,
                'horas por registro',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(
    String label,
    String value,
    PdfColor color,
    String subtitle,
  ) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGraficoBarrasCategoria(
    Map<String, double> datos,
    double totalHoras,
  ) {
    if (datos.isEmpty) return pw.Container();

    final maxValor = datos.values.reduce((a, b) => a > b ? a : b);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: PdfColors.orange700,
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              'DISTRIBUCIÓN DE HORAS POR CATEGORÍA',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        ...datos.entries.map((entry) {
          final porcentaje = (entry.value / totalHoras * 100);
          final barWidth = (entry.value / maxValor * 400);

          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 120,
                  child: pw.Text(
                    entry.key.length > 20
                        ? '${entry.key.substring(0, 18)}...'
                        : entry.key,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
                pw.Container(
                  width: barWidth,
                  height: 20,
                  decoration: const pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [PdfColors.blue700, PdfColors.blue400],
                    ),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${entry.value.toStringAsFixed(1)}h',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  '${porcentaje.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTablaCategoria(
    Map<String, double> datos,
    double totalHoras,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableHeader('Categoría'),
            _buildTableHeader('Horas'),
            _buildTableHeader('Porcentaje'),
          ],
        ),
        // Datos
        ...datos.entries.map((entry) {
          final porcentaje = (entry.value / totalHoras * 100);
          return pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey50),
            children: [
              _buildTableCell(entry.key),
              _buildTableCell(entry.value.toStringAsFixed(1)),
              _buildTableCell('${porcentaje.toStringAsFixed(1)}%'),
            ],
          );
        }),
        // Total
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableCell('TOTAL', isBold: true),
            _buildTableCell(totalHoras.toStringAsFixed(1), isBold: true),
            _buildTableCell('100%', isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _buildAnalisisComunidades(
    Map<String, double> datos,
    double totalHoras,
  ) {
    if (datos.isEmpty) return pw.Container();

    final top5 = datos.entries.take(5).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: PdfColors.purple700,
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              'TOP 5 COMUNIDADES POR HORAS DEDICADAS',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Encabezado
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.purple700),
              children: [
                _buildTableHeader('#'),
                _buildTableHeader('Comunidad'),
                _buildTableHeader('Horas'),
                _buildTableHeader('%'),
              ],
            ),
            // Datos
            ...top5.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final porcentaje = (data.value / totalHoras * 100);
              
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index.isEven ? PdfColors.grey50 : PdfColors.white,
                ),
                children: [
                  _buildTableCell('${index + 1}'),
                  _buildTableCell(data.key),
                  _buildTableCell(data.value.toStringAsFixed(1)),
                  _buildTableCell('${porcentaje.toStringAsFixed(1)}%'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDistribucionTipo(
    Map<String, int> datos,
    int totalRegistros,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: PdfColors.teal700,
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              'DISTRIBUCIÓN POR TIPO DE ACTIVIDAD',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: datos.entries.map((entry) {
            final porcentaje = (entry.value / totalRegistros * 100);
            return pw.Container(
              width: 200,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: entry.key == 'comunidad' 
                    ? PdfColors.blue50 
                    : PdfColors.green50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(
                  color: entry.key == 'comunidad' 
                      ? PdfColors.blue400 
                      : PdfColors.green400,
                  width: 2,
                ),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    entry.key.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: entry.key == 'comunidad' 
                          ? PdfColors.blue900 
                          : PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    '${entry.value}',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: entry.key == 'comunidad' 
                          ? PdfColors.blue700 
                          : PdfColors.green700,
                    ),
                  ),
                  pw.Text(
                    'registros',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${porcentaje.toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: entry.key == 'comunidad' 
                          ? PdfColors.blue600 
                          : PdfColors.green600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildConclusiones(List<String> conclusiones) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.amber400, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.amber700,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Icon(
                  pw.IconData(0xe87e), // lightbulb icon
                  color: PdfColors.white,
                  size: 16,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'CONCLUSIONES Y RECOMENDACIONES',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          ...conclusiones.asMap().entries.map((entry) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 20,
                    height: 20,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.amber700,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '${entry.key + 1}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Text(
                      entry.value,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildPiePagina() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'RPS Administración de Fincas',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static List<String> _generarConclusiones({
    required List<RegistroTiempo> registros,
    required Map<String, double> horasPorCategoria,
    required Map<String, double> horasPorComunidad,
    required double totalHoras,
  }) {
    final conclusiones = <String>[];

    // Conclusión 1: Categoría principal
    if (horasPorCategoria.isNotEmpty) {
      final principal = horasPorCategoria.entries.first;
      final porcentaje = (principal.value / totalHoras * 100);
      conclusiones.add(
        'La categoría "${principal.key}" representa el mayor consumo de tiempo con '
        '${principal.value.toStringAsFixed(1)} horas (${porcentaje.toStringAsFixed(1)}% del total), '
        'siendo la actividad que requiere mayor dedicación en el período analizado.',
      );
    }

    // Conclusión 2: Comunidad que más tiempo requiere
    if (horasPorComunidad.isNotEmpty) {
      final principalCom = horasPorComunidad.entries.first;
      final porcentajeCom = (principalCom.value / totalHoras * 100);
      conclusiones.add(
        'La comunidad "${principalCom.key}" es la que más tiempo requiere con '
        '${principalCom.value.toStringAsFixed(1)} horas (${porcentajeCom.toStringAsFixed(1)}% del total). '
        'Se recomienda evaluar si esta carga de trabajo es sostenible o requiere apoyo adicional.',
      );
    }

    // Conclusión 3: Promedio de tiempo
    if (registros.isNotEmpty) {
      final promedio = totalHoras / registros.length;
      if (promedio < 0.5) {
        conclusiones.add(
          'El promedio de ${promedio.toStringAsFixed(2)} horas por registro indica actividades '
          'mayormente breves y puntuales. Se recomienda optimizar la documentación de estas tareas '
          'para reducir el tiempo administrativo.',
        );
      } else if (promedio > 2) {
        conclusiones.add(
          'El promedio de ${promedio.toStringAsFixed(2)} horas por registro sugiere actividades '
          'complejas que requieren dedicación significativa. Se recomienda evaluar si es posible '
          'subdividir estas tareas o delegar parte del trabajo.',
        );
      } else {
        conclusiones.add(
          'El promedio de ${promedio.toStringAsFixed(2)} horas por registro indica una distribución '
          'equilibrada entre tareas breves y actividades que requieren mayor dedicación.',
        );
      }
    }

    // Conclusión 4: Diversidad de categorías
    if (horasPorCategoria.length >= 10) {
      conclusiones.add(
        'Se observa una alta diversidad de actividades (${horasPorCategoria.length} categorías), '
        'lo que indica versatilidad en la gestión. Se recomienda evaluar si algunas categorías '
        'podrían agruparse para simplificar el seguimiento.',
      );
    } else if (horasPorCategoria.length <= 3) {
      conclusiones.add(
        'La concentración en pocas categorías (${horasPorCategoria.length}) indica especialización. '
        'Se recomienda evaluar si hay áreas de gestión desatendidas que requieran mayor atención.',
      );
    }

    // Conclusión 5: Distribución de comunidades
    if (horasPorComunidad.length >= 10) {
      final top3Horas = horasPorComunidad.values.take(3).reduce((a, b) => a + b);
      final porcentajeTop3 = (top3Horas / totalHoras * 100);
      conclusiones.add(
        'Las 3 comunidades principales concentran el ${porcentajeTop3.toStringAsFixed(1)}% del tiempo. '
        'Se recomienda revisar la distribución de cargas para garantizar atención equitativa a todas '
        'las comunidades gestionadas.',
      );
    }

    return conclusiones;
  }
}
