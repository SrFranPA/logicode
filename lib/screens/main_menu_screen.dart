import 'package:flutter/material.dart';

class MainMenuScreen extends StatefulWidget {
  MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = [
    const Center(child: Text('📘 Aprende', style: TextStyle(fontSize: 24))),
    const Center(child: Text('🧠 Refuerzo', style: TextStyle(fontSize: 24))),
    const Center(child: Text('🏆 Clasificación', style: TextStyle(fontSize: 24))),
    const Center(child: Text('👤 Perfil', style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
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
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))
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
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: screens[selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
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
