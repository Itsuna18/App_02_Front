import 'package:flutter/material.dart';
import 'vista_consulta_screen.dart';
import 'registrar_doctor_screen.dart';
import 'registrar_paciente_screen.dart';
import 'actualizar_cita_screen.dart';
import 'actualizar_doctor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicity Distribuida'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(
            context,
            title: '1. Ver Consulta General',
            subtitle: 'GET: Vista Distribuida (Sitio A + B)',
            icon: Icons.visibility,
            color: Colors.blue,
            screen: const VistaConsultaScreen(),
          ),
          _buildCard(
            context,
            title: '2. Registrar Doctor',
            subtitle: 'POST: SP Insert en Sitio B',
            icon: Icons.person_add,
            color: Colors.green,
            screen: const RegistrarDoctorScreen(),
          ),
          _buildCard(
            context,
            title: '3. Registrar Paciente',
            subtitle: 'POST: SP Insert en Sitio A',
            icon: Icons.personal_injury,
            color: Colors.teal,
            screen: const RegistrarPacienteScreen(),
          ),
          _buildCard(
            context,
            title: '4. Actualizar Cita Médica',
            subtitle: 'PUT: SP Update en Sitio A',
            icon: Icons.edit_calendar,
            color: Colors.orange,
            screen: const ActualizarCitaScreen(),
          ),
          _buildCard(
            context,
            title: '5. Actualizar Doctor',
            subtitle: 'PUT: SP Update en Sitio B',
            icon: Icons.manage_accounts,
            color: Colors.purple,
            screen: const ActualizarDoctorScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 24,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}