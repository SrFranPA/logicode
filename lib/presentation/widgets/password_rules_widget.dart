// lib/presentation/widgets/password_rules_widget.dart

import 'package:flutter/material.dart';

class PasswordRulesWidget extends StatelessWidget {
  final String password;

  const PasswordRulesWidget({super.key, required this.password});

  bool get hasMinLength => password.length >= 8;
  bool get hasUpper => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLower => RegExp(r'[a-z]').hasMatch(password);
  bool get hasNumber => RegExp(r'\d').hasMatch(password);
  bool get hasSymbol =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-_/\\]').hasMatch(password);
  bool get hasNoSpaces => !password.contains(' ');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rule("Mínimo 8 caracteres", hasMinLength),
        _rule("Una mayúscula (A-Z)", hasUpper),
        _rule("Una minúscula (a-z)", hasLower),
        _rule("Un número (0-9)", hasNumber),
        _rule("Un símbolo (!, @, #, ...)", hasSymbol),
        _rule("Sin espacios", hasNoSpaces),
      ],
    );
  }

  Widget _rule(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              color: ok ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    color: ok ? Colors.green.shade700 : Colors.black54,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
