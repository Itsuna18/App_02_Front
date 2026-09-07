import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/consulta_model.dart';

class ApiService {
  static const String baseUrl = "http://localhost:5086/api/medicity/distribuida";

  // 1. GET: Vista General (Sitio A + Sitio B)
  static Future<List<ConsultaGeneral>> getConsultaGeneral() async {
    final response = await http.get(Uri.parse('$baseUrl/view'));
    if (response.statusCode == 200) {
      // utf8.decode(response.bodyBytes) garantiza que las tildes y ñ se decodifiquen perfectamente
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((item) => ConsultaGeneral.fromJson(item)).toList();
    } else {
      throw Exception('Error al conectar con la base de datos distribuida');
    }
  }

  // 2. GET: Especialidades Reales en Sitio B (vía Linked Server)
  static Future<List<Map<String, dynamic>>> getEspecialidades() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/especialidades'));
      if (response.statusCode == 200) {
        List list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [
      {'id': 1, 'nombre': 'ESPECIALIDAD 1'},
      {'id': 2, 'nombre': 'ESPECIALIDAD 2'},
    ];
  }

  // 3. GET: Ciudades Reales en Sitio A
  static Future<List<Map<String, dynamic>>> getCiudades() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ciudades'));
      if (response.statusCode == 200) {
        List list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [
      {'id': 1, 'nombre': 'QUITO'},
      {'id': 2, 'nombre': 'AMBATO'},
    ];
  }

  // 4. GET: Todos los Doctores (Sitio B vía Linked Server)
  static Future<List<Map<String, dynamic>>> getDoctores() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/doctores'));
      if (response.statusCode == 200) {
        List list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  // 5. GET: Todos los Pacientes (Sitio A)
  static Future<List<Map<String, dynamic>>> getPacientes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pacientes'));
      if (response.statusCode == 200) {
        List list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  // 6. POST: Insertar Doctor (SP 1 en Sitio B)
  static Future<String> insertarDoctor(String nombre, int idEspecialidad, int idCiudad) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sp_doctor'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'nombre': nombre,
        'idEspecialidad': idEspecialidad,
        'idCiudad': idCiudad,
      }),
    );
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data['mensaje'] ?? 'Doctor registrado correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al insertar doctor');
  }

  // 7. POST: Insertar Paciente (SP 2 en Sitio A)
  static Future<String> insertarPaciente(String nombre, String fechaNacimiento, String direccion, int idCiudad) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sp_paciente'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'nombre': nombre,
        'fechaNacimiento': fechaNacimiento,
        'direccion': direccion,
        'idCiudad': idCiudad,
      }),
    );
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data['mensaje'] ?? 'Paciente registrado correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al insertar paciente');
  }

  // 8. PUT: Actualizar Cita Médica (SP 3 en Sitio A)
  static Future<String> actualizarCita(int id, int idPaciente, int idDoctor, String fechaHora) async {
    final fechaFormateada = fechaHora.contains('T') ? fechaHora : fechaHora.replaceFirst(' ', 'T');

    final response = await http.put(
      Uri.parse('$baseUrl/sp_cita/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'idPaciente': idPaciente,
        'idDoctor': idDoctor,
        'fechaHora': fechaFormateada,
      }),
    );
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data['mensaje'] ?? 'Cita actualizada correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al actualizar cita');
  }

  // 9. PUT: Actualizar Doctor (SP 4 en Sitio B)
  static Future<String> actualizarDoctor(int id, String nombre, int idEspecialidad, int idCiudad) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sp_doctor/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'nombre': nombre,
        'idEspecialidad': idEspecialidad,
        'idCiudad': idCiudad,
      }),
    );
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data['mensaje'] ?? 'Doctor actualizado correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al actualizar doctor');
  }
}
