package com.tscr.backend.repository;

import com.tscr.backend.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByClient_IdOrderByDateEnvoiDesc(Long clientId);

    void deleteByReservation_Id(Long reservationId);
}
