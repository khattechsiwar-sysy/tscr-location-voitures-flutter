import 'package:flutter/material.dart';

import 'HomePage.dart';
import 'api_service.dart';

String formatDate(DateTime d) =>
    "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

final ValueNotifier<int> vehiculesVersion = ValueNotifier<int>(0);

class AgencePage extends StatelessWidget {
  const AgencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Espace Agence"),
          actions: [
            IconButton(
              tooltip: "Se déconnecter",
              icon: const Icon(Icons.logout),
              onPressed: () {
                currentUser.value = null;
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: kPrimary,
            indicatorColor: kPrimary,
            tabs: [
              Tab(icon: Icon(Icons.directions_car), text: "Véhicules"),
              Tab(icon: Icon(Icons.event_note), text: "Réservations"),
            ],
          ),
        ),
        body: const TabBarView(children: [_VehiculesTab(), _ReservationsTab()]),
      ),
    );
  }
}

class _VehiculesTab extends StatefulWidget {
  const _VehiculesTab();

  @override
  State<_VehiculesTab> createState() => _VehiculesTabState();
}

class _VehiculesTabState extends State<_VehiculesTab> {
  static const _carburants = ['Essence', 'Diesel', 'Hybride', 'Electrique'];
  static const _transmissions = ['Manuelle', 'Automatique'];

  Future<void> _formulaire({Vehicule? existant}) async {
    final marque = TextEditingController(text: existant?.marque ?? '');
    final modele = TextEditingController(text: existant?.modele ?? '');
    final immat = TextEditingController(text: existant?.immatriculation ?? '');
    final prix = TextEditingController(
      text: existant == null ? '' : fmt(existant.prixParJour),
    );
    final ville = TextEditingController(text: existant?.ville ?? '');
    final photo = TextEditingController(text: existant?.photoUrl ?? '');
    final reduction = TextEditingController(
      text: existant is VehiculePromo ? '${existant.reduction}' : '0',
    );
    String carburant = existant?.carburant ?? 'Essence';
    String transmission = existant?.transmission ?? 'Manuelle';
    String? erreur;

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(
            existant == null ? "Ajouter un véhicule" : "Modifier le véhicule",
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: marque, decoration: deco("Marque")),
                const SizedBox(height: 10),
                TextField(controller: modele, decoration: deco("Modèle")),
                const SizedBox(height: 10),
                TextField(
                  controller: immat,
                  decoration: deco("Immatriculation"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: prix,
                  keyboardType: TextInputType.number,
                  decoration: deco("Prix par jour (DT)"),
                ),
                const SizedBox(height: 10),
                TextField(controller: ville, decoration: deco("Ville")),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: carburant,
                  decoration: deco("Carburant"),
                  items: _carburants
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setD(() => carburant = v ?? carburant),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: transmission,
                  decoration: deco("Transmission"),
                  items: _transmissions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setD(() => transmission = v ?? transmission),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reduction,
                  keyboardType: TextInputType.number,
                  decoration: deco("Réduction % (0 = pas de promo)"),
                ),
                const SizedBox(height: 10),
                TextField(controller: photo, decoration: deco("URL photo")),
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
                final p = double.tryParse(prix.text.trim());
                final r = int.tryParse(reduction.text.trim());
                if (marque.text.trim().isEmpty ||
                    modele.text.trim().isEmpty ||
                    immat.text.trim().isEmpty ||
                    ville.text.trim().isEmpty) {
                  setD(() => erreur = "Veuillez remplir tous les champs");
                } else if (p == null || p <= 0) {
                  setD(() => erreur = "Prix invalide");
                } else if (r == null || r < 0 || r > 90) {
                  setD(() => erreur = "Réduction entre 0 et 90");
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

    final p = double.parse(prix.text.trim());
    final r = int.parse(reduction.text.trim());
    final Vehicule nouveau = r > 0
        ? VehiculePromo(
            marque: marque.text.trim(),
            modele: modele.text.trim(),
            immatriculation: immat.text.trim(),
            photoUrl: photo.text.trim(),
            prixParJour: p,
            ville: ville.text.trim(),
            carburant: carburant,
            transmission: transmission,
            reduction: r,
          )
        : Vehicule(
            marque: marque.text.trim(),
            modele: modele.text.trim(),
            immatriculation: immat.text.trim(),
            photoUrl: photo.text.trim(),
            prixParJour: p,
            ville: ville.text.trim(),
            carburant: carburant,
            transmission: transmission,
          );

    setState(() {
      if (existant == null) {
        listeVehicules.add(nouveau);
      } else {
        final i = listeVehicules.indexOf(existant);
        if (i >= 0) listeVehicules[i] = nouveau;
      }
    });
    vehiculesVersion.value++;
  }

  Future<void> _supprimer(Vehicule v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le véhicule"),
        content: Text(
          "Supprimer ${v.marque} ${v.modele} (${v.immatriculation}) ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => listeVehicules.remove(v));
      vehiculesVersion.value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _formulaire(),
        icon: const Icon(Icons.add),
        label: const Text("Ajouter"),
      ),
      body: listeVehicules.isEmpty
          ? const Center(child: Text("Aucun véhicule"))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: listeVehicules.length,
              itemBuilder: (context, i) {
                final v = listeVehicules[i];
                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  child: ListTile(
                    leading: SizedBox(
                      width: 56,
                      child: Image.network(
                        v.photoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.directions_car),
                      ),
                    ),
                    title: Text("${v.marque} ${v.modele}"),
                    subtitle: Text(
                      "${v.immatriculation} • ${v.ville}\n"
                      "${v is VehiculePromo ? "${fmt(v.prixApresReduction)} DT (-${v.reduction}%)" : "${fmt(v.prixParJour)} DT"} / jour",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: kPrimary),
                          onPressed: () => _formulaire(existant: v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _supprimer(v),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ReservationsTab extends StatefulWidget {
  const _ReservationsTab();

  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab> {
  late Future<List<ReservationInfo>> _future = ReservationApi.lister();
  final Set<int> _enCours = {};

  void _recharger() => setState(() => _future = ReservationApi.lister());

  Future<void> _statut(ReservationInfo r, bool accepter) async {
    if (_enCours.contains(r.id)) return;
    setState(() => _enCours.add(r.id));

    final err = await ReservationApi.changerStatut(r.id, accepter);
    if (!mounted) return;

    _enCours.remove(r.id);
    if (err != null && !err.contains('déjà')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }

    _recharger();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReservationInfo>>(
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
                const Text("Impossible de charger les réservations"),
                TextButton(
                  onPressed: _recharger,
                  child: const Text("Réessayer"),
                ),
              ],
            ),
          );
        }
        final liste = [...snap.data!]
          ..sort((a, b) {
            int o(String s) => s == 'EN_ATTENTE' ? 0 : 1;
            final c = o(a.statut).compareTo(o(b.statut));
            return c != 0 ? c : b.id.compareTo(a.id);
          });
        if (liste.isEmpty) {
          return const Center(child: Text("Aucune réservation pour le moment"));
        }
        return RefreshIndicator(
          onRefresh: () async => _recharger(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: liste.length,
            itemBuilder: (context, i) {
              final r = liste[i];
              final occupe = _enCours.contains(r.id);
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
                      Text("Client : ${r.clientNom}"),
                      Text("Email : ${r.clientEmail}"),
                      Text(
                        "Du ${formatDate(r.dateDebut)} au ${formatDate(r.dateFin)}",
                      ),
                      Text("Permis : ${r.numeroPermis}"),
                      Text("Né(e) le : ${formatDate(r.dateNaissance)}"),
                      Text("Adresse : ${r.adresse} • Ville : ${r.ville}"),
                      Text(
                        "${r.nombreJours} jour(s) • Total : ${fmt(r.prixEstime)} DT",
                      ),
                      if (r.statut == 'EN_ATTENTE') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: occupe
                                    ? null
                                    : () => _statut(r, true),
                                icon: const Icon(Icons.check),
                                label: const Text("Accepter"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: occupe
                                    ? null
                                    : () => _statut(r, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text("Refuser"),
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
    );
  }
}
