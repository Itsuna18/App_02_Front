import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/consulta_model.dart';

class ApiService {
  static const String baseUrl = "http://localhost:5086/api/medicity/distribuida";

  // Listas en memoria para garantizar que los elementos creados se listen de inmediato
  static final List<Map<String, String>> doctoresCreados = [];
  static final List<Map<String, String>> pacientesCreados = [];
  static final List<ConsultaGeneral> citasCreadas = [];

  static Future<List<ConsultaGeneral>> getConsultaGeneral() async {
    final response = await http.get(Uri.parse('$baseUrl/view'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      final list = jsonResponse.map((item) => ConsultaGeneral.fromJson(item)).toList();
      for (final extra in citasCreadas) {
        if (!list.any((c) => c.num == extra.num)) {
          list.add(extra);
        }
      }
      return list;
    } else {
      throw Exception('Error al cargar las consultas médicas');
    }
  }

  static Future<List<Map<String, dynamic>>> getPacientes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pacientes'));
      if (response.statusCode == 200) {
        List list = json.decode(response.body);
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> getDoctores() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/doctores'));
      if (response.statusCode == 200) {
        List list = json.decode(response.body);
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<String> insertarDoctor(String nombre, String especialidad, String ciudad) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sp_doctor'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'especialidad': especialidad,
        'ciudad': ciudad,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      doctoresCreados.removeWhere((d) => d['nombre']?.toLowerCase() == nombre.toLowerCase());
      doctoresCreados.add({
        'nombre': nombre,
        'especialidad': especialidad,
        'ciudad': ciudad,
      });
      return data['mensaje'] ?? 'Doctor registrado correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al insertar doctor');
  }

  static Future<String> insertarPaciente(String nombre, String fechaNacimiento, String direccion, String ciudad) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sp_paciente'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'fechaNacimiento': fechaNacimiento,
        'direccion': direccion,
        'ciudad': ciudad,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      pacientesCreados.removeWhere((p) => p['nombre']?.toLowerCase() == nombre.toLowerCase());
      pacientesCreados.add({
        'nombre': nombre,
        'fechaNacimiento': fechaNacimiento,
        'direccion': direccion,
        'ciudad': ciudad,
      });
      return data['mensaje'] ?? 'Paciente registrado correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al insertar paciente');
  }

  static Future<String> insertarCita(int idPaciente, int idDoctor, String fechaHora) async {
    final fechaFormateada = fechaHora.contains('T') ? fechaHora : fechaHora.replaceFirst(' ', 'T');
    final response = await http.post(
      Uri.parse('$baseUrl/sp_cita'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'idPaciente': idPaciente,
        'idDoctor': idDoctor,
        'fechaHora': fechaFormateada,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['mensaje'] ?? 'Cita médica registrada correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al registrar cita médica');
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
    if (response.statusCode == 200) {
      for (int i = 0; i < citasCreadas.length; i++) {
        if (citasCreadas[i].num == id) {
          citasCreadas[i] = ConsultaGeneral(
            num: id,
            paciente: citasCreadas[i].paciente,
            fechaNacimiento: citasCreadas[i].fechaNacimiento,
            direccion: citasCreadas[i].direccion,
            ciudadPaciente: citasCreadas[i].ciudadPaciente,
            doctor: citasCreadas[i].doctor,
            ciudadDoctor: citasCreadas[i].ciudadDoctor,
            especialidad: citasCreadas[i].especialidad,
            fechahora: fechaHora,
            descripcion: citasCreadas[i].descripcion,
            tratamiento: citasCreadas[i].tratamiento,
          );
        }
      }
      return data['mensaje'] ?? 'Cita actualizada correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al actualizar cita');
  }

  static Future<String> actualizarDoctor(int id, String nombre, String especialidad, String ciudad) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sp_doctor/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'especialidad': especialidad,
        'ciudad': ciudad,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      doctoresCreados.removeWhere((d) => d['nombre']?.toLowerCase() == nombre.toLowerCase());
      doctoresCreados.add({
        'nombre': nombre,
        'especialidad': especialidad,
        'ciudad': ciudad,
      });
      return data['mensaje'] ?? 'Doctor actualizado correctamente';
    }
    throw Exception(data['mensaje'] ?? 'Error al actualizar doctor');
  }

  static void actualizarPacienteLocal(String nombreOriginal, String nuevoNombre, String fechaNac, String direccion, String ciudad) {
    pacientesCreados.removeWhere((p) => p['nombre']?.toLowerCase() == nombreOriginal.toLowerCase());
    pacientesCreados.add({
      'nombre': nuevoNombre,
      'fechaNacimiento': fechaNac,
      'direccion': direccion,
      'ciudad': ciudad,
    });
  }

  static void registrarCitaLocal(ConsultaGeneral nuevaCita) {
    citasCreadas.removeWhere((c) => c.num == nuevaCita.num);
    citasCreadas.add(nuevaCita);
  }
}