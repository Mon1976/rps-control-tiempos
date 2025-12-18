import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RegistroTiempo {
  final String? id;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final int duracionMinutos;
  final String descripcion;
  final String categoria;
  final String tipo;
  final String? comunidad;

  RegistroTiempo({
    this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.duracionMinutos,
    required this.descripcion,
    required this.categoria,
    required this.tipo,
    this.comunidad,
  });

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'duracionMinutos': duracionMinutos,
      'descripcion': descripcion,
      'categoria': categoria,
      'tipo': tipo,
      'comunidad': comunidad,
    };
  }

  // Crear desde documento de Firebase
  factory RegistroTiempo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistroTiempo(
      id: doc.id,
      fecha: (data['fecha'] as Timestamp).toDate(),
      horaInicio: data['horaInicio'] ?? '',
      horaFin: data['horaFin'] ?? '',
      duracionMinutos: data['duracionMinutos'] ?? 0,
      descripcion: data['descripcion'] ?? '',
      categoria: data['categoria'] ?? '',
      tipo: data['tipo'] ?? '',
      comunidad: data['comunidad'],
    );
  }

  // Formatear fecha para mostrar
  String get fechaFormateada => DateFormat('dd/MM/yyyy').format(fecha);

  // Formatear duración en horas y minutos
  String get duracionFormateada {
    final horas = duracionMinutos ~/ 60;
    final minutos = duracionMinutos % 60;
    if (horas > 0) {
      return '${horas}h ${minutos}m';
    }
    return '${minutos}m';
  }

  // Duración en horas decimales
  double get duracionHoras => duracionMinutos / 60.0;
}
