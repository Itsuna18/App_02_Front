import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/consulta_model.dart';

class ApiService {
  static const String baseUrl = "http://localhost:5086/api/medicity/distribuida";

  static Future<List<ConsultaGeneral>> getConsultaGeneral() async {
    final response = await http.get(Uri.parse('$baseUrl/view'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => ConsultaGeneral.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar la vista distribuida');
    }
  }

  static Future<String> insertarDoctor(String nombre, int idEspecialidad, int idCiudad) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sp_doctor'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'idEspecialidad': idEspecialidad,
        'idCiudad': idCiudad,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) return data['mensaje'] ?? 'Doctor registrado';
    throw Exception(data['mensaje'] ?? 'Error al insertar doctor');
  }

  static Future<String> insertarPaciente(String nombre, String fechaNacimiento, String direccion, int idCiudad) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sp_paciente'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'fechaNacimiento': fechaNacimiento,
        'direccion': direccion,
        'idCiudad': idCiudad,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) return data['mensaje'] ?? 'Paciente registrado';
    throw Exception(data['mensaje'] ?? 'Error al insertar paciente');
  }

static Future<String> actualizarCita(int id, int idPaciente, int idDoctor, String fechaHora) async {
  final fechaFormateada = fechaHora.contains('T') ? fechaHora : fechaHora.replaceFirst(' ', 'T');

  final response = await http.put(
    Uri.parse('$baseUrl/sp_cita/$id'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'idPaciente': idPaciente,
      'idDoctor': idDoctor,
      'fechaHora': fechaFormateada,
    }),
  );
  final data = json.decode(response.body);
  if (response.statusCode == 200) return data['mensaje'] ?? 'Cita actualizada';
  throw Exception(data['mensaje'] ?? 'Error al actualizar cita');
}

  static Future<String> actualizarDoctor(int id, String nombre, int idEspecialidad, int idCiudad) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sp_doctor/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'idEspecialidad': idEspecialidad,
        'idCiudad': idCiudad,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) return data['mensaje'] ?? 'Doctor actualizado';
    throw Exception(data['mensaje'] ?? 'Error al actualizar doctor');
  }
}