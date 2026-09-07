import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegistrarPacienteScreen extends StatefulWidget {
  const RegistrarPacienteScreen({super.key});

  @override
  State<RegistrarPacienteScreen> createState() => _RegistrarPacienteScreenState();
}

class _RegistrarPacienteScreenState extends State<RegistrarPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController(text: '1998-05-15');
  final _dirCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fechaCtrl.dispose();
    _dirCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    DateTime initial = DateTime.tryParse(_fechaCtrl.text) ?? DateTime(1998, 5, 15);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Seleccione Fecha de Nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _fechaCtrl.text = '$y-$m-$d';
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      final msg = await ApiService.insertarPaciente(
        _nombreCtrl.text.trim(),
        _fechaCtrl.text.trim(),
        _dirCtrl.text.trim(),
        _ciudadCtrl.text.trim(),
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
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _formKey.currentState!.reset();
        _nombreCtrl.clear();
        _dirCtrl.clear();
        _ciudadCtrl.clear();
        _fechaCtrl.text = '1998-05-15';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Paciente'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 3,
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
                            backgroundColor: Colors.teal.shade50,
                            child: Icon(Icons.personal_injury, color: Colors.teal.shade700),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Datos del Paciente',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Ingrese los datos del nuevo paciente',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Campo Nombre del Paciente: SOLO LETRAS
                      TextFormField(
                        controller: _nombreCtrl,
                        keyboardType: TextInputType.name,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo del Paciente',
                          hintText: 'Ej. Juan Antonio Pérez',
                          prefixIcon: Icon(Icons.person, color: Colors.teal),
                          helperText: 'Solo se permiten letras y espacios',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          if (val.trim().length < 3) {
                            return 'Debe ingresar al menos 3 caracteres';
                          }
                          if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(val.trim())) {
                            return 'El nombre solo puede contener letras';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Fecha de Nacimiento: con selector
                      TextFormField(
                        controller: _fechaCtrl,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: 'Fecha de Nacimiento',
                          hintText: 'AAAA-MM-DD',
                          prefixIcon: const Icon(Icons.calendar_month, color: Colors.teal),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar, color: Colors.teal),
                            onPressed: _seleccionarFecha,
                            tooltip: 'Seleccionar fecha',
                          ),
                          helperText: 'Formato: AAAA-MM-DD',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'La fecha de nacimiento es obligatoria';
                          }
                          final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                          if (!regex.hasMatch(val.trim())) {
                            return 'Formato inválido. Use AAAA-MM-DD';
                          }
                          final parsed = DateTime.tryParse(val.trim());
                          if (parsed == null) {
                            return 'Fecha no válida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Dirección
                      TextFormField(
                        controller: _dirCtrl,
                        keyboardType: TextInputType.streetAddress,
                        decoration: const InputDecoration(
                          labelText: 'Dirección Domiciliaria',
                          hintText: 'Ej. Av. 9 de Octubre y Malecón',
                          prefixIcon: Icon(Icons.home, color: Colors.teal),
                          helperText: 'Dirección de residencia',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'La dirección es obligatoria';
                          }
                          if (val.trim().length < 4) {
                            return 'Debe ingresar una dirección más detallada';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Ciudad: SOLO LETRAS
                      TextFormField(
                        controller: _ciudadCtrl,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                          hintText: 'Ej. Guayaquil, Quito, Ambato',
                          prefixIcon: Icon(Icons.location_city, color: Colors.teal),
                          helperText: 'Solo se permiten letras y espacios',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'La ciudad es obligatoria';
                          }
                          if (val.trim().length < 3) {
                            return 'Debe ingresar al menos 3 caracteres';
                          }
                          if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(val.trim())) {
                            return 'Solo se permiten letras y espacios';
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
                onPressed: _loading ? null : _guardar,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _loading ? 'Guardando...' : 'Guardar Paciente',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}