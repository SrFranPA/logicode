// lib/presentation/widgets/social_login_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

enum SocialProvider { google, facebook, phone }

/// Widget reutilizable que garantiza la misma altura/anchura/estética
/// para todos los botones sociales del modal.
class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final String label;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.label,
    required this.onPressed,
  });

  // altura fija para todos los botones
  static const double _buttonHeight = 55.0;
  static const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    // Todos deben tener la misma caja (width infinito, misma altura).
    return SizedBox(
      width: double.infinity,
      height: _buttonHeight,
      child: _buildByProvider(context),
    );
  }

  Widget _buildByProvider(BuildContext context) {
    switch (provider) {
      case SocialProvider.google:
        // Usamos SignInButton para mantener look oficial, pero forzamos tamaño
        return SignInButton(
          Buttons.Google,
          text: label,
          onPressed: onPressed,
          shape: RoundedRectangleBorder(borderRadius: _borderRadius),
        );

      case SocialProvider.facebook:
        return SignInButton(
          Buttons.FacebookNew,
          text: label,
          onPressed: onPressed,
          shape: RoundedRectangleBorder(borderRadius: _borderRadius),
        );

      case SocialProvider.phone:
        // No hay botón oficial en flutter_signin_button, así que creamos uno con el mismo estilo
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.phone, color: Colors.black87),
          label: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDDDDDD)),
            shape: RoundedRectangleBorder(borderRadius: _borderRadius),
            elevation: 0,
          ),
        );
    }
  }
}

/// Wrappers semánticos para usar en el modal (más legible)
class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleLoginButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      provider: SocialProvider.google,
      label: 'Continuar con Google',
      onPressed: onPressed,
    );
  }
}

class FacebookLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  const FacebookLoginButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      provider: SocialProvider.facebook,
      label: 'Continuar con Facebook',
      onPressed: onPressed,
    );
  }
}

class PhoneLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const PhoneLoginButton({
    super.key,
    required this.onPressed,
    this.label = 'Continuar con teléfono',
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      provider: SocialProvider.phone,
      label: label,
      onPressed: onPressed,
    );
  }
}
