import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Client {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;

  Client({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.role = 'CLIENT',
  });

  bool get isAgence => role == 'AGENCE';

  factory Client.fromJson(Map<String, dynamic> j) => Client(
    id: j['id'],
    nom: j['nom'],
    prenom: j['prenom'],
    email: j['email'],
    role: j['role'] ?? 'CLIENT',
  );
}

final ValueNotifier<Client?> currentUser = ValueNotifier<Client?>(null);

class ApiService {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081/api/auth';
    }
    return 'http://localhost:8081/api/auth';
  }

  static const _headers = {'Content-Type': 'application/json'};

  static String _message(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body['message'] ?? 'Erreur';
    } catch (_) {
      return 'Erreur serveur';
    }
  }

  static Future<String?> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String motDePasse,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'email': email,
          'motDePasse': motDePasse,
        }),
      );
      if (res.statusCode == 201) return null;
      return _message(res);
    } catch (_) {
      return 'Impossible de contacter le serveur';
    }
  }

  static Future<(Client?, String?)> login({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'motDePasse': motDePasse}),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        return (Client.fromJson(json), null);
      }
      return (null, _message(res));
    } catch (_) {
      return (null, 'Impossible de contacter le serveur');
    }
  }
}

String isoDate(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

class ReservationApi {
  static String get _root {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    }
    return 'http://localhost:8081';
  }

  static Future<String?> creer({
    required int clientId,
    required String vehiculeNom,
    required String immatriculation,
    required String ville,
    required String adresse,
    required String numeroPermis,
    required DateTime dateNaissance,
    required DateTime dateDebut,
    required DateTime dateFin,
    required int nombreJours,
    required double prixParJour,
    required double prixEstime,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_root/api/reservations'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
          'vehiculeNom': vehiculeNom,
          'immatriculation': immatriculation,
          'ville': ville,
          'adresse': adresse,
          'numeroPermis': numeroPermis,
          'dateNaissance': isoDate(dateNaissance),
          'dateDebut': isoDate(dateDebut),
          'dateFin': isoDate(dateFin),
          'nombreJours': nombreJours,
          'prixParJour': prixParJour,
          'prixEstime': prixEstime,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return 'Erreur ${res.statusCode} : ${ApiService._message(res)}';
    } catch (_) {
      return 'Impossible de contacter le serveur';
    }
  }

  static Future<List<ReservationInfo>> lister({int? clientId}) async {
    final url = clientId == null
        ? '$_root/api/reservations'
        : '$_root/api/reservations/client/$clientId';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data
        .map((e) => ReservationInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<String?> changerStatut(int id, bool accepter) async {
    try {
      final res = await http.put(
        Uri.parse(
          '$_root/api/reservations/$id/${accepter ? 'accepter' : 'refuser'}',
        ),
      );
      if (res.statusCode == 200) return null;
      return ApiService._message(res);
    } catch (_) {
      return 'Impossible de contacter le serveur';
    }
  }

  static Future<String?> modifier(
    int id, {
    required String ville,
    required String adresse,
    required String numeroPermis,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_root/api/reservations/$id'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ville': ville,
          'adresse': adresse,
          'numeroPermis': numeroPermis,
          'dateDebut': isoDate(dateDebut),
          'dateFin': isoDate(dateFin),
        }),
      );
      if (res.statusCode == 200) return null;
      return ApiService._message(res);
    } catch (_) {
      return 'Impossible de contacter le serveur';
    }
  }

  static Future<String?> supprimer(int id) async {
    try {
      final res = await http.delete(Uri.parse('$_root/api/reservations/$id'));
      if (res.statusCode == 200 || res.statusCode == 204) return null;
      return ApiService._message(res);
    } catch (_) {
      return 'Impossible de contacter le serveur';
    }
  }
}

class ReservationInfo {
  final int id;
  final String vehiculeNom, immatriculation, ville, adresse, numeroPermis;
  final String statut, clientNom, clientEmail;
  final DateTime dateNaissance, dateDebut, dateFin;
  final int nombreJours;
  final double prixParJour, prixEstime;

  ReservationInfo({
    required this.id,
    required this.vehiculeNom,
    required this.immatriculation,
    required this.ville,
    required this.adresse,
    required this.numeroPermis,
    required this.statut,
    required this.clientNom,
    required this.clientEmail,
    required this.dateNaissance,
    required this.dateDebut,
    required this.dateFin,
    required this.nombreJours,
    required this.prixParJour,
    required this.prixEstime,
  });

  factory ReservationInfo.fromJson(Map<String, dynamic> j) => ReservationInfo(
    id: j['id'],
    vehiculeNom: j['vehiculeNom'] ?? '',
    immatriculation: j['immatriculation'] ?? '',
    ville: j['ville'] ?? '',
    adresse: j['adresse'] ?? '',
    numeroPermis: j['numeroPermis'] ?? '',
    statut: j['statut'] ?? 'EN_ATTENTE',
    clientNom: j['clientNom'] ?? '',
    clientEmail: j['clientEmail'] ?? '',
    dateNaissance: DateTime.parse(j['dateNaissance']),
    dateDebut: DateTime.parse(j['dateDebut']),
    dateFin: DateTime.parse(j['dateFin']),
    nombreJours: (j['nombreJours'] as num).toInt(),
    prixParJour: (j['prixParJour'] as num).toDouble(),
    prixEstime: (j['prixEstime'] as num).toDouble(),
  );

  String get libelleStatut => switch (statut) {
    'ACCEPTEE' => "Acceptée",
    'REFUSEE' => "Refusée",
    _ => "En attente",
  };

  Color get couleurStatut => switch (statut) {
    'ACCEPTEE' => Colors.green,
    'REFUSEE' => Colors.red,
    _ => Colors.orange,
  };
}

final ValueNotifier<int> notifsNonLues = ValueNotifier<int>(0);

class NotificationInfo {
  final int id;
  final String titre, message;
  final DateTime date;
  final bool lue;

  NotificationInfo({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    required this.lue,
  });

  factory NotificationInfo.fromJson(Map<String, dynamic> j) => NotificationInfo(
    id: j['id'],
    titre: j['titre'] ?? '',
    message: j['message'] ?? '',
    date: DateTime.parse(j['dateEnvoi']),
    lue: j['estLue'] ?? false,
  );

  bool get acceptee => titre.toLowerCase().contains('accept');
}

class NotificationApi {
  static Future<List<NotificationInfo>> lister(int clientId) async {
    final res = await http.get(
      Uri.parse('${ReservationApi._root}/api/notifications/client/$clientId'),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data
        .map((e) => NotificationInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> marquerLue(int id) async {
    try {
      await http.put(
        Uri.parse('${ReservationApi._root}/api/notifications/$id/lue'),
      );
    } catch (_) {}
  }

  static Future<void> chargerNonLues() async {
    final user = currentUser.value;
    if (user == null || user.isAgence) {
      notifsNonLues.value = 0;
      return;
    }
    try {
      final liste = await lister(user.id);
      notifsNonLues.value = liste.where((n) => !n.lue).length;
    } catch (_) {}
  }
}
