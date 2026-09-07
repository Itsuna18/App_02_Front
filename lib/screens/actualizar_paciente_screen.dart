import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ActualizarPacienteScreen extends StatefulWidget {
  final String initialNombre;
  final String? initialFechaNacimiento;
  final String? initialDireccion;
  final String? initialCiudad;

  const ActualizarPacienteScreen({
    super.key,
    required this.initialNombre,
    this.initialFechaNacimiento,
    this.initialDireccion,
    this.initialCiudad,
  });

  @override
  State<ActualizarPacienteScreen> createState() => _ActualizarPacienteScreenState();
}

class _ActualizarPacienteScreenState extends State<ActualizarPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fechaCtrl;
  late final TextEditingController _dirCtrl;
  late final TextEditingController _ciudadCtrl;
  bool _loading = false;

  static const Color _primaryColor = Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialNombre);
    _fechaCtrl = TextEditingController(text: widget.initialFechaNacimiento ?? '1998-05-15');
    _dirCtrl = TextEditingController(text: widget.initialDireccion ?? '');
    _ciudadCtrl = TextEditingController(text: widget.initialCiudad ?? '');
  }

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

  Future<void> _actualizar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    ApiService.actualizarPacienteLocal(
      widget.initialNombre,
      _nombreCtrl.text.trim(),
      _fechaCtrl.text.trim(),
      _dirCtrl.text.trim(),
      _ciudadCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Datos del paciente actualizados correctamente')),
            ],
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Paciente'),
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
                            child: const Icon(Icons.manage_accounts, color: _primaryColor),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modificar Paciente',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Actualice la información del paciente',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                          prefixIcon: Icon(Icons.person, color: _primaryColor),
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

                      // Campo Fecha de Nacimiento
                      TextFormField(
                        controller: _fechaCtrl,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: 'Fecha de Nacimiento',
                          hintText: 'AAAA-MM-DD',
                          prefixIcon: const Icon(Icons.calendar_month, color: _primaryColor),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar, color: _primaryColor),
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
                          prefixIcon: Icon(Icons.home, color: _primaryColor),
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
                          prefixIcon: Icon(Icons.location_city, color: _primaryColor),
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
                onPressed: _loading ? null : _actualizar,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.update),
                label: Text(
                  _loading ? 'Actualizando...' : 'Actualizar Paciente',
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
