import 'package:flutter/material.dart';

import 'api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Set<int> _nouvelles = {};
  late Future<List<NotificationInfo>> _future = _charger();

  Future<List<NotificationInfo>> _charger() async {
    final liste = await NotificationApi.lister(currentUser.value!.id);
    final nonLues = liste.where((n) => !n.lue).toList();
    _nouvelles
      ..clear()
      ..addAll(nonLues.map((n) => n.id));
    await Future.wait(nonLues.map((n) => NotificationApi.marquerLue(n.id)));
    notifsNonLues.value = 0;
    return liste;
  }

  void _recharger() => setState(() => _future = _charger());

  String _date(DateTime d) {
    String deux(int n) => n.toString().padLeft(2, '0');
    return "${deux(d.day)}/${deux(d.month)}/${d.year} ${deux(d.hour)}:${deux(d.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: FutureBuilder<List<NotificationInfo>>(
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
                  const Text("Impossible de charger les notifications"),
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
            return const Center(child: Text("Aucune notification"));
          }
          return RefreshIndicator(
            onRefresh: () async => _recharger(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: liste.length,
              itemBuilder: (context, i) {
                final n = liste[i];
                final nouvelle = _nouvelles.contains(n.id);
                final couleur = n.acceptee ? Colors.green : Colors.red;
                return Card(
                  color: nouvelle ? const Color(0xFFFDEFF6) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: couleur.withOpacity(0.12),
                      child: Icon(
                        n.acceptee ? Icons.check_circle : Icons.cancel,
                        color: couleur,
                      ),
                    ),
                    title: Text(
                      n.titre,
                      style: TextStyle(
                        fontWeight: nouvelle
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text("${n.message}\n${_date(n.date)}"),
                    isThreeLine: true,
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
