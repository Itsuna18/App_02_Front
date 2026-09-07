import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/especialidad_autocomplete.dart';

class ActualizarDoctorScreen extends StatefulWidget {
  final int? initialId;
  final String? initialNombre;
  final String? initialEspecialidad;
  final String? initialCiudad;
  final List<String>? especialidadesDisponibles;

  const ActualizarDoctorScreen({
    super.key,
    this.initialId,
    this.initialNombre,
    this.initialEspecialidad,
    this.initialCiudad,
    this.especialidadesDisponibles,
  });

  @override
  State<ActualizarDoctorScreen> createState() => _ActualizarDoctorScreenState();
}

class _ActualizarDoctorScreenState extends State<ActualizarDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idDoctorCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _espCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  bool _loading = false;

  static const Color _primaryColor = Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    if (widget.initialId != null) {
      _idDoctorCtrl.text = widget.initialId.toString();
    }
    if (widget.initialNombre != null) {
      _nombreCtrl.text = widget.initialNombre!;
    }
    if (widget.initialEspecialidad != null) {
      _espCtrl.text = widget.initialEspecialidad!;
    }
    if (widget.initialCiudad != null) {
      _ciudadCtrl.text = widget.initialCiudad!;
    }
  }

  @override
  void dispose() {
    _idDoctorCtrl.dispose();
    _nombreCtrl.dispose();
    _espCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  Future<void> _actualizar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      final msg = await ApiService.actualizarDoctor(
        int.parse(_idDoctorCtrl.text.trim()),
        _nombreCtrl.text.trim(),
        _espCtrl.text.trim(),
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
    final bool isPreselected = widget.initialId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Doctor'),
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
                                  'Modificar Información',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Modifique los datos del médico',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Campo ID Doctor
                      TextFormField(
                        controller: _idDoctorCtrl,
                        readOnly: isPreselected,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'ID del Doctor',
                          hintText: 'Ej. 1',
                          prefixIcon: const Icon(Icons.badge, color: _primaryColor),
                          helperText: isPreselected
                              ? 'Médico seleccionado para edición'
                              : 'Solo dígitos numéricos',
                          filled: isPreselected,
                          fillColor: isPreselected ? _primaryColor.withValues(alpha: 0.05) : null,
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

                      // Campo Nombre del Doctor: SOLO LETRAS
                      TextFormField(
                        controller: _nombreCtrl,
                        keyboardType: TextInputType.name,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo del Doctor',
                          hintText: 'Ej. Dra. María Elena Solís',
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

                      // Campo Especialidad: COMBO AUTOCOMPLETO + SOLO LETRAS
                      EspecialidadAutocomplete(
                        controller: _espCtrl,
                        primaryColor: _primaryColor,
                        especialidadesDisponibles: widget.especialidadesDisponibles ?? const [
                          'Cardiología',
                          'Pediatría',
                          'Medicina General',
                          'Especialidad 1',
                          'Especialidad 2',
                        ],
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
                          hintText: 'Ej. Quito, Guayaquil, Ambato',
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
                  _loading ? 'Actualizando...' : 'Actualizar Doctor',
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
