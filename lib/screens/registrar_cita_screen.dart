import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/consulta_model.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class RegistrarCitaScreen extends StatefulWidget {
  final List<PacienteItem>? pacientesDisponibles;
  final List<DoctorItem>? doctoresDisponibles;
  final List<String>? especialidadesDisponibles;

  const RegistrarCitaScreen({
    super.key,
    this.pacientesDisponibles,
    this.doctoresDisponibles,
    this.especialidadesDisponibles,
  });

  @override
  State<RegistrarCitaScreen> createState() => _RegistrarCitaScreenState();
}

class _RegistrarCitaScreenState extends State<RegistrarCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pacienteCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _espCtrl = TextEditingController();
  final _fechaHoraCtrl = TextEditingController(text: '2026-10-20 09:00:00');
  final _descCtrl = TextEditingController();
  final _tratCtrl = TextEditingController();

  final FocusNode _pacienteFocusNode = FocusNode();
  final FocusNode _doctorFocusNode = FocusNode();

  PacienteItem? _pacienteSeleccionado;
  DoctorItem? _doctorSeleccionado;
  bool _loading = false;

  static const Color _primaryColor = Color(0xFF00796B);

  List<PacienteItem> get _pacientes => widget.pacientesDisponibles ?? [];
  List<DoctorItem> get _doctores => widget.doctoresDisponibles ?? [];

  @override
  void dispose() {
    _pacienteCtrl.dispose();
    _doctorCtrl.dispose();
    _espCtrl.dispose();
    _fechaHoraCtrl.dispose();
    _descCtrl.dispose();
    _tratCtrl.dispose();
    _pacienteFocusNode.dispose();
    _doctorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaHora() async {
    DateTime initialDate = DateTime.now();
    try {
      final parts = _fechaHoraCtrl.text.split(' ');
      if (parts.isNotEmpty) {
        final parsed = DateTime.tryParse(parts[0]);
        if (parsed != null) initialDate = parsed;
      }
    } catch (_) {}

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Seleccione Fecha de la Cita',
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Seleccione Hora de la Cita',
    );

    if (pickedTime == null || !mounted) return;

    final y = pickedDate.year.toString().padLeft(4, '0');
    final m = pickedDate.month.toString().padLeft(2, '0');
    final d = pickedDate.day.toString().padLeft(2, '0');
    final hh = pickedTime.hour.toString().padLeft(2, '0');
    final mm = pickedTime.minute.toString().padLeft(2, '0');

    setState(() {
      _fechaHoraCtrl.text = '$y-$m-$d $hh:$mm:00';
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nombrePac = _pacienteCtrl.text.trim();
    final nombreDoc = _doctorCtrl.text.trim();

    // Validar estrictamente que el paciente exista en la base de datos
    PacienteItem? pacEncontrado = _pacienteSeleccionado;
    if (pacEncontrado == null || pacEncontrado.nombre.toLowerCase() != nombrePac.toLowerCase()) {
      try {
        pacEncontrado = _pacientes.firstWhere(
          (p) => p.nombre.trim().toLowerCase() == nombrePac.toLowerCase(),
        );
      } catch (_) {
        pacEncontrado = null;
      }
    }

    if (pacEncontrado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El paciente no existe. Seleccione uno de la lista desplegable.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validar estrictamente que el doctor exista en la base de datos
    DoctorItem? docEncontrado = _doctorSeleccionado;
    if (docEncontrado == null || docEncontrado.nombre.toLowerCase() != nombreDoc.toLowerCase()) {
      try {
        docEncontrado = _doctores.firstWhere(
          (d) => d.nombre.trim().toLowerCase() == nombreDoc.toLowerCase(),
        );
      } catch (_) {
        docEncontrado = null;
      }
    }

    if (docEncontrado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El doctor no existe. Seleccione uno de la lista desplegable.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final msg = await ApiService.insertarCita(
        pacEncontrado.id,
        docEncontrado.id,
        _fechaHoraCtrl.text.trim(),
      );

      final nuevaCita = ConsultaGeneral(
        num: DateTime.now().millisecondsSinceEpoch % 10000,
        paciente: pacEncontrado.nombre,
        fechaNacimiento: pacEncontrado.fechaNacimiento,
        direccion: pacEncontrado.direccion,
        ciudadPaciente: pacEncontrado.ciudad,
        doctor: docEncontrado.nombre,
        ciudadDoctor: docEncontrado.ciudad,
        especialidad: docEncontrado.especialidad,
        fechahora: _fechaHoraCtrl.text.trim(),
        descripcion: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : 'Consulta médica general',
        tratamiento: _tratCtrl.text.trim().isNotEmpty ? _tratCtrl.text.trim() : 'Indicaciones médicas',
      );
      ApiService.registrarCitaLocal(nuevaCita);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(msg)),
              ],
            ),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cita Médica'),
        backgroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _primaryColor.withValues(alpha: 0.12),
                            child: const Icon(Icons.add_circle_outline, color: _primaryColor),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agendar Nueva Cita',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Seleccione el paciente y doctor existentes.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Campo PACIENTE: COMBO AUTOCOMPLETO
                      RawAutocomplete<PacienteItem>(
                        textEditingController: _pacienteCtrl,
                        focusNode: _pacienteFocusNode,
                        displayStringForOption: (p) => p.nombre,
                        optionsBuilder: (TextEditingValue textVal) {
                          final query = textVal.text.trim().toLowerCase();
                          if (query.isEmpty) {
                            return const Iterable<PacienteItem>.empty();
                          }
                          final matches = _pacientes.where((p) {
                            return p.nombre.toLowerCase().contains(query) ||
                                p.ciudad.toLowerCase().contains(query);
                          }).toList();
                          return matches.isNotEmpty ? matches : _pacientes;
                        },
                        onSelected: (PacienteItem selection) {
                          setState(() {
                            _pacienteSeleccionado = selection;
                            _pacienteCtrl.text = selection.nombre;
                          });
                        },
                        fieldViewBuilder: (context, ctrl, fn, onSubmitted) {
                          return TextFormField(
                            controller: ctrl,
                            focusNode: fn,
                            keyboardType: TextInputType.name,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Paciente ',
                              hintText: 'Escriba cualquier letra para buscar paciente...',
                              prefixIcon: Icon(Icons.person, color: _primaryColor),
                              helperText: 'Al escribir se despliegan los pacientes existentes',
                              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Debe ingresar un paciente';
                              }
                              final match = _pacientes.any(
                                (p) => p.nombre.trim().toLowerCase() == val.trim().toLowerCase(),
                              );
                              if (!match) {
                                return 'No existe. Elija uno de la lista.';
                              }
                              return null;
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final pac = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(pac),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.person, size: 18, color: _primaryColor),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pac.nombre,
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                  ),
                                                  Text(
                                                    'Ciudad: ${pac.ciudad}',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo DOCTOR: COMBO AUTOCOMPLETO
                      RawAutocomplete<DoctorItem>(
                        textEditingController: _doctorCtrl,
                        focusNode: _doctorFocusNode,
                        displayStringForOption: (d) => d.nombre,
                        optionsBuilder: (TextEditingValue textVal) {
                          final query = textVal.text.trim().toLowerCase();
                          if (query.isEmpty) {
                            return const Iterable<DoctorItem>.empty();
                          }
                          final matches = _doctores.where((d) {
                            return d.nombre.toLowerCase().contains(query) ||
                                d.especialidad.toLowerCase().contains(query) ||
                                d.ciudad.toLowerCase().contains(query);
                          }).toList();
                          return matches.isNotEmpty ? matches : _doctores;
                        },
                        onSelected: (DoctorItem selection) {
                          setState(() {
                            _doctorSeleccionado = selection;
                            _doctorCtrl.text = selection.nombre;
                            _espCtrl.text = selection.especialidad;
                          });
                        },
                        fieldViewBuilder: (context, ctrl, fn, onSubmitted) {
                          return TextFormField(
                            controller: ctrl,
                            focusNode: fn,
                            keyboardType: TextInputType.name,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Doctor ',
                              hintText: 'Escriba cualquier letra para buscar doctor...',
                              prefixIcon: Icon(Icons.medical_services, color: _primaryColor),
                              helperText: 'Al escribir se despliegan los doctores existentes',
                              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Debe ingresar un doctor';
                              }
                              final match = _doctores.any(
                                (d) => d.nombre.trim().toLowerCase() == val.trim().toLowerCase(),
                              );
                              if (!match) {
                                return 'No existe. Elija uno de la lista.';
                              }
                              return null;
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final doc = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(doc),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.medical_services, size: 18, color: _primaryColor),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    doc.nombre,
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                  ),
                                                  Text(
                                                    '${doc.especialidad} - ${doc.ciudad}',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Especialidad
                      TextFormField(
                        controller: _espCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Especialidad Médica Asignada',
                          hintText: 'Se asigna automáticamente al elegir doctor',
                          prefixIcon: Icon(Icons.badge, color: _primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fecha y Hora
                      TextFormField(
                        controller: _fechaHoraCtrl,
                        decoration: InputDecoration(
                          labelText: 'Fecha y Hora de la Cita',
                          hintText: 'AAAA-MM-DD HH:MM:SS',
                          prefixIcon: const Icon(Icons.access_time, color: _primaryColor),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month, color: _primaryColor),
                            onPressed: _seleccionarFechaHora,
                            tooltip: 'Seleccionar fecha y hora',
                          ),
                          helperText: 'Formato: AAAA-MM-DD HH:MM:SS',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'La fecha y hora es obligatoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Motivo / Diagnóstico
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Motivo / Diagnóstico Preliminar',
                          hintText: 'Ej. Control médico general',
                          prefixIcon: Icon(Icons.assignment, color: _primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tratamiento
                      TextFormField(
                        controller: _tratCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tratamiento / Indicaciones',
                          hintText: 'Ej. Reposo y medicación recomendada',
                          prefixIcon: Icon(Icons.healing, color: _primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _guardar,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _loading ? 'Agendando...' : 'Agendar Cita Médica',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
