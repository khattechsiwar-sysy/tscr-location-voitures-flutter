import 'package:flutter/material.dart';

import 'HomePage.dart';
import 'agence_page.dart';
import 'api_service.dart';

class MesReservationsPage extends StatefulWidget {
  const MesReservationsPage({super.key});

  @override
  State<MesReservationsPage> createState() => _MesReservationsPageState();
}

class _MesReservationsPageState extends State<MesReservationsPage> {
  late Future<List<ReservationInfo>> _future = _charger();

  Future<List<ReservationInfo>> _charger() =>
      ReservationApi.lister(clientId: currentUser.value!.id);

  void _recharger() => setState(() => _future = _charger());

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _supprimer(ReservationInfo r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la réservation"),
        content: Text("Supprimer la réservation de ${r.vehiculeNom} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await ReservationApi.supprimer(r.id);
    if (!mounted) return;
    _msg(err ?? "Réservation supprimée");
    _recharger();
  }

  Future<void> _modifier(ReservationInfo r) async {
    final ville = TextEditingController(text: r.ville);
    final adresse = TextEditingController(text: r.adresse);
    final permis = TextEditingController(text: r.numeroPermis);
    DateTime debut = r.dateDebut;
    DateTime fin = r.dateFin;
    String? erreur;
    final now = DateTime.now();
    final aujourdhui = DateTime(now.year, now.month, now.day);

    InputDecoration deco(String l) => InputDecoration(
      labelText: l,
      isDense: true,
      border: const OutlineInputBorder(),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text("Modifier la réservation"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ville, decoration: deco("Ville")),
                const SizedBox(height: 10),
                TextField(controller: adresse, decoration: deco("Adresse")),
                const SizedBox(height: 10),
                TextField(
                  controller: permis,
                  decoration: deco("Numéro de permis"),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: debut.isBefore(aujourdhui)
                          ? aujourdhui
                          : debut,
                      firstDate: aujourdhui,
                      lastDate: aujourdhui.add(const Duration(days: 730)),
                    );
                    if (d != null) {
                      setD(() {
                        debut = d;
                        if (!fin.isAfter(d)) {
                          fin = d.add(const Duration(days: 1));
                        }
                      });
                    }
                  },
                  child: Text("Début : ${formatDate(debut)}"),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final premier = debut.add(const Duration(days: 1));
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: fin.isBefore(premier) ? premier : fin,
                      firstDate: premier,
                      lastDate: premier.add(const Duration(days: 730)),
                    );
                    if (d != null) setD(() => fin = d);
                  },
                  child: Text("Fin : ${formatDate(fin)}"),
                ),
                if (erreur != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      erreur!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (ville.text.trim().isEmpty ||
                    adresse.text.trim().isEmpty ||
                    permis.text.trim().isEmpty) {
                  setD(() => erreur = "Veuillez remplir tous les champs");
                } else {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final err = await ReservationApi.modifier(
      r.id,
      ville: ville.text.trim(),
      adresse: adresse.text.trim(),
      numeroPermis: permis.text.trim(),
      dateDebut: debut,
      dateFin: fin,
    );
    if (!mounted) return;
    _msg(err ?? "Réservation modifiée");
    _recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes réservations")),
      body: FutureBuilder<List<ReservationInfo>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Impossible de charger vos réservations"),
                  TextButton(
                    onPressed: _recharger,
                    child: const Text("Réessayer"),
                  ),
                ],
              ),
            );
          }
          final liste = snap.data!;
          if (liste.isEmpty) {
            return const Center(child: Text("Aucune réservation"));
          }
          return RefreshIndicator(
            onRefresh: () async => _recharger(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: liste.length,
              itemBuilder: (context, i) {
                final r = liste[i];
                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.vehiculeNom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                r.libelleStatut,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: r.couleurStatut,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        Text(
                          "Du ${formatDate(r.dateDebut)} au ${formatDate(r.dateFin)}",
                        ),
                        Text("Ville : ${r.ville} • Adresse : ${r.adresse}"),
                        Text("Permis : ${r.numeroPermis}"),
                        Text(
                          "${r.nombreJours} jour(s) • Total : ${fmt(r.prixEstime)} DT",
                        ),
                        if (r.statut == 'EN_ATTENTE') ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _modifier(r),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text("Modifier"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _supprimer(r),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text("Supprimer"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
