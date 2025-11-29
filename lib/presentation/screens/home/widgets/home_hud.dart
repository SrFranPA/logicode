import 'package:flutter/material.dart';

class HomeHUD extends StatelessWidget {
  final int vidas;
  final int racha;
  final String nombre;
  final String avatarPath; // ruta local del asset

  const HomeHUD({
    super.key,
    required this.vidas,
    required this.racha,
    required this.nombre,
    required this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),

        /// 🔥 Racha + Vidas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.black26,
                    size: 30,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$racha días",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.favorite,
                    color: index < vidas ? Colors.red : Colors.black12,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// 👋 Nombre
        Text(
          "¡Hola, $nombre! 👋",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF303030),
          ),
        ),

        const SizedBox(height: 4),

        /// 🐶 Avatar / mascota
        SizedBox(
          width: 180,
          height: 180,
          child: ClipOval(
            child: Image.asset(
              avatarPath,
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 35),
      ],
    );
  }
}
