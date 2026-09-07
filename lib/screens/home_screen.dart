import 'package:flutter/material.dart';
import '../models/consulta_model.dart';
import '../services/api_service.dart';
import 'registrar_doctor_screen.dart';
import 'actualizar_doctor_screen.dart';
import 'registrar_paciente_screen.dart';
import 'actualizar_cita_screen.dart';

class DoctorModelo {
  final int id;
  final String nombre;
  final String especialidad;
  final String ciudad;

  DoctorModelo({required this.id, required this.nombre, required this.especialidad, required this.ciudad});
}

class PacienteModelo {
  final int id;
  final String nombre;
  final String fechaNacimiento;
  final String direccion;
  final String ciudad;

  PacienteModelo({required this.id, required this.nombre, required this.fechaNacimiento, required this.direccion, required this.ciudad});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryColor = Color(0xFF00796B);
  static const Color _accentLight = Color(0xFFE0F2F1);

  int _currentIndex = 0;
  bool _loading = true;
  String? _errorMessage;

  List<ConsultaGeneral> _allConsultas = [];
  List<ConsultaGeneral> _filteredConsultas = [];
  List<DoctorModelo> _listaDoctores = [];
  List<PacienteModelo> _listaPacientes = [];

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getConsultaGeneral(),
        ApiService.getDoctores(),
        ApiService.getPacientes(),
      ]);

      final consultas = results[0] as List<ConsultaGeneral>;
      final rawDoctores = results[1] as List<Map<String, dynamic>>;
      final rawPacientes = results[2] as List<Map<String, dynamic>>;

      List<DoctorModelo> docs = rawDoctores.map((d) {
        final rawId = d['id'];
        final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 1;
        return DoctorModelo(
          id: id,
          nombre: (d['nombre'] ?? '').toString(),
          especialidad: (d['especialidad'] ?? 'Medicina General').toString(),
          ciudad: (d['ciudad'] ?? 'Quito').toString(),
        );
      }).toList();

      List<PacienteModelo> pacs = rawPacientes.map((p) {
        final rawId = p['id'];
        final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 1;
        return PacienteModelo(
          id: id,
          nombre: (p['nombre'] ?? '').toString(),
          fechaNacimiento: (p['fechaNacimiento'] ?? '').toString(),
          direccion: (p['direccion'] ?? 'Centro').toString(),
          ciudad: (p['ciudad'] ?? 'Quito').toString(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allConsultas = consultas;
          _listaDoctores = docs;
          _listaPacientes = pacs;
          _filtrar(_searchCtrl.text);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
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
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aplicaciones Distribuidas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
            Text(
              'Gestión de Citas Médicas',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade200),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar Datos de la BD',
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  SizedBox(height: 16),
                  Text('Consultando bases de datos distribuidas...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 54, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error de Conexión',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _cargarDatos,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart_outlined),
            activeIcon: Icon(Icons.table_chart),
            label: '1. Vista General',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: '2. Doctores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: '3. Pacientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: '4. Citas',
          ),
        ],
      ),
    );
  }


  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildPestanaVistaGeneral();
      case 1:
        return _buildPestanaDoctores();
      case 2:
        return _buildPestanaPacientes();
      case 3:
        return _buildPestanaCitas();
      default:
        return _buildPestanaVistaGeneral();
    }
  }

  // 1. PESTAÑA VISTA GENERAL (GET Vista)
  Widget _buildPestanaVistaGeneral() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _accentLight,
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filtrar,
            decoration: InputDecoration(
              hintText: 'Buscar por paciente, doctor, ciudad o especialidad...',
              prefixIcon: const Icon(Icons.search, color: _primaryColor),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: _primaryColor),
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
                borderSide: const BorderSide(color: Color(0xFF80CBC4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF80CBC4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
        ),
        Expanded(
          child: _filteredConsultas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        _searchCtrl.text.isNotEmpty
                            ? 'No hay resultados que coincidan'
                            : 'No hay datos en la vista consulta_general',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredConsultas.length,
                  itemBuilder: (context, index) {
                    final c = _filteredConsultas[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text('Cita #${c.num}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(c.fechahora, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 18, color: _primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                                      children: [
                                        const TextSpan(text: 'Paciente: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: '${c.paciente} '),
                                        WidgetSpan(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(color: _accentLight, borderRadius: BorderRadius.circular(4)),
                                            child: Text(c.ciudadPaciente, style: const TextStyle(fontSize: 10, color: _primaryColor, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.medical_services, size: 18, color: _primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                                      children: [
                                        const TextSpan(text: 'Doctor: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: '${c.doctor} (${c.especialidad}) '),
                                        WidgetSpan(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(color: _accentLight, borderRadius: BorderRadius.circular(4)),
                                            child: Text(c.ciudadDoctor, style: const TextStyle(fontSize: 10, color: _primaryColor, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Diagnóstico: ${c.descripcion}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 3),
                                  Text('Tratamiento: ${c.tratamiento}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 2. PESTAÑA DOCTORES (Sitio B)
  Widget _buildPestanaDoctores() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14.0),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrarDoctorScreen())).then((_) => _cargarDatos()),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Registrar Nuevo Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _listaDoctores.isEmpty
              ? const Center(child: Text('No hay doctores registrados en Sitio B'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _listaDoctores.length,
                  itemBuilder: (context, index) {
                    final d = _listaDoctores[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: _accentLight, child: Icon(Icons.medical_services, color: _primaryColor)),
                        title: Text('ID #${d.id}: ${d.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('Especialidad: ${d.especialidad}\nCiudad: ${d.ciudad}', style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                        trailing: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActualizarDoctorScreen(
                                initialId: d.id,
                                initialNombre: d.nombre,
                                initialEspecialidad: d.especialidad,
                                initialCiudad: d.ciudad,
                              ),
                            ),
                          ).then((_) => _cargarDatos()),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Actualizar', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentLight,
                            foregroundColor: _primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 3. PESTAÑA PACIENTES (Sitio A)
  Widget _buildPestanaPacientes() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14.0),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrarPacienteScreen())).then((_) => _cargarDatos()),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Registrar Nuevo Paciente', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _listaPacientes.isEmpty
              ? const Center(child: Text('No hay pacientes registrados en Sitio A'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _listaPacientes.length,
                  itemBuilder: (context, index) {
                    final p = _listaPacientes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: _accentLight, child: Icon(Icons.person, color: _primaryColor)),
                        title: Text('ID #${p.id}: ${p.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('Ciudad: ${p.ciudad} • F. Nac: ${p.fechaNacimiento}\nDirección: ${p.direccion.isNotEmpty ? p.direccion : "Centro"}', style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _accentLight, borderRadius: BorderRadius.circular(6)),
                          child: const Text('Sitio A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryColor)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPestanaCitas() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _accentLight,
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: _primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Presiona "Actualizar Cita" para reprogramar fecha o asignar otro doctor.',
                  style: TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _allConsultas.isEmpty
              ? const Center(child: Text('No hay citas registradas'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _allConsultas.length,
                  itemBuilder: (context, index) {
                    final c = _allConsultas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Cita Médica #${c.num}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primaryColor)),
                                Chip(
                                  label: Text(c.fechahora, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                  backgroundColor: _primaryColor,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const Divider(),
                            Text('Paciente: ${c.paciente}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text('Doctor: ${c.doctor} (${c.especialidad})'),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActualizarCitaScreen(
                                      initialIdCita: c.num.toInt(),
                                      initialFechaHora: c.fechahora,
                                      nombrePaciente: c.paciente,
                                      nombreDoctor: c.doctor,
                                    ),
                                  ),
                                ).then((_) => _cargarDatos()),
                                icon: const Icon(Icons.edit_calendar, size: 16),
                                label: const Text('Actualizar Cita Médica'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
