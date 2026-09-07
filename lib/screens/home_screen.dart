import 'package:flutter/material.dart';
import '../models/consulta_model.dart';
import '../services/api_service.dart';
import 'registrar_doctor_screen.dart';
import 'actualizar_doctor_screen.dart';
import 'registrar_paciente_screen.dart';
import 'actualizar_paciente_screen.dart';
import 'registrar_cita_screen.dart';
import 'actualizar_cita_screen.dart';

class DoctorItem {
  final int id;
  final String nombre;
  final String especialidad;
  final String ciudad;
  final int totalCitas;

  DoctorItem({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.ciudad,
    required this.totalCitas,
  });
}

class PacienteItem {
  final int id;
  final String nombre;
  final String fechaNacimiento;
  final String direccion;
  final String ciudad;
  final int totalCitas;

  PacienteItem({
    required this.id,
    required this.nombre,
    required this.fechaNacimiento,
    required this.direccion,
    required this.ciudad,
    required this.totalCitas,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Paleta única de color Teal para toda la aplicación
  static const Color _primaryColor = Color(0xFF00796B);
  static const Color _accentLight = Color(0xFFE0F2F1);

  int _currentIndex = 0; // 0: Vista General, 1: Doctores, 2: Pacientes, 3: Citas
  bool _loading = true;
  String? _errorMessage;

  List<ConsultaGeneral> _allConsultas = [];
  List<DoctorItem> _doctores = [];
  List<PacienteItem> _pacientes = [];
  List<String> _especialidades = [
    'Cardiología',
    'Pediatría',
    'Medicina General',
    'Especialidad 1',
    'Especialidad 2',
  ];

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
        ApiService.getPacientes(),
        ApiService.getDoctores(),
      ]);

      final consultas = results[0] as List<ConsultaGeneral>;
      final pacientesBd = results[1] as List<Map<String, dynamic>>;
      final doctoresBd = results[2] as List<Map<String, dynamic>>;

      _procesarDatos(consultas, pacientesBd, doctoresBd);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _procesarDatos(
    List<ConsultaGeneral> consultas,
    List<Map<String, dynamic>> pacientesBd,
    List<Map<String, dynamic>> doctoresBd,
  ) {
    // 1. Procesar Doctores: cargar primero todos los de la base de datos
    final Map<String, DoctorItem> doctorMap = {};
    int docIdCounter = 1;

    for (final d in doctoresBd) {
      final nombre = (d['nombre'] ?? '').toString().trim();
      if (nombre.isEmpty) continue;
      final rawId = d['id'];
      final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? docIdCounter++;
      final key = nombre.toLowerCase();

      doctorMap[key] = DoctorItem(
        id: id,
        nombre: nombre,
        especialidad: (d['especialidad'] ?? 'Medicina General').toString().trim(),
        ciudad: (d['ciudad'] ?? 'Quito').toString().trim(),
        totalCitas: 0,
      );
    }

    // Complementar con los de consultas y contar citas
    for (final c in consultas) {
      final cleanName = c.doctor.trim();
      if (cleanName.isEmpty) continue;
      final key = cleanName.toLowerCase();

      if (!doctorMap.containsKey(key)) {
        doctorMap[key] = DoctorItem(
          id: docIdCounter++,
          nombre: cleanName,
          especialidad: c.especialidad.trim().isNotEmpty ? c.especialidad.trim() : 'Medicina General',
          ciudad: c.ciudadDoctor.trim().isNotEmpty ? c.ciudadDoctor.trim() : 'Quito',
          totalCitas: 1,
        );
      } else {
        final prev = doctorMap[key]!;
        doctorMap[key] = DoctorItem(
          id: prev.id,
          nombre: prev.nombre,
          especialidad: prev.especialidad,
          ciudad: prev.ciudad,
          totalCitas: prev.totalCitas + 1,
        );
      }
    }

    // Incorporar creados localmente si no estuvieran
    for (final extra in ApiService.doctoresCreados) {
      final nombre = extra['nombre'] ?? '';
      if (nombre.isEmpty) continue;
      final key = nombre.toLowerCase();

      if (doctorMap.containsKey(key)) {
        final prev = doctorMap[key]!;
        doctorMap[key] = DoctorItem(
          id: prev.id,
          nombre: nombre,
          especialidad: extra['especialidad'] ?? prev.especialidad,
          ciudad: extra['ciudad'] ?? prev.ciudad,
          totalCitas: prev.totalCitas,
        );
      } else {
        doctorMap[key] = DoctorItem(
          id: docIdCounter++,
          nombre: nombre,
          especialidad: extra['especialidad'] ?? 'Medicina General',
          ciudad: extra['ciudad'] ?? 'Quito',
          totalCitas: 0,
        );
      }
    }

    // 2. Procesar Pacientes: cargar primero todos los de la base de datos
    final Map<String, PacienteItem> pacienteMap = {};
    int pacIdCounter = 1;

    for (final p in pacientesBd) {
      final nombre = (p['nombre'] ?? '').toString().trim();
      if (nombre.isEmpty) continue;
      final rawId = p['id'];
      final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? pacIdCounter++;
      final key = nombre.toLowerCase();

      pacienteMap[key] = PacienteItem(
        id: id,
        nombre: nombre,
        fechaNacimiento: (p['fecha_nacimiento'] ?? '1998-05-15').toString().trim(),
        direccion: (p['direccion'] ?? '').toString().trim(),
        ciudad: (p['ciudad'] ?? 'Quito').toString().trim(),
        totalCitas: 0,
      );
    }

    // Complementar con los de consultas y contar citas
    for (final c in consultas) {
      final cleanName = c.paciente.trim();
      if (cleanName.isEmpty) continue;
      final key = cleanName.toLowerCase();

      if (!pacienteMap.containsKey(key)) {
        pacienteMap[key] = PacienteItem(
          id: pacIdCounter++,
          nombre: cleanName,
          fechaNacimiento: c.fechaNacimiento.trim(),
          direccion: c.direccion.trim(),
          ciudad: c.ciudadPaciente.trim().isNotEmpty ? c.ciudadPaciente.trim() : 'Quito',
          totalCitas: 1,
        );
      } else {
        final prev = pacienteMap[key]!;
        pacienteMap[key] = PacienteItem(
          id: prev.id,
          nombre: prev.nombre,
          fechaNacimiento: prev.fechaNacimiento,
          direccion: prev.direccion,
          ciudad: prev.ciudad,
          totalCitas: prev.totalCitas + 1,
        );
      }
    }

    // Incorporar creados localmente si no estuvieran
    for (final extra in ApiService.pacientesCreados) {
      final nombre = extra['nombre'] ?? '';
      if (nombre.isEmpty) continue;
      final key = nombre.toLowerCase();

      if (pacienteMap.containsKey(key)) {
        final prev = pacienteMap[key]!;
        pacienteMap[key] = PacienteItem(
          id: prev.id,
          nombre: nombre,
          fechaNacimiento: extra['fechaNacimiento'] ?? prev.fechaNacimiento,
          direccion: extra['direccion'] ?? prev.direccion,
          ciudad: extra['ciudad'] ?? prev.ciudad,
          totalCitas: prev.totalCitas,
        );
      } else {
        pacienteMap[key] = PacienteItem(
          id: pacIdCounter++,
          nombre: nombre,
          fechaNacimiento: extra['fechaNacimiento'] ?? '1998-05-15',
          direccion: extra['direccion'] ?? 'Dirección registrada',
          ciudad: extra['ciudad'] ?? 'Quito',
          totalCitas: 0,
        );
      }
    }

    // 3. Especialidades disponibles
    final Set<String> espSet = {
      'Cardiología',
      'Pediatría',
      'Medicina General',
      'Especialidad 1',
      'Especialidad 2',
    };
    for (final c in consultas) {
      if (c.especialidad.trim().isNotEmpty) espSet.add(c.especialidad.trim());
    }
    for (final d in doctorMap.values) {
      if (d.especialidad.trim().isNotEmpty) espSet.add(d.especialidad.trim());
    }

    if (mounted) {
      setState(() {
        _allConsultas = consultas;
        _doctores = doctorMap.values.toList();
        _pacientes = pacienteMap.values.toList();
        _especialidades = espSet.toList();
        _loading = false;
      });
    }
  }

  Future<void> _abrirNuevoDoctor() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrarDoctorScreen(especialidadesDisponibles: _especialidades),
      ),
    );
    if (res == true) _cargarDatos();
  }

  Future<void> _abrirActualizarDoctor(DoctorItem doctor) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActualizarDoctorScreen(
          initialId: doctor.id,
          initialNombre: doctor.nombre,
          initialEspecialidad: doctor.especialidad,
          initialCiudad: doctor.ciudad,
          especialidadesDisponibles: _especialidades,
        ),
      ),
    );
    if (res == true) _cargarDatos();
  }

  Future<void> _abrirNuevoPaciente() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegistrarPacienteScreen()),
    );
    if (res == true) _cargarDatos();
  }

  Future<void> _abrirActualizarPaciente(PacienteItem paciente) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActualizarPacienteScreen(
          initialNombre: paciente.nombre,
          initialFechaNacimiento: paciente.fechaNacimiento,
          initialDireccion: paciente.direccion,
          initialCiudad: paciente.ciudad,
        ),
      ),
    );
    if (res == true) _cargarDatos();
  }

  Future<void> _abrirNuevaCita() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrarCitaScreen(
          pacientesDisponibles: _pacientes,
          doctoresDisponibles: _doctores,
          especialidadesDisponibles: _especialidades,
        ),
      ),
    );
    if (res == true) _cargarDatos();
  }

  Future<void> _abrirActualizarCita(ConsultaGeneral cita) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActualizarCitaScreen(
          initialIdCita: cita.num,
          initialFechaHora: cita.fechahora,
          nombrePaciente: cita.paciente,
          nombreDoctor: cita.doctor,
        ),
      ),
    );
    if (res == true) _cargarDatos();
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'Vista General - Medicity';
      case 1:
        return 'Apartado: Doctores';
      case 2:
        return 'Apartado: Pacientes';
      case 3:
        return 'Apartado: Citas Médicas';
      default:
        return 'Medicity';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: _primaryColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar datos',
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
                  SizedBox(height: 14),
                  Text('Cargando información...', style: TextStyle(color: Colors.grey)),
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
                        const Icon(Icons.error_outline, size: 50, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar datos:\n$_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _cargarDatos,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: RefreshIndicator(
                        color: _primaryColor,
                        onRefresh: _cargarDatos,
                        child: IndexedStack(
                          index: _currentIndex,
                          children: [
                            _buildVistaGeneralTab(),
                            _buildDoctoresTab(),
                            _buildPacientesTab(),
                            _buildCitasTab(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: _accentLight,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
            _searchCtrl.clear();
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _primaryColor),
            label: 'Vista General',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services, color: _primaryColor),
            label: 'Doctores',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt, color: _primaryColor),
            label: 'Pacientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: _primaryColor),
            label: 'Citas Médicas',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    String hint = 'Buscar en el sistema...';
    if (_currentIndex == 0) {
      hint = 'Buscar en vista general por paciente, doctor o diagnóstico...';
    } else if (_currentIndex == 1) {
      hint = 'Buscar doctor por nombre, especialidad o ciudad...';
    } else if (_currentIndex == 2) {
      hint = 'Buscar paciente por nombre o ciudad...';
    } else if (_currentIndex == 3) {
      hint = 'Buscar cita por #, paciente o doctor...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: _primaryColor),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: _primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PESTAÑA 0: VISTA GENERAL (AL INICIAR)
  // ==========================================
  Widget _buildVistaGeneralTab() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtradas = _allConsultas.where((c) {
      if (query.isEmpty) return true;
      return c.num.toString().contains(query) ||
          c.paciente.toLowerCase().contains(query) ||
          c.doctor.toLowerCase().contains(query) ||
          c.especialidad.toLowerCase().contains(query) ||
          c.ciudadPaciente.toLowerCase().contains(query) ||
          c.ciudadDoctor.toLowerCase().contains(query) ||
          c.descripcion.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                titulo: 'Total Citas',
                valor: '${_allConsultas.length}',
                icono: Icons.calendar_month,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                titulo: 'Doctores',
                valor: '${_doctores.length}',
                icono: Icons.medical_services,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                titulo: 'Pacientes',
                valor: '${_pacientes.length}',
                icono: Icons.people_alt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Registros de Consulta General',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${filtradas.length} encontrados',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (filtradas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No hay consultas que coincidan con la búsqueda',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...filtradas.map((c) => _buildConsultaGeneralCard(c)),
      ],
    );
  }

  Widget _buildMetricCard({required String titulo, required String valor, required IconData icono}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentLight),
      ),
      child: Column(
        children: [
          Icon(icono, color: _primaryColor, size: 22),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
          Text(titulo, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildConsultaGeneralCard(ConsultaGeneral c) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cita #${c.num}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryColor),
                  ),
                ),
                Text(
                  c.fechahora,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: _primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Paciente: ${c.paciente} (${c.ciudadPaciente})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.medical_services, size: 16, color: _primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Doctor: ${c.doctor} - ${c.especialidad}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            if (c.descripcion.isNotEmpty || c.tratamiento.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.descripcion.isNotEmpty)
                      Text(
                        'Diagnóstico: ${c.descripcion}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    if (c.tratamiento.isNotEmpty)
                      Text(
                        'Tratamiento: ${c.tratamiento}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // APARTADO 1: DOCTORES (LISTAR, CREAR, ACTUALIZAR)
  // ==========================================
  Widget _buildDoctoresTab() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtrados = _doctores.where((d) {
      if (query.isEmpty) return true;
      return d.nombre.toLowerCase().contains(query) ||
          d.especialidad.toLowerCase().contains(query) ||
          d.ciudad.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Listado de Doctores (${filtrados.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _abrirNuevoDoctor,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Crear Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(
                  child: Text('No hay doctores registrados', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final doc = filtrados[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _accentLight,
                              child: const Icon(Icons.medical_services, color: _primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.nombre,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _accentLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          doc.especialidad,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ciudad: ${doc.ciudad}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _abrirActualizarDoctor(doc),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Actualizar'),
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

  // ==========================================
  // APARTADO 2: PACIENTES (LISTAR, CREAR, ACTUALIZAR)
  // ==========================================
  Widget _buildPacientesTab() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtrados = _pacientes.where((p) {
      if (query.isEmpty) return true;
      return p.nombre.toLowerCase().contains(query) ||
          p.ciudad.toLowerCase().contains(query) ||
          p.direccion.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Listado de Pacientes (${filtrados.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _abrirNuevoPaciente,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Crear Paciente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(
                  child: Text('No hay pacientes registrados', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final pac = filtrados[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _accentLight,
                              child: const Icon(Icons.person, color: _primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pac.nombre,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nacimiento: ${pac.fechaNacimiento} | ${pac.ciudad}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  if (pac.direccion.isNotEmpty)
                                    Text(
                                      'Dirección: ${pac.direccion}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _abrirActualizarPaciente(pac),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Actualizar'),
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

  // ==========================================
  // APARTADO 3: CITAS MÉDICAS (LISTAR, CREAR, ACTUALIZAR)
  // ==========================================
  Widget _buildCitasTab() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtrados = _allConsultas.where((c) {
      if (query.isEmpty) return true;
      return c.num.toString().contains(query) ||
          c.paciente.toLowerCase().contains(query) ||
          c.doctor.toLowerCase().contains(query) ||
          c.especialidad.toLowerCase().contains(query) ||
          c.descripcion.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Listado de Citas (${filtrados.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _abrirNuevaCita,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Crear Cita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(
                  child: Text('No hay citas médicas registradas', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final cita = filtrados[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _accentLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Cita #${cita.num}',
                                    style: const TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  cita.fechahora,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: _primaryColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Paciente: ${cita.paciente}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.medical_services, size: 16, color: _primaryColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Doctor: ${cita.doctor} (${cita.especialidad})',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            if (cita.descripcion.isNotEmpty || cita.tratamiento.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (cita.descripcion.isNotEmpty)
                                      Text(
                                        'Diagnóstico: ${cita.descripcion}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    if (cita.tratamiento.isNotEmpty)
                                      Text(
                                        'Tratamiento: ${cita.tratamiento}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _abrirActualizarCita(cita),
                                icon: const Icon(Icons.edit_calendar, size: 15),
                                label: const Text('Actualizar Cita'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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