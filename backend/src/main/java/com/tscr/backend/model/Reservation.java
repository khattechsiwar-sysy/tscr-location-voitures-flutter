package com.tscr.backend.model;

import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "reservations")
public class Reservation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "client_id")
    public Client client;

    public String vehiculeNom;
    public String immatriculation;
    public String ville;
    public double prixParJour;

    public LocalDate dateDebut;
    public LocalDate dateFin;
    public int nombreJours;
    public double prixEstime;

    public String numeroPermis;
    public LocalDate dateNaissance;
    public String adresse;

    public String statut = "EN_ATTENTE";
    public LocalDateTime dateCreation = LocalDateTime.now();

    public Reservation() {
    }
}