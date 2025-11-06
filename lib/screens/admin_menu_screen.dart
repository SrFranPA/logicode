import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart'; // ✅ Pantalla principal

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  int _currentIndex = 0; // Control del menú inferior
  bool _isLoading = true; // Indicador de carga
  List<Map<String, dynamic>> _students = []; // Lista de estudiantes

  @override
  void initState() {
    super.initState();
    _loadStudents(); // Cargar estudiantes al iniciar
  }

  /// 🔹 Cargar estudiantes desde Cloud Firestore
  Future<void> _loadStudents() async {
    try {
      // Referencia a la colección 'users' en Firestore
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> studentsList = [];

      // Recorremos todos los documentos de la colección
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['nombre'] != null && data['nombre'] != 'admin') {
          studentsList.add({
            'nombre': data['nombre'],
            'edad': data['edad'] ?? 'N/A',
            'nivel': data['nivel'] ?? 'Básico',
          });
        }
      }

      setState(() {
        _students = studentsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los estudiantes: $e')),
      );
    }
  }

  /// 🔹 Vista de lista de estudiantes
  Widget _buildStudentsDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_students.isEmpty) {
      return const Center(
        child: Text(
          'No hay estudiantes registrados.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color.fromARGB(255, 202, 94, 55),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              student['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Edad: ${student['edad']}  |  Nivel: ${student['nivel']}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Vista de pruebas simuladas (Dashboard de resultados)
  Widget _buildTestsDashboard() {
    final testData = [
      {'titulo': 'Prueba de Lógica', 'promedio': 85, 'fecha': '10/10/2025'},
      {'titulo': 'Prueba de Matemáticas', 'promedio': 78, 'fecha': '15/10/2025'},
      {'titulo': 'Prueba de Programación', 'promedio': 92, 'fecha': '20/10/2025'},
    ];

    return ListView.builder(
      itemCount: testData.length,
      itemBuilder: (context, index) {
        final test = testData[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFFAFAFA),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.deepOrange),
            title: Text(
              test['titulo'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Promedio: ${test['promedio']}%  |  Fecha: ${test['fecha']}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Cerrar sesión del modo administrador
  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Deseas cerrar la sesión del administrador?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 124, 218, 255),
            ),
            child: const Text("Salir"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildStudentsDashboard(),
      _buildTestsDashboard(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 29, 68, 89),
        title: const Text(
          'Administrador',
          style: TextStyle(
            color: Color.fromARGB(255, 254, 254, 254), // ---------------administrador
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color.fromARGB(255, 255, 255, 255), // -------------- botón de salir
            ),
            tooltip: "Cerrar sesión",
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        selectedItemColor: const Color.fromARGB(255, 29, 89, 90),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Estudiantes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Pruebas',
          ),
        ],
      ),
    );
  }
}
