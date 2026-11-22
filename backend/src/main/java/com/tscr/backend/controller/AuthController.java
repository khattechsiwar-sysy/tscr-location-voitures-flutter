package com.tscr.backend.controller;

import com.tscr.backend.model.Client;
import com.tscr.backend.repository.ClientRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final ClientRepository repo;
    private final PasswordEncoder encoder;

    public AuthController(ClientRepository repo, PasswordEncoder encoder) {
        this.repo = repo;
        this.encoder = encoder;
    }

    public record RegisterRequest(String nom, String prenom, String telephone,
            String email, String motDePasse) {
    }

    public record LoginRequest(String email, String motDePasse) {
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        if (isBlank(req.nom()) || isBlank(req.prenom()) || isBlank(req.telephone())
                || isBlank(req.email()) || isBlank(req.motDePasse())) {
            return error(HttpStatus.BAD_REQUEST, "Tous les champs sont obligatoires");
        }

        String email = req.email().trim().toLowerCase();
        if (repo.existsByEmail(email)) {
            return error(HttpStatus.CONFLICT, "Cet email est déjà utilisé");
        }

        Client c = new Client();
        c.setNom(req.nom().trim());
        c.setPrenom(req.prenom().trim());
        c.setTelephone(req.telephone().trim());
        c.setEmail(email);
        c.setMotDePasse(encoder.encode(req.motDePasse()));
        repo.save(c);

        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(c));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        if (isBlank(req.email()) || isBlank(req.motDePasse())) {
            return error(HttpStatus.BAD_REQUEST, "Email et mot de passe obligatoires");
        }

        return repo.findByEmail(req.email().trim().toLowerCase())
                .filter(c -> encoder.matches(req.motDePasse(), c.getMotDePasse()))
                .<ResponseEntity<?>>map(c -> ResponseEntity.ok(toDto(c)))
                .orElseGet(() -> error(HttpStatus.UNAUTHORIZED, "Email ou mot de passe incorrect"));
    }

    private Map<String, Object> toDto(Client c) {
        return Map.of(
                "id", c.getId(),
                "nom", c.getNom(),
                "prenom", c.getPrenom(),
                "email", c.getEmail(),
                "role", c.getRole());
    }

    private ResponseEntity<Map<String, String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("message", message));
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}