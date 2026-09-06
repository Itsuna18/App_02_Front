import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/consulta_model.dart';

class VistaConsultaScreen extends StatefulWidget {
  const VistaConsultaScreen({super.key});

  @override
  State<VistaConsultaScreen> createState() => _VistaConsultaScreenState();
}

class _VistaConsultaScreenState extends State<VistaConsultaScreen> {
  late Future<List<ConsultaGeneral>> _futureConsultas;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futureConsultas = ApiService.getConsultaGeneral();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta General (Vista)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh))
        ],
      ),
      body: FutureBuilder<List<ConsultaGeneral>>(
        future: _futureConsultas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay datos disponibles'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final c = items[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cita #${c.num} - ${c.fechahora}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                      const Divider(),
                      Text('Paciente: ${c.paciente} | Ciudad: ${c.ciudadPaciente}'),
                      Text('Doctor: ${c.doctor} (${c.especialidad}) | Ciudad: ${c.ciudadDoctor}'),
                      Text('Diagnóstico: ${c.descripcion}'),
                      Text('Tratamiento: ${c.tratamiento}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}