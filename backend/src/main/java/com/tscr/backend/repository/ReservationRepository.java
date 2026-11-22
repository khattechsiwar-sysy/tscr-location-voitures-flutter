package com.tscr.backend.repository;

import com.tscr.backend.model.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReservationRepository extends JpaRepository<Reservation, Long> {
    List<Reservation> findByClient_IdOrderByDateCreationDesc(Long clientId);

    List<Reservation> findAllByOrderByDateCreationDesc();
}