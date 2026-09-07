import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ActualizarCitaScreen extends StatefulWidget {
  final int? initialIdCita;
  final int? initialIdPaciente;
  final int? initialIdDoctor;
  final String? initialFechaHora;
  final String? nombrePaciente;
  final String? nombreDoctor;

  const ActualizarCitaScreen({
    super.key,
    this.initialIdCita,
    this.initialIdPaciente,
    this.initialIdDoctor,
    this.initialFechaHora,
    this.nombrePaciente,
    this.nombreDoctor,
  });

  @override
  State<ActualizarCitaScreen> createState() => _ActualizarCitaScreenState();
}

class _ActualizarCitaScreenState extends State<ActualizarCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCitaCtrl = TextEditingController();
  final _idPacienteCtrl = TextEditingController();
  final _idDoctorCtrl = TextEditingController();
  final _fechaHoraCtrl = TextEditingController(text: '2026-10-15 10:00:00');
  bool _loading = false;

  static const Color _primaryColor = Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    if (widget.initialIdCita != null) {
      _idCitaCtrl.text = widget.initialIdCita.toString();
    }
    if (widget.initialIdPaciente != null) {
      _idPacienteCtrl.text = widget.initialIdPaciente.toString();
    } else {
      _idPacienteCtrl.text = '1';
    }
    if (widget.initialIdDoctor != null) {
      _idDoctorCtrl.text = widget.initialIdDoctor.toString();
    } else {
      _idDoctorCtrl.text = '1';
    }
    if (widget.initialFechaHora != null && widget.initialFechaHora!.isNotEmpty) {
      _fechaHoraCtrl.text = widget.initialFechaHora!;
    }
  }

  @override
  void dispose() {
    _idCitaCtrl.dispose();
    _idPacienteCtrl.dispose();
    _idDoctorCtrl.dispose();
    _fechaHoraCtrl.dispose();
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
      initialTime: const TimeOfDay(hour: 10, minute: 0),
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

  Future<void> _actualizar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      final msg = await ApiService.actualizarCita(
        int.parse(_idCitaCtrl.text.trim()),
        int.parse(_idPacienteCtrl.text.trim()),
        int.parse(_idDoctorCtrl.text.trim()),
        _fechaHoraCtrl.text.trim(),
      );
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final bool isPreselected = widget.initialIdCita != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Cita Médica'),
        backgroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.nombrePaciente != null || widget.nombreDoctor != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.nombrePaciente != null)
                              Text(
                                'Paciente: ${widget.nombrePaciente}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            if (widget.nombreDoctor != null)
                              Text(
                                'Doctor: ${widget.nombreDoctor}',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                            child: const Icon(Icons.edit_calendar, color: _primaryColor),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Datos de la Cita',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Modifique los datos de la cita médica',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Campo ID Cita: SOLO NÚMEROS
                      TextFormField(
                        controller: _idCitaCtrl,
                        readOnly: isPreselected,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Número de Cita a Modificar',
                          hintText: 'Ej. 1',
                          prefixIcon: const Icon(Icons.confirmation_number, color: _primaryColor),
                          helperText: isPreselected
                              ? 'Cita seleccionada para actualización'
                              : 'Solo dígitos numéricos',
                          filled: isPreselected,
                          fillColor: isPreselected ? _primaryColor.withValues(alpha: 0.05) : null,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'El ID de cita es obligatorio';
                          }
                          final num = int.tryParse(val.trim());
                          if (num == null || num <= 0) {
                            return 'Ingrese un ID numérico válido mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _idPacienteCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Código del Paciente (ID)',
                          hintText: 'Ej. 1',
                          prefixIcon: Icon(Icons.person, color: _primaryColor),
                          helperText: 'Solo dígitos numéricos',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'El ID del paciente es obligatorio';
                          }
                          final num = int.tryParse(val.trim());
                          if (num == null || num <= 0) {
                            return 'Ingrese un ID numérico válido mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo ID Doctor: SOLO NÚMEROS
                      TextFormField(
                        controller: _idDoctorCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Código del Doctor (ID)',
                          hintText: 'Ej. 1',
                          prefixIcon: Icon(Icons.medical_services, color: _primaryColor),
                          helperText: 'Solo dígitos numéricos',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'El ID del doctor es obligatorio';
                          }
                          final num = int.tryParse(val.trim());
                          if (num == null || num <= 0) {
                            return 'Ingrese un ID numérico válido mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Fecha y Hora: con selector interactivo
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
                          if (!RegExp(r'^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}(:\d{2})?$').hasMatch(val.trim())) {
                            return 'Formato inválido. Use AAAA-MM-DD HH:MM:SS';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _actualizar,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.update),
                label: Text(
                  _loading ? 'Actualizando...' : 'Actualizar Cita',
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