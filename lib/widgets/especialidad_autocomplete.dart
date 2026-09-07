import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EspecialidadAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Color primaryColor;
  final List<String> especialidadesDisponibles;

  const EspecialidadAutocomplete({
    super.key,
    required this.controller,
    this.validator,
    this.primaryColor = const Color(0xFF00796B),
    this.especialidadesDisponibles = const [
      'Cardiología',
      'Pediatría',
      'Medicina General',
      'Especialidad 1',
      'Especialidad 2',
    ],
  });

  @override
  State<EspecialidadAutocomplete> createState() => _EspecialidadAutocompleteState();
}

class _EspecialidadAutocompleteState extends State<EspecialidadAutocomplete> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return const Iterable<String>.empty();
        }
        // Al escribir cualquier letra, muestra las especialidades que coincidan
        final matches = widget.especialidadesDisponibles.where((esp) {
          return esp.toLowerCase().contains(query);
        }).toList();

        // Si hay coincidencias específicas se muestran; si no, todas las de la base
        if (matches.isEmpty) {
          return widget.especialidadesDisponibles;
        }
        return matches;
      },
      onSelected: (String selection) {
        widget.controller.text = selection;
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: textEditingController,
          focusNode: fieldFocusNode,
          keyboardType: TextInputType.text,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
          ],
          decoration: InputDecoration(
            labelText: 'Especialidad Médica',
            hintText: 'Ej. Cardiología, Pediatría, Medicina General',
            prefixIcon: Icon(Icons.medical_services, color: widget.primaryColor),
            helperText: 'Al escribir cualquier letra se abre el combo de especialidades',
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              onPressed: () {
                if (!fieldFocusNode.hasFocus) {
                  fieldFocusNode.requestFocus();
                }
              },
            ),
          ),
          validator: widget.validator ??
              (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'La especialidad es obligatoria';
                }
                if (val.trim().length < 3) {
                  return 'Debe ingresar al menos 3 caracteres';
                }
                if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(val.trim())) {
                  return 'Solo se permiten letras y espacios';
                }
                return null;
              },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: widget.primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    );
  }
}
