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

  int? _selectedCiudadId;
  List<Map<String, dynamic>> _ciudades = [];

  bool _loading = false;
  bool _loadingCiudades = true;

  static const Color _primaryColor = Color(0xFF00796B);
  static const Color _accentLight = Color(0xFFE0F2F1);

  @override
  void initState() {
    super.initState();
    _cargarCiudades();
  }

  Future<void> _cargarCiudades() async {
    setState(() => _loadingCiudades = true);
    try {
      final list = await ApiService.getCiudades();
      if (mounted) {
        setState(() {
          _ciudades = list;
          if (_ciudades.isNotEmpty) {
            _selectedCiudadId = _ciudades.first['id'];
          }
          _loadingCiudades = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCiudades = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fechaCtrl.dispose();
    _dirCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    DateTime initial = DateTime(1998, 5, 15);
    try {
      final parsed = DateTime.tryParse(_fechaCtrl.text);
      if (parsed != null) initial = parsed;
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar Fecha de Nacimiento',
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

    if (_selectedCiudadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una ciudad v�lida'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final msg = await ApiService.insertarPaciente(
        _nombreCtrl.text.trim(),
        _fechaCtrl.text.trim(),
        _dirCtrl.text.trim(),
        _selectedCiudadId!,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Registrar Paciente'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _loadingCiudades
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
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
                                const CircleAvatar(
                                  backgroundColor: _accentLight,
                                  child: Icon(Icons.person_add_alt_1, color: _primaryColor),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nuevo Paciente (Sitio A)',
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Inserta el paciente en la base de datos local',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 28),

                            // Campo Nombre
                            TextFormField(
                              controller: _nombreCtrl,
                              keyboardType: TextInputType.name,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z������������\s]')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Nombre del Paciente',
                                hintText: 'Ej. Juan P�rez',
                                prefixIcon: const Icon(Icons.person, color: _primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'El nombre es obligatorio';
                                if (val.trim().length < 3) return 'M�nimo 3 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Campo Fecha de Nacimiento con Selector
                            TextFormField(
                              controller: _fechaCtrl,
                              readOnly: true,
                              onTap: _seleccionarFecha,
                              decoration: InputDecoration(
                                labelText: 'Fecha de Nacimiento',
                                prefixIcon: const Icon(Icons.calendar_today, color: _primaryColor),
                                suffixIcon: const Icon(Icons.arrow_drop_down, color: _primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                                ),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Seleccione una fecha' : null,
                            ),
                            const SizedBox(height: 18),

                            TextFormField(
                              controller: _dirCtrl,
                              decoration: InputDecoration(
                                labelText: 'Direccion de Residencia',
                                hintText: 'Ej. Av. Cevallos y Castillo',
                                prefixIcon: const Icon(Icons.home, color: _primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'La direccion es obligatoria';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Desplegable de Ciudades Reales
                            DropdownButtonFormField<int>(
                              initialValue: _selectedCiudadId,
                              decoration: InputDecoration(
                                labelText: 'Ciudad (Registrada en Sitio A)',
                                prefixIcon: const Icon(Icons.location_city, color: _primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                                ),
                              ),
                              items: _ciudades.map((c) {
                                final id = c['id'] as int;
                                final nombre = (c['nombre'] ?? '').toString();
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text('ID $id - $nombre'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedCiudadId = val),
                              validator: (val) => val == null ? 'Seleccione una ciudad' : null,
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
                        _loading ? 'Guardando...' : 'Guardar Paciente (SP 2)',
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
