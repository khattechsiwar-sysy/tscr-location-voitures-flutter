import 'package:flutter/material.dart';

import 'agence_page.dart';
import 'SignupPage.dart';
import 'api_service.dart';

const Color kPink = Color(0xFFD32381);

class loginPage extends StatefulWidget {
  const loginPage({super.key});

  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _seConnecter() async {
    final email = _emailController.text.trim();
    final mdp = _passwordController.text;

    if (email.isEmpty && mdp.isEmpty) {
      _msg('Veuillez remplir les deux champs');
      return;
    } else if (email.isEmpty) {
      _msg('Veuillez saisir votre email');
      return;
    } else if (mdp.isEmpty) {
      _msg('Veuillez saisir votre mot de passe');
      return;
    }

    setState(() => _loading = true);
    final (client, erreur) = await ApiService.login(
      email: email,
      motDePasse: mdp,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (client == null) {
      _msg(erreur ?? 'Erreur de connexion');
      return;
    }

    currentUser.value = client;
    final nav = Navigator.of(context);
    if (client.isAgence) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AgencePage()),
        (route) => route.isFirst,
      );
    } else {
      nav.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: kPink, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tunisia Smart Rental Car',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Connectez Vous Pour Réserver',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 117, 106, 109),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: kPink, width: 2),
                        ),
                        floatingLabelStyle: TextStyle(color: kPink),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      onSubmitted: (_) => _seConnecter(),
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: kPink, width: 2),
                        ),
                        floatingLabelStyle: TextStyle(color: kPink),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _loading ? null : _seConnecter,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const signupPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Vous n'avez pas de compte ? Créez-en un !",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: kPink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
