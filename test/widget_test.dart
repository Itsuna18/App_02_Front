import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_medicity/screens/home_screen.dart';
import 'package:front_medicity/screens/registrar_doctor_screen.dart';
import 'package:front_medicity/screens/actualizar_doctor_screen.dart';
import 'package:front_medicity/screens/actualizar_paciente_screen.dart';
import 'package:front_medicity/screens/registrar_cita_screen.dart';

void main() {
  testWidgets('Verifica renderizado de HomeScreen con Vista General y los 3 apartados', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    // Verificamos los 4 destinos de navegación (Vista General inicial + 3 apartados)
    expect(find.text('Vista General'), findsOneWidget);
    expect(find.text('Doctores'), findsOneWidget);
    expect(find.text('Pacientes'), findsOneWidget);
    expect(find.text('Citas Médicas'), findsOneWidget);
  });

  testWidgets('Valida campos de solo letras y validaciones en RegistrarDoctorScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegistrarDoctorScreen()));
    await tester.pumpAndSettle();

    // Intentar presionar guardar con campos vacíos
    await tester.ensureVisible(find.text('Guardar Doctor'));
    await tester.tap(find.text('Guardar Doctor'));
    await tester.pumpAndSettle();

    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('La especialidad es obligatoria'), findsOneWidget);
    expect(find.text('La ciudad es obligatoria'), findsOneWidget);

    // Probar que el campo de nombre solo permite letras y espacios
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '123Carlos!!456');
    await tester.pumpAndSettle();
    expect(find.text('Carlos'), findsOneWidget);

    // Probar que el campo de especialidad solo permite letras y espacios
    await tester.enterText(textFields.at(1), '12Cardiologia34!!');
    await tester.pumpAndSettle();
    expect(find.text('Cardiologia'), findsOneWidget);

    // Probar que el campo de ciudad solo permite letras y espacios
    await tester.enterText(textFields.at(2), 'Quito99##');
    await tester.pumpAndSettle();
    expect(find.text('Quito'), findsOneWidget);
  });

  testWidgets('Valida ActualizarDoctorScreen con EspecialidadAutocomplete', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ActualizarDoctorScreen(
          initialId: 1,
          initialNombre: 'Dra. María Solís',
          initialEspecialidad: 'Pediatría',
          initialCiudad: 'Quito',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actualizar Doctor'), findsNWidgets(2)); // AppBar y Botón
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Dra. María Solís'), findsOneWidget);
    expect(find.text('Pediatría'), findsOneWidget);
    expect(find.text('Quito'), findsOneWidget);
  });

  testWidgets('Valida ActualizarPacienteScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ActualizarPacienteScreen(
          initialNombre: 'Juan Antonio Pérez',
          initialFechaNacimiento: '1995-03-20',
          initialDireccion: 'Av. Amazonas y Colón',
          initialCiudad: 'Quito',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actualizar Paciente'), findsNWidgets(2)); // AppBar y Botón
    expect(find.text('Juan Antonio Pérez'), findsOneWidget);
    expect(find.text('1995-03-20'), findsOneWidget);
    expect(find.text('Av. Amazonas y Colón'), findsOneWidget);
    expect(find.text('Quito'), findsOneWidget);
  });

  testWidgets('Valida combos y restricción de paciente y doctor en RegistrarCitaScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockPacientes = [
      PacienteItem(id: 1, nombre: 'PACIENTE 1', fechaNacimiento: '1995-01-02', direccion: 'CENTRO', ciudad: 'QUITO', totalCitas: 1),
      PacienteItem(id: 2, nombre: 'PACIENTE 2', fechaNacimiento: '1995-11-02', direccion: 'NORTE', ciudad: 'AMBATO', totalCitas: 1),
    ];
    final mockDoctores = [
      DoctorItem(id: 1, nombre: 'JUAN', especialidad: 'CARDIOLOGÍA', ciudad: 'QUITO', totalCitas: 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: RegistrarCitaScreen(
          pacientesDisponibles: mockPacientes,
          doctoresDisponibles: mockDoctores,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Intentar guardar con campos vacíos
    await tester.ensureVisible(find.text('Agendar Cita Médica'));
    await tester.tap(find.text('Agendar Cita Médica'));
    await tester.pumpAndSettle();

    expect(find.text('Debe ingresar un paciente'), findsOneWidget);
    expect(find.text('Debe ingresar un doctor'), findsOneWidget);

    // Ingresar un paciente no registrado en la base de datos
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Paciente Inexistente');
    await tester.enterText(textFields.at(1), 'Doctor Desconocido');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Agendar Cita Médica'));
    await tester.tap(find.text('Agendar Cita Médica'));
    await tester.pumpAndSettle();

    expect(find.text('No existe en la base de datos. Elija uno del combo.'), findsNWidgets(2));
  });
}
