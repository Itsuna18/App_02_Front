import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ActualizarCitaScreen extends StatefulWidget {
  const ActualizarCitaScreen({super.key});

  @override
  State<ActualizarCitaScreen> createState() => _ActualizarCitaScreenState();
}

class _ActualizarCitaScreenState extends State<ActualizarCitaScreen> {
  final _idCitaCtrl = TextEditingController();
  final _idPacienteCtrl = TextEditingController();
  final _idDoctorCtrl = TextEditingController();
  final _fechaHoraCtrl = TextEditingController(text: '2026-10-15 10:00:00');
  bool _loading = false;

  Future<void> _actualizar() async {
    setState(() => _loading = true);
    try {
      final msg = await ApiService.actualizarCita(
        int.parse(_idCitaCtrl.text),
        int.parse(_idPacienteCtrl.text),
        int.parse(_idDoctorCtrl.text),
        _fechaHoraCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizar Cita Médica'), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _idCitaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID Cita a Modificar', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _idPacienteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID Paciente', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _idDoctorCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID Doctor', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _fechaHoraCtrl, decoration: const InputDecoration(labelText: 'Fecha y Hora (AAAA-MM-DD HH:MM:SS)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _actualizar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Actualizar Cita', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}