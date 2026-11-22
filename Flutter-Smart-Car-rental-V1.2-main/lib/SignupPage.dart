import 'package:flutter/material.dart';

import 'loginPage.dart';
import 'api_service.dart';

const Color kPink = Color(0xFFD32381);

class signupPage extends StatefulWidget {
  const signupPage({super.key});

  @override
  State<signupPage> createState() => _signupPageState();
}

class _signupPageState extends State<signupPage> {
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _tel = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _tel.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String? _valider() {
    final mdp = _password.text;
    if (_nom.text.trim().isEmpty ||
        _prenom.text.trim().isEmpty ||
        _tel.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        mdp.isEmpty ||
        _confirm.text.isEmpty) {
      return 'Veuillez remplir tous les champs';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(_tel.text.trim())) {
      return 'Le numéro de téléphone doit contenir uniquement des chiffres';
    }
    if (_tel.text.trim().length != 8) {
      return 'Le numéro de téléphone doit contenir 8 chiffres';
    }
    if (!_email.text.contains('@')) return 'Email incorrect';
    if (mdp.length < 6)
      return 'Le mot de passe doit contenir au moins 6 caractères';
    if (!mdp.contains(RegExp(r'[A-Z]'))) {
      return 'Le mot de passe doit contenir une lettre majuscule';
    }
    if (!mdp.contains(RegExp(r'[0-9]')))
      return 'Le mot de passe doit contenir un chiffre';
    if (!mdp.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) {
      return 'Le mot de passe doit contenir un caractère spécial';
    }
    if (mdp != _confirm.text) return 'Les mots de passe ne sont pas identiques';
    return null;
  }

  Future<void> _creerCompte() async {
    final erreurLocale = _valider();
    if (erreurLocale != null) {
      _msg(erreurLocale);
      return;
    }

    setState(() => _loading = true);
    final erreur = await ApiService.register(
      nom: _nom.text.trim(),
      prenom: _prenom.text.trim(),
      telephone: _tel.text.trim(),
      email: _email.text.trim(),
      motDePasse: _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (erreur != null) {
      _msg(erreur);
      return;
    }

    _msg('Compte créé avec succès, connectez-vous');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const loginPage()),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: kPink, width: 2),
    ),
    floatingLabelStyle: const TextStyle(color: kPink),
  );

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
                      'Créez Votre Compte Pour Réserver',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 117, 106, 109),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nom,
                      decoration: _deco('Nom', Icons.person),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _prenom,
                      decoration: _deco('Prénom', Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tel,
                      keyboardType: TextInputType.phone,
                      decoration: _deco('Téléphone', Icons.phone),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _deco('Email', Icons.email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: _deco('Mot de passe', Icons.lock),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: _deco(
                        'Confirmation du mot de passe',
                        Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _loading ? null : _creerCompte,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Créer mon compte'),
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
