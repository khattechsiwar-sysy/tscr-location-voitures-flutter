import 'package:flutter/material.dart';

import 'HomePage.dart';
import 'agence_page.dart';
import 'api_service.dart';

class ReservationFormPage extends StatefulWidget {
  final Vehicule vehicule;
  const ReservationFormPage({super.key, required this.vehicule});

  @override
  State<ReservationFormPage> createState() => _ReservationFormPageState();
}

class _ReservationFormPageState extends State<ReservationFormPage> {
  final _permis = TextEditingController();
  final _adresse = TextEditingController();
  DateTime? _debut;
  DateTime? _fin;
  bool _loading = false;

  @override
  void dispose() {
    _permis.dispose();
    _adresse.dispose();
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  DateTime get _aujourdhui {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  int get _jours =>
      (_debut != null && _fin != null) ? _fin!.difference(_debut!).inDays : 0;

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: kPrimary, width: 2),
    ),
    floatingLabelStyle: const TextStyle(color: kPrimary),
  );

  Widget _champDate(
    String label,
    IconData icon,
    DateTime? valeur,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _deco(label, icon),
        child: Text(
          valeur == null ? "Choisir une date" : formatDate(valeur),
          style: TextStyle(
            color: valeur == null ? Colors.grey[600] : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _choisirDebut() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _debut ?? _aujourdhui,
      firstDate: _aujourdhui,
      lastDate: _aujourdhui.add(const Duration(days: 730)),
    );
    if (d == null) return;
    setState(() {
      _debut = d;
      if (_fin != null && !_fin!.isAfter(d)) _fin = null;
    });
  }

  Future<void> _choisirFin() async {
    final premier = (_debut ?? _aujourdhui).add(const Duration(days: 1));
    final d = await showDatePicker(
      context: context,
      initialDate: (_fin != null && !_fin!.isBefore(premier)) ? _fin! : premier,
      firstDate: premier,
      lastDate: premier.add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _fin = d);
  }

  String? _valider() {
    if (_permis.text.trim().isEmpty) {
      return "Veuillez saisir le numéro de permis";
    }
    if (_adresse.text.trim().isEmpty) return "Veuillez saisir votre adresse";
    if (_debut == null || _fin == null) {
      return "Veuillez choisir les dates de location";
    }
    if (_jours < 1) return "La date de fin doit être après la date de début";
    return null;
  }

  Future<void> _envoyer() async {
    final erreurLocale = _valider();
    if (erreurLocale != null) {
      _msg(erreurLocale);
      return;
    }
    final user = currentUser.value;
    if (user == null) return;

    final v = widget.vehicule;
    final prixJour = v.prixApresReductionCalculated;
    final jours = _jours;

    setState(() => _loading = true);
    final erreur = await ReservationApi.creer(
      clientId: user.id,
      vehiculeNom: "${v.marque} ${v.modele}",
      immatriculation: v.immatriculation,
      ville: v.ville,
      adresse: _adresse.text.trim(),
      numeroPermis: _permis.text.trim(),
      dateDebut: _debut!,
      dateFin: _fin!,
      nombreJours: jours,
      prixParJour: prixJour,
      prixEstime: jours * prixJour,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (erreur != null) {
      _msg(erreur);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "Demande envoyée pour ${v.marque} ${v.modele} ($jours jour(s)), en attente de l'agence",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicule;
    return Scaffold(
      appBar: AppBar(title: Text("Réserver ${v.marque} ${v.modele}")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Informations du conducteur",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _permis,
                      decoration: _deco("Numéro de permis", Icons.badge),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _adresse,
                      decoration: _deco("Adresse", Icons.home),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Période de location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _champDate(
                      "Date de début",
                      Icons.event,
                      _debut,
                      _choisirDebut,
                    ),
                    const SizedBox(height: 12),
                    _champDate(
                      "Date de fin",
                      Icons.event_available,
                      _fin,
                      _choisirFin,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _loading ? null : _envoyer,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Confirmer la réservation"),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text("Annuler"),
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
