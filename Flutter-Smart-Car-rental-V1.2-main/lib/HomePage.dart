import 'package:flutter/material.dart';

import 'dart:async';

import 'notifications_page.dart';
import 'agence_page.dart';
import 'loginPage.dart';
import 'mes_reservations_page.dart';
import 'SignupPage.dart';
import 'api_service.dart';
import 'reservation_form_page.dart';

const Color kPrimary = Color(0xFFD32381);
const Color kBackground = Color(0xFFF7F5F6);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TSCR - Location de Voitures",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
          primary: kPrimary,
        ),
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kPrimary : null,
          ),
        ),
      ),
      home: const CatalogueVehiculesScreen(),
    );
  }
}

String fmt(double n) =>
    n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(1);

void reserver(BuildContext context, Vehicule v, {int jours = 1}) {
  final user = currentUser.value;
  String? message;
  if (user == null) {
    message = "Connectez-vous pour réserver";
  } else if (user.isAgence) {
    message = "Le compte agence ne peut pas réserver";
  }
  if (message != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ReservationFormPage(vehicule: v)),
  );
}

Widget buildVehiculeCard(
  Vehicule v, {
  VoidCallback? onTap,
  VoidCallback? onReserver,
}) {
  return Card(
    elevation: 2,
    margin: EdgeInsets.zero,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: const Color(0xFFF1EEF0),
                padding: const EdgeInsets.all(12),
                child: Image.network(
                  v.photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.directions_car,
                    size: 60,
                    color: Colors.black38,
                  ),
                ),
              ),
              if (v is VehiculePromo)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "-${v.reduction}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${v.marque} ${v.modele}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Text(
                      v.ville,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        v.immatriculation,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      size: 14,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 3),
                    Text(v.carburant, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 10),
                    Icon(Icons.settings, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        v.transmission,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (v is VehiculePromo)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${fmt(v.prixApresReduction)} DT",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${fmt(v.prixParJour)} DT",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "/ jour",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${fmt(v.prixParJour)} DT",
                        style: const TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "/ jour",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onReserver,
                    label: const Text("Réserver"),
                    icon: const Icon(Icons.calendar_today, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CatalogueVehiculesScreen extends StatefulWidget {
  const CatalogueVehiculesScreen({super.key});

  @override
  State<CatalogueVehiculesScreen> createState() =>
      _CatalogueVehiculesScreenState();
}

class _CatalogueVehiculesScreenState extends State<CatalogueVehiculesScreen> {
  bool _promoSeulement = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    currentUser.addListener(NotificationApi.chargerNonLues);

    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => NotificationApi.chargerNonLues(),
    );
  }

  @override
  void dispose() {
    currentUser.removeListener(NotificationApi.chargerNonLues);
    _timer?.cancel();
    super.dispose();
  }

  List<Vehicule> get _visible => _promoSeulement
      ? listeVehicules.whereType<VehiculePromo>().toList()
      : listeVehicules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TSCR - Véhicules"),
        actions: [
          ValueListenableBuilder<Client?>(
            valueListenable: currentUser,
            builder: (context, user, _) {
              if (user == null) {
                return Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 8.0,
                        top: 8.0,
                        bottom: 8.0,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const loginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Se Connecter",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 12.0,
                        top: 8.0,
                        bottom: 8.0,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const signupPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  if (user.isAgence)
                    IconButton(
                      tooltip: "Espace Agence",
                      icon: const Text("🏢", style: TextStyle(fontSize: 22)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AgencePage(),
                        ),
                      ).then((_) => setState(() {})),
                    ),
                  if (!user.isAgence) ...[
                    IconButton(
                      tooltip: "Mes réservations",
                      icon: const Icon(Icons.event_note),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MesReservationsPage(),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: notifsNonLues,
                      builder: (context, nb, _) => IconButton(
                        tooltip: "Notifications",
                        icon: Badge(
                          isLabelVisible: nb > 0,
                          label: Text("$nb"),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        ).then((_) => NotificationApi.chargerNonLues()),
                      ),
                    ),
                  ],
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      "Salut, ${user.prenom} ${user.nom}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 12.0,
                      top: 8.0,
                      bottom: 8.0,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => currentUser.value = null,
                      child: const Text(
                        "Se déconnecter",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text(
                "Véhicules en Promo",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              secondary: const Icon(Icons.local_offer, color: Colors.red),
              value: _promoSeulement,
              onChanged: (valeur) => setState(() => _promoSeulement = valeur),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _visible.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 335,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final v = _visible[index];
                return buildVehiculeCard(
                  v,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailVehiculeScreen(vehicule: v),
                    ),
                  ),
                  onReserver: () => reserver(context, v),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DetailVehiculeScreen extends StatefulWidget {
  final Vehicule vehicule;
  const DetailVehiculeScreen({super.key, required this.vehicule});

  @override
  State<DetailVehiculeScreen> createState() => _DetailVehiculeScreenState();
}

class _DetailVehiculeScreenState extends State<DetailVehiculeScreen> {
  int _nombreJours = 1;

  Widget _infoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: kPrimary),
      label: Text(text),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicule;
    final total = _nombreJours * v.prixApresReductionCalculated;

    return Scaffold(
      appBar: AppBar(title: Text("${v.marque} ${v.modele}")),
      body: ListView(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            color: const Color(0xFFF1EEF0),
            padding: const EdgeInsets.all(20),
            child: Image.network(
              v.photoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_car,
                size: 100,
                color: Colors.black38,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${v.marque} ${v.modele}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(v.ville, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _infoChip(Icons.local_gas_station, v.carburant),
                    _infoChip(Icons.settings, v.transmission),
                    _infoChip(Icons.confirmation_number, v.immatriculation),
                  ],
                ),
                const SizedBox(height: 16),
                if (v is VehiculePromo)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${fmt(v.prixApresReduction)} DT / jour",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${fmt(v.prixParJour)} DT",
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "-${v.reduction}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    "${fmt(v.prixParJour)} DT / jour",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: kPrimary,
                    ),
                  ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Nombre de jours",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: _nombreJours > 1
                              ? () => setState(() => _nombreJours--)
                              : null,
                          color: kPrimary,
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 30,
                          ),
                        ),
                        Text(
                          "$_nombreJours",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _nombreJours++),
                          color: kPrimary,
                          icon: const Icon(Icons.add_circle_outline, size: 30),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total à payer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${total.toStringAsFixed(2)} DT",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => reserver(context, v, jours: _nombreJours),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text("Réserver maintenant"),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text("Retour"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Vehicule {
  String marque;
  String modele;
  String immatriculation;
  String photoUrl;
  double prixParJour;
  String ville;
  String carburant;
  String transmission;

  Vehicule({
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.photoUrl,
    required this.prixParJour,
    required this.ville,
    required this.carburant,
    required this.transmission,
  });

  double get prixApresReductionCalculated => prixParJour;
}

class VehiculePromo extends Vehicule {
  int reduction;

  VehiculePromo({
    required super.marque,
    required super.modele,
    required super.immatriculation,
    required super.photoUrl,
    required super.prixParJour,
    required super.ville,
    required super.carburant,
    required super.transmission,
    required this.reduction,
  });

  double get prixApresReduction =>
      prixParJour - (prixParJour * reduction) / 100;

  @override
  double get prixApresReductionCalculated => prixApresReduction;
}

var listeVehicules = [
  Vehicule(
    marque: 'Dacia',
    modele: 'Logan',
    immatriculation: '177 TN 8390',
    photoUrl:
        'https://images.pexels.com/photos/19922984/pexels-photo-19922984.jpeg',
    prixParJour: 120,
    ville: 'Tunis',
    carburant: 'Diesel',
    transmission: 'Manuelle',
  ),
  Vehicule(
    marque: 'Kia',
    modele: 'Picanto',
    immatriculation: '196 TN 1231',
    photoUrl:
        'https://images.pexels.com/photos/20475125/pexels-photo-20475125.jpeg',
    prixParJour: 90,
    ville: 'Sousse',
    carburant: 'Essence',
    transmission: 'Manuelle',
  ),
  VehiculePromo(
    marque: 'Hyundai',
    modele: 'Tucson',
    immatriculation: '201 TN 7642',
    photoUrl:
        'https://images.pexels.com/photos/27629970/pexels-photo-27629970.jpeg',
    prixParJour: 200,
    ville: 'Tunis',
    carburant: 'Hybride',
    transmission: 'Automatique',
    reduction: 20,
  ),
  Vehicule(
    marque: 'Mercedes',
    modele: 'Classe C',
    immatriculation: '222 TN 7883',
    photoUrl:
        'https://images.pexels.com/photos/27019870/pexels-photo-27019870.jpeg',
    prixParJour: 350,
    ville: 'Hammamet',
    carburant: 'Diesel',
    transmission: 'Automatique',
  ),
  VehiculePromo(
    marque: 'Volkswagen',
    modele: 'Golf 8',
    immatriculation: '246 TN 2183',
    photoUrl:
        'https://images.pexels.com/photos/18517136/pexels-photo-18517136.jpeg',
    prixParJour: 180,
    ville: 'Sfax',
    carburant: 'Essence',
    transmission: 'Automatique',
    reduction: 15,
  ),
];
