import 'package:flutter/material.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _notificaciones = true;
  bool _modoFoco = false;
  bool _recordatorios = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E6BA8),
        title: const Text(
          'Ajustes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'Preferencias',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF12314D),
            ),
          ),
          const SizedBox(height: 10),
          _settingTile(
            title: 'Notificaciones',
            subtitle: 'Recibe avisos de nuevas misiones y recordatorios.',
            value: _notificaciones,
            onChanged: (v) => setState(() => _notificaciones = v),
          ),
          _settingTile(
            title: 'Modo foco',
            subtitle: 'Silencia distracciones mientras estudias.',
            value: _modoFoco,
            onChanged: (v) => setState(() => _modoFoco = v),
          ),
          _settingTile(
            title: 'Recordatorios diarios',
            subtitle: 'Resumen rapido de tu progreso cada dia.',
            value: _recordatorios,
            onChanged: (v) => setState(() => _recordatorios = v),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sistema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF12314D),
            ),
          ),
          const SizedBox(height: 10),
          _actionTile(
            icon: Icons.lock_reset,
            title: 'Cambiar contrasena',
            subtitle: 'Actualiza la clave de acceso de tu laboratorio.',
          ),
          _actionTile(
            icon: Icons.help_outline,
            title: 'Centro de ayuda',
            subtitle: 'Resuelve dudas frecuentes.',
          ),
          _actionTile(
            icon: Icons.logout,
            title: 'Cerrar sesion',
            subtitle: 'Sal de la aplicacion de forma segura.',
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0E6BA8),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF12314D),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF4A6275)),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0E6BA8).withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0E6BA8).withOpacity(0.12),
            ),
            child: Icon(icon, color: const Color(0xFF0E6BA8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF12314D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF4A6275), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4A6275)),
        ],
      ),
    );
  }
}
