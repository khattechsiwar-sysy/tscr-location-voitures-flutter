package com.tscr.backend.controller;

import com.tscr.backend.model.Client;
import com.tscr.backend.model.Notification;
import com.tscr.backend.model.Reservation;
import com.tscr.backend.repository.ClientRepository;
import com.tscr.backend.repository.NotificationRepository;
import com.tscr.backend.repository.ReservationRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ReservationController {

    private final ReservationRepository reservations;
    private final NotificationRepository notifications;
    private final ClientRepository clients;

    public ReservationController(ReservationRepository reservations,
            NotificationRepository notifications,
            ClientRepository clients) {
        this.reservations = reservations;
        this.notifications = notifications;
        this.clients = clients;
    }

    public record ReservationRequest(Long clientId, String vehiculeNom, String immatriculation,
            String ville, Double prixParJour, String dateDebut,
            String dateFin, String numeroPermis, String dateNaissance,
            String adresse) {
    }

    public record ReservationUpdate(String ville, String adresse, String numeroPermis,
            String dateDebut, String dateFin) {
    }

    @PostMapping("/reservations")
    public ResponseEntity<?> creer(@RequestBody ReservationRequest req) {
        if (req.clientId() == null)
            return error(HttpStatus.BAD_REQUEST, "Client manquant");
        Client client = clients.findById(req.clientId()).orElse(null);
        if (client == null)
            return error(HttpStatus.UNAUTHORIZED, "Client introuvable");

        if (isBlank(req.numeroPermis()) || isBlank(req.adresse()) || isBlank(req.vehiculeNom())
                || req.prixParJour() == null) {
            return error(HttpStatus.BAD_REQUEST, "Tous les champs sont obligatoires");
        }

        LocalDate debut, fin, naissance;
        try {
            debut = LocalDate.parse(req.dateDebut());
            fin = LocalDate.parse(req.dateFin());
            naissance = LocalDate.parse(req.dateNaissance());
        } catch (DateTimeParseException | NullPointerException e) {
            return error(HttpStatus.BAD_REQUEST, "Dates invalides");
        }

        if (debut.isBefore(LocalDate.now())) {
            return error(HttpStatus.BAD_REQUEST, "La date de début est déjà passée");
        }
        if (fin.isBefore(debut)) {
            return error(HttpStatus.BAD_REQUEST, "La date de fin doit être après la date de début");
        }
        if (Period.between(naissance, LocalDate.now()).getYears() < 18) {
            return error(HttpStatus.BAD_REQUEST, "Vous devez avoir au moins 18 ans");
        }

        int jours = (int) Math.max(1, ChronoUnit.DAYS.between(debut, fin));

        Reservation r = new Reservation();
        r.client = client;
        r.vehiculeNom = req.vehiculeNom().trim();
        r.immatriculation = req.immatriculation();
        r.ville = req.ville();
        r.prixParJour = req.prixParJour();
        r.dateDebut = debut;
        r.dateFin = fin;
        r.nombreJours = jours;
        r.prixEstime = jours * req.prixParJour();
        r.numeroPermis = req.numeroPermis().trim();
        r.dateNaissance = naissance;
        r.adresse = req.adresse().trim();
        reservations.save(r);

        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(r));
    }

    @PutMapping("/reservations/{id}")
    public ResponseEntity<?> modifier(@PathVariable Long id, @RequestBody ReservationUpdate req) {
        Reservation r = reservations.findById(id).orElse(null);
        if (r == null)
            return error(HttpStatus.NOT_FOUND, "Réservation introuvable");
        if (!"EN_ATTENTE".equals(r.statut))
            return error(HttpStatus.CONFLICT, "Réservation déjà traitée, modification impossible");

        if (isBlank(req.ville()) || isBlank(req.adresse()) || isBlank(req.numeroPermis()))
            return error(HttpStatus.BAD_REQUEST, "Tous les champs sont obligatoires");

        LocalDate debut, fin;
        try {
            debut = LocalDate.parse(req.dateDebut());
            fin = LocalDate.parse(req.dateFin());
        } catch (DateTimeParseException | NullPointerException e) {
            return error(HttpStatus.BAD_REQUEST, "Dates invalides");
        }
        if (debut.isBefore(LocalDate.now()))
            return error(HttpStatus.BAD_REQUEST, "La date de début est déjà passée");
        if (!fin.isAfter(debut))
            return error(HttpStatus.BAD_REQUEST, "La date de fin doit être après la date de début");

        int jours = (int) ChronoUnit.DAYS.between(debut, fin);
        r.ville = req.ville().trim();
        r.adresse = req.adresse().trim();
        r.numeroPermis = req.numeroPermis().trim();
        r.dateDebut = debut;
        r.dateFin = fin;
        r.nombreJours = jours;
        r.prixEstime = jours * r.prixParJour;
        reservations.save(r);
        return ResponseEntity.ok(toDto(r));
    }

    @DeleteMapping("/reservations/{id}")
    @Transactional
    public ResponseEntity<?> supprimer(@PathVariable Long id) {
        Reservation r = reservations.findById(id).orElse(null);
        if (r == null)
            return error(HttpStatus.NOT_FOUND, "Réservation introuvable");
        if (!"EN_ATTENTE".equals(r.statut))
            return error(HttpStatus.CONFLICT, "Réservation déjà traitée, suppression impossible");
        notifications.deleteByReservation_Id(id);
        reservations.delete(r);
        return ResponseEntity.ok(Map.of("ok", true));
    }

    @GetMapping("/reservations/client/{clientId}")
    public List<Map<String, Object>> duClient(@PathVariable Long clientId) {
        return reservations.findByClient_IdOrderByDateCreationDesc(clientId)
                .stream().map(this::toDto).toList();
    }

    @GetMapping("/reservations")
    public List<Map<String, Object>> toutes() {
        return reservations.findAllByOrderByDateCreationDesc()
                .stream().map(this::toDto).toList();
    }

    @PutMapping("/reservations/{id}/accepter")
    public ResponseEntity<?> accepter(@PathVariable Long id) {
        return changerStatut(id, true);
    }

    @PutMapping("/reservations/{id}/refuser")
    public ResponseEntity<?> refuser(@PathVariable Long id) {
        return changerStatut(id, false);
    }

    private ResponseEntity<?> changerStatut(Long id, boolean accepte) {
        Reservation r = reservations.findById(id).orElse(null);
        if (r == null)
            return error(HttpStatus.NOT_FOUND, "Réservation introuvable");
        if (!"EN_ATTENTE".equals(r.statut)) {
            return error(HttpStatus.CONFLICT, "Cette réservation a déjà été traitée");
        }

        r.statut = accepte ? "ACCEPTEE" : "REFUSEE";
        reservations.save(r);

        Notification n = new Notification();
        n.client = r.client;
        n.reservation = r;
        n.titre = accepte ? "Réservation acceptée" : "Réservation refusée";
        n.message = "Votre réservation du véhicule " + r.vehiculeNom
                + " (du " + r.dateDebut + " au " + r.dateFin + ") a été "
                + (accepte ? "acceptée" : "refusée") + " par l'agence.";
        n.dateEnvoi = LocalDateTime.now();
        n.estLue = false;
        notifications.save(n);

        return ResponseEntity.ok(toDto(r));
    }

    @GetMapping("/notifications/client/{clientId}")
    public List<Map<String, Object>> notificationsClient(@PathVariable Long clientId) {
        return notifications.findByClient_IdOrderByDateEnvoiDesc(clientId).stream().map(n -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", n.id);
            m.put("titre", n.titre);
            m.put("message", n.message);
            m.put("dateEnvoi", n.dateEnvoi.toString());
            m.put("estLue", n.estLue);
            return m;
        }).toList();
    }

    @PutMapping("/notifications/{id}/lue")
    public ResponseEntity<?> marquerLue(@PathVariable Long id) {
        Notification n = notifications.findById(id).orElse(null);
        if (n == null)
            return error(HttpStatus.NOT_FOUND, "Notification introuvable");
        n.estLue = true;
        notifications.save(n);
        return ResponseEntity.ok(Map.of("ok", true));
    }

    private Map<String, Object> toDto(Reservation r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.id);
        m.put("clientId", r.client.getId());
        m.put("clientNom", r.client.getPrenom() + " " + r.client.getNom());
        m.put("clientTelephone", r.client.getTelephone());
        m.put("clientEmail", r.client.getEmail());
        m.put("vehiculeNom", r.vehiculeNom);
        m.put("immatriculation", r.immatriculation);
        m.put("ville", r.ville);
        m.put("prixParJour", r.prixParJour);
        m.put("dateDebut", r.dateDebut.toString());
        m.put("dateFin", r.dateFin.toString());
        m.put("nombreJours", r.nombreJours);
        m.put("prixEstime", r.prixEstime);
        m.put("numeroPermis", r.numeroPermis);
        m.put("dateNaissance", r.dateNaissance.toString());
        m.put("adresse", r.adresse);
        m.put("statut", r.statut);
        m.put("dateCreation", r.dateCreation.toString());
        return m;
    }

    private ResponseEntity<Map<String, String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("message", message));
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}