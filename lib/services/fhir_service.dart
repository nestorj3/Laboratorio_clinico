import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paciente.dart';
import '../models/observacion.dart';
import '../models/reporte_diagnostico.dart';
import '../models/medico.dart';
import '../models/condicion.dart';

class FhirService {
  static const String _baseUrl = 'https://hapi.fhir.org/baseR4';

  static const Map<String, String> _headers = {
    'Accept': 'application/fhir+json',
    'Content-Type': 'application/fhir+json',
  };

  // ── Pacientes ─────────────────────────────────────────────────

  /// Obtiene una lista de pacientes del laboratorio.
  Future<List<Paciente>> obtenerPacientes({int count = 20}) async {
    final uri = Uri.parse('$_baseUrl/Patient?_count=$count&_format=json');
    try {
      final response = await http.get(uri, headers: _headers);
      _validarRespuesta(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final recursos = _parsearBundle(json);
      return recursos.map((r) => Paciente.fromFhir(r)).toList();
    } catch (e) {
      throw _manejarError('obtenerPacientes', e);
    }
  }

  /// Obtiene el detalle de un paciente por su ID.
  Future<Paciente> obtenerPaciente(String id) async {
    final uri = Uri.parse('$_baseUrl/Patient/$id?_format=json');
    try {
      final response = await http.get(uri, headers: _headers);
      _validarRespuesta(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return Paciente.fromFhir(json);
    } catch (e) {
      throw _manejarError('obtenerPaciente', e);
    }
  }

  /// Busca pacientes por nombre usando el API FHIR.
  Future<List<Paciente>> buscarPacientesPorNombre(String nombre) async {
    final uri = Uri.parse(
        '$_baseUrl/Patient?name=${Uri.encodeComponent(nombre)}&_format=json');
    try {
      final response = await http.get(uri, headers: _headers);
      _validarRespuesta(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final recursos = _parsearBundle(json);
      return recursos.map((r) => Paciente.fromFhir(r)).toList();
    } catch (e) {
      throw _manejarError('buscarPacientesPorNombre', e);
    }
  }

  // ── Observaciones ─────────────────────────────────────────────

  /// Obtiene resultados de exámenes de laboratorio.
  Future<List<Observacion>> obtenerObservaciones({int count = 20}) async {
    final uri =
        Uri.parse('$_baseUrl/Observation?_count=$count&_format=json');
    try {
      final response = await http.get(uri, headers: _headers);
      _validarRespuesta(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final recursos = _parsearBundle(json);
      return recursos.map((r) => Observacion.fromFhir(r)).toList();
    } catch (e) {
      throw _manejarError('obtenerObservaciones', e);
    }
  }

  /// Obtiene las observaciones/resultados de un paciente específico.
  Future<List<Observacion>> obtenerObservacionesPaciente(
      String pacienteId) async {
    final uri = Uri.parse(
        '$_baseUrl/Observation?patient=$pacienteId&_format=json');
    try {
      final response = await http.get(uri, headers: _headers);
      _validarRespuesta(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final recursos = _parsearBundle(json);
      return recursos.map((r) => Observacion.fromFhir(r)).toList();
    } catch (e) {
      throw _manejarError('obtenerObservacionesPaciente', e);
    }
  }

  // ── Reportes Diagnósticos ────────────────────────────────────

  /// Obtiene reportes diagnósticos completos.
  Future<List<ReporteDiagnostico>> obtenerReportesDiagnosticos(
      {int count = 20}) async {
    final uri = Uri.parse(
        '$_baseUrl/DiagnosticReport?_count=$count&_format=json');
    try {
      final response = await http.get(uri, headers: _headers);
      _validarRespuesta(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final recursos = _parsearBundle(json);
      return recursos
          .map((r) => ReporteDiagnostico.fromFhir(r))
          .toList();
    } catch (e) {
      throw _manejarError('obtenerReportesDiagnosticos', e);
    }
  }

  // ── Médicos ───────────────────────────────────────────────────

  /// Obtiene la lista de médicos y especialistas.
  Future<List<Medico>> obtenerMedicos({int count = 10}) async {
    final uri =
        Uri.parse('$_baseUrl/Practitioner?_count=$count&_format=json');
    try {
      final response = await http.get(uri, headers: _headers);
      _validarRespuesta(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final recursos = _parsearBundle(json);
      return recursos.map((r) => Medico.fromFhir(r)).toList();
    } catch (e) {
      throw _manejarError('obtenerMedicos', e);
    }
  }

  // ── Condiciones ───────────────────────────────────────────────

  /// Obtiene condiciones/diagnósticos de pacientes.
  Future<List<Condicion>> obtenerCondiciones({int count = 20}) async {
    final uri =
        Uri.parse('$_baseUrl/Condition?_count=$count&_format=json');
    try {
      final response = await http.get(uri, headers: _headers);
      _validarRespuesta(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final recursos = _parsearBundle(json);
      return recursos.map((r) => Condicion.fromFhir(r)).toList();
    } catch (e) {
      throw _manejarError('obtenerCondiciones', e);
    }
  }

  // ── Helpers privados ──────────────────────────────────────────

  /// Parsea un Bundle FHIR y extrae la lista de resources.
  List<Map<String, dynamic>> _parsearBundle(Map<String, dynamic> json) {
    if (json['resourceType'] != 'Bundle') {
      // Respuesta directa de un recurso único
      return [json];
    }
    final entries = json['entry'] as List? ?? [];
    return entries
        .where((e) => e['resource'] != null)
        .map((e) => e['resource'] as Map<String, dynamic>)
        .toList();
  }

  /// Valida que la respuesta HTTP sea exitosa.
  void _validarRespuesta(http.Response response) {
    if (response.statusCode == 200) return;

    String mensaje;
    switch (response.statusCode) {
      case 400:
        mensaje = 'Solicitud inválida al servidor FHIR (400).';
        break;
      case 401:
        mensaje = 'No autorizado para acceder al recurso (401).';
        break;
      case 404:
        mensaje = 'Recurso no encontrado en el servidor FHIR (404).';
        break;
      case 500:
        mensaje = 'Error interno del servidor FHIR (500).';
        break;
      default:
        mensaje =
            'Error inesperado del servidor: ${response.statusCode}.';
    }
    throw Exception(mensaje);
  }

  /// Convierte cualquier error en una excepción con contexto.
  Exception _manejarError(String metodo, Object e) {
    if (e is Exception) return e;
    return Exception('Error en FhirService.$metodo: $e');
  }
}