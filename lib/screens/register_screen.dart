import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'main_menu_screen.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  bool allFieldsFilled = false;

  void checkFields() {
    setState(() {
      allFieldsFilled = nameController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          ageController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    nameController.addListener(checkFields);
    emailController.addListener(checkFields);
    ageController.addListener(checkFields);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen()), // sin const
                    );
                  },
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Regístrate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 8, color: Color.fromARGB(120, 255, 255, 255), offset: Offset(2, 2))
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 210,
                        child: Image.asset('assets/images/logoR.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Edad',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.cake),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      CustomButton(
                        text: 'Continuar',
                        color: allFieldsFilled ? const Color(0xFFDA8B23) : Colors.grey,
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          if (allFieldsFilled) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => MainMenuScreen()), // sin const
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ Por favor, completa todos los campos para continuar.'),
                                duration: Duration(seconds: 3),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
