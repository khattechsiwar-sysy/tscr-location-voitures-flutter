import 'package:flutter/material.dart';

import 'HomePage.dart';
import 'api_service.dart';

String formatDate(DateTime d) =>
    "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

class AgencePage extends StatelessWidget {
  const AgencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: const _ReservationsTab(),
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
