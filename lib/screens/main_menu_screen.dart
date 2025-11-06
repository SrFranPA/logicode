import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int selectedIndex = 0;
  User? user;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email;
  }

  /// 🔹 Si el usuario no tiene correo (por login manual), tratamos de buscar por uid
  Stream<QuerySnapshot> _userDataStream() {
    final firestore = FirebaseFirestore.instance.collection('usuarios');
    if (userEmail != null && userEmail!.isNotEmpty) {
      return firestore.where('correo', isEqualTo: userEmail).snapshots();
    } else if (user != null) {
      return firestore.where('uid', isEqualTo: user!.uid).snapshots();
    } else {
      // En caso extremo, no hay usuario
      return const Stream.empty();
    }
  }

  /// 🔹 Pantalla de perfil con datos en vivo desde Firestore
  Widget _buildProfileScreen() {
    if (user == null) {
      return const Center(child: Text("No hay usuario autenticado."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _userDataStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No se encontraron datos del usuario."));
        }

        final userDoc = snapshot.data!.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;
        final docId = userDoc.id;

        final nombre = userData['nombre'] ?? 'Sin nombre';
        final edad = userData['edad']?.toString() ?? 'Sin edad';
        final correo = userData['correo'] ?? 'Sin correo';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: userData['foto'] != null && userData['foto'] != ''
                    ? NetworkImage(userData['foto'])
                    : null,
                child: (userData['foto'] == null || userData['foto'] == '')
                    ? const Icon(Icons.person, size: 70, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 20),

              _editableField("Nombre", nombre, (value) {
                _updateUserField(docId, 'nombre', value);
              }),

              const SizedBox(height: 15),

              _editableField("Edad", edad, (value) {
                _updateUserField(docId, 'edad', int.tryParse(value) ?? 0);
              }, keyboardType: TextInputType.number),

              const SizedBox(height: 15),

              _editableField("Correo", correo, (value) {
                _updateUserField(docId, 'correo', value);
              }),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Cerrar Sesión",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  // 🔹 En vez de solo hacer pop, se reemplaza por HomeScreen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Campo editable reutilizable
  Widget _editableField(String label, String value, Function(String) onSave,
      {TextInputType keyboardType = TextInputType.text}) {
    final controller = TextEditingController(text: value);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.only(top: 4),
          ),
          onSubmitted: onSave,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.save, color: Colors.blueAccent),
          onPressed: () {
            onSave(controller.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$label actualizado")),
            );
          },
        ),
      ),
    );
  }

  /// 🔹 Actualiza campo en Firestore
  Future<void> _updateUserField(String docId, String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(docId).update({field: value});
    } catch (e) {
      debugPrint("Error al actualizar $field: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const Center(child: Text('Aprende', style: TextStyle(fontSize: 24))),
      const Center(child: Text('Refuerzo', style: TextStyle(fontSize: 24))),
      const Center(child: Text('Ranking', style: TextStyle(fontSize: 24))),
      _buildProfileScreen(),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF144578), Color(0xFF0C2E4E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.favorite, color: Color(0xFFF44336)),
                  SizedBox(width: 5),
                  Text('5 Vidas', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              Text(
                'Nivel 1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: screens[selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2)),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: selectedIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFDA8B23),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
            onTap: (index) => setState(() => selectedIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Aprende'),
              BottomNavigationBarItem(icon: Icon(Icons.extension), label: 'Refuerzo'),
              BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Ranking'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}
