import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;
  final Color textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
    required this.onPressed,
    this.textColor = Colors.white,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.textColor),
              const SizedBox(width: 10),
              Text(
                widget.text,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
