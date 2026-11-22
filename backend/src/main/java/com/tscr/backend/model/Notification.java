package com.tscr.backend.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "client_id")
    public Client client;

    @ManyToOne
    @JoinColumn(name = "reservation_id")
    public Reservation reservation;

    public String titre;

    @Column(length = 500)
    public String message;

    public LocalDateTime dateEnvoi = LocalDateTime.now();
    public boolean estLue = false;

    public Notification() {
    }
}