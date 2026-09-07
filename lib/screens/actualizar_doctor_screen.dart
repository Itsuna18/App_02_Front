import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ActualizarDoctorScreen extends StatefulWidget {
  final int? initialId;
  final String? initialNombre;
  final String? initialEspecialidad;
  final String? initialCiudad;

  const ActualizarDoctorScreen({
    super.key,
    this.initialId,
    this.initialNombre,
    this.initialEspecialidad,
    this.initialCiudad,
  });

  @override
  State<ActualizarDoctorScreen> createState() => _ActualizarDoctorScreenState();
}

class _ActualizarDoctorScreenState extends State<ActualizarDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idDoctorCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  int? _selectedEspecialidadId;
  int? _selectedCiudadId;

  List<Map<String, dynamic>> _especialidades = [];
  List<Map<String, dynamic>> _ciudades = [];

  bool _loading = false;
  bool _loadingCatalogos = true;

  static const Color _primaryColor = Color(0xFF00796B);
  static const Color _accentLight = Color(0xFFE0F2F1);

  @override
  void initState() {
    super.initState();
    if (widget.initialId != null) {
      _idDoctorCtrl.text = widget.initialId.toString();
    }
    if (widget.initialNombre != null) {
      _nombreCtrl.text = widget.initialNombre!;
    }
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    setState(() => _loadingCatalogos = true);
    try {
      final results = await Future.wait([
        ApiService.getEspecialidades(),
        ApiService.getCiudades(),
      ]);

      if (mounted) {
        setState(() {
          _especialidades = results[0];
          _ciudades = results[1];

          if (_especialidades.isNotEmpty) {
            _selectedEspecialidadId = _especialidades.first['id'];
          }
          if (_ciudades.isNotEmpty) {
            _selectedCiudadId = _ciudades.first['id'];
          }
          _loadingCatalogos = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCatalogos = false);
      }
    }
  }

  @override
  void dispose() {
    _idDoctorCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _actualizar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEspecialidadId == null || _selectedCiudadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una especialidad y una ciudad v�lidas'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final msg = await ApiService.actualizarDoctor(
        int.parse(_idDoctorCtrl.text.trim()),
        _nombreCtrl.text.trim(),
        _selectedEspecialidadId!,
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
        title: const Text('Actualizar Doctor'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _loadingCatalogos
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
                                  child: Icon(Icons.edit, color: _primaryColor),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Modificar Doctor (Sitio B)',
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Actualiza los datos del m�dico en la BD remota',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 28),

                            // Campo ID
                            TextFormField(
                              controller: _idDoctorCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'ID del Doctor en Sitio B',
                                prefixIcon: const Icon(Icons.tag, color: _primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'El ID es obligatorio';
                                if (int.tryParse(val.trim()) == null) return 'Ingrese un n�mero v�lido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Campo Nombre
                            TextFormField(
                              controller: _nombreCtrl,
                              keyboardType: TextInputType.name,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z������������\s]')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Nombre Actualizado del Doctor',
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

                            // Desplegable de Especialidades Reales
                            DropdownButtonFormField<int>(
                              initialValue: _selectedEspecialidadId,
                              decoration: InputDecoration(
                                labelText: 'Especialidad (Registrada en Sitio B)',
                                prefixIcon: const Icon(Icons.medical_services, color: _primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                                ),
                              ),
                              items: _especialidades.map((e) {
                                final id = e['id'] as int;
                                final nombre = (e['nombre'] ?? '').toString();
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text('ID $id - $nombre'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedEspecialidadId = val),
                              validator: (val) => val == null ? 'Seleccione una especialidad' : null,
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
                      onPressed: _loading ? null : _actualizar,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.update),
                      label: Text(
                        _loading ? 'Actualizando...' : 'Actualizar Doctor (SP 4)',
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
