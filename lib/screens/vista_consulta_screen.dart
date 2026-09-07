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
  final TextEditingController _searchCtrl = TextEditingController();
  List<ConsultaGeneral> _allConsultas = [];
  List<ConsultaGeneral> _filteredConsultas = [];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _cargar() {
    setState(() {
      _hasLoaded = false;
      _futureConsultas = ApiService.getConsultaGeneral().then((list) {
        _allConsultas = list;
        _filtrar(_searchCtrl.text);
        _hasLoaded = true;
        return list;
      });
    });
  }

  void _filtrar(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredConsultas = List.from(_allConsultas);
      } else {
        _filteredConsultas = _allConsultas.where((c) {
          return c.paciente.toLowerCase().contains(q) ||
              c.doctor.toLowerCase().contains(q) ||
              c.especialidad.toLowerCase().contains(q) ||
              c.num.toString().contains(q) ||
              c.ciudadPaciente.toLowerCase().contains(q) ||
              c.ciudadDoctor.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta General'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar consultas',
          )
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade50,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por paciente, doctor o especialidad...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filtrar('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue.shade200),
                ),
              ),
            ),
          ),

          // Lista de resultados
          Expanded(
            child: FutureBuilder<List<ConsultaGeneral>>(
              future: _futureConsultas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_hasLoaded) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text('Consultando bases de datos distribuidas...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 52, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            'Error al cargar vista distribuida:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final displayList = _hasLoaded ? _filteredConsultas : (snapshot.data ?? []);

                if (displayList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchCtrl.text.isNotEmpty
                              ? 'No se encontraron resultados para la búsqueda'
                              : 'No hay datos disponibles en la vista',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final c = displayList[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabecera: Cita # y Fecha
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Cita #${c.num}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 15, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        c.fechahora,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Paciente
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.person, size: 20, color: Colors.teal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                                        children: [
                                          const TextSpan(
                                            text: 'Paciente: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: '${c.paciente} '),
                                          WidgetSpan(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.teal.shade200),
                                              ),
                                              child: Text(
                                                'Ciudad: ${c.ciudadPaciente}',
                                                style: TextStyle(fontSize: 11, color: Colors.teal.shade800),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Doctor
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.medical_services, size: 20, color: Colors.indigo),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                                        children: [
                                          const TextSpan(
                                            text: 'Doctor: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: '${c.doctor} (${c.especialidad}) '),
                                          WidgetSpan(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.indigo.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.indigo.shade200),
                                              ),
                                              child: Text(
                                                'Ciudad: ${c.ciudadDoctor}',
                                                style: TextStyle(fontSize: 11, color: Colors.indigo.shade800),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Diagnóstico y Tratamiento
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.assignment, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Diagnóstico: ${c.descripcion}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.healing, size: 16, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Tratamiento: ${c.tratamiento}',
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}