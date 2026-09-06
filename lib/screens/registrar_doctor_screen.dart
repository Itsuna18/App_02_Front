import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegistrarDoctorScreen extends StatefulWidget {
  const RegistrarDoctorScreen({super.key});

  @override
  State<RegistrarDoctorScreen> createState() => _RegistrarDoctorScreenState();
}

class _RegistrarDoctorScreenState extends State<RegistrarDoctorScreen> {
  final _nombreCtrl = TextEditingController();
  final _espCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _guardar() async {
    setState(() => _loading = true);
    try {
      final msg = await ApiService.insertarDoctor(
        _nombreCtrl.text,
        int.parse(_espCtrl.text),
        int.parse(_ciudadCtrl.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
        _nombreCtrl.clear();
        _espCtrl.clear();
        _ciudadCtrl.clear();
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
      appBar: AppBar(title: const Text('Registrar Doctor'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Doctor', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _espCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID Especialidad', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _ciudadCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID Ciudad', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _guardar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Doctor', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}