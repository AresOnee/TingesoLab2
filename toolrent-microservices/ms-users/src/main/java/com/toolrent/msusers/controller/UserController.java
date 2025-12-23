package com.toolrent.msusers.controller;

import com.toolrent.msusers.entity.UserEntity;
import com.toolrent.msusers.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    @Autowired
    private UserService userService;

    /**
     * Obtener todos los usuarios
     * GET /api/v1/users/
     */
    @GetMapping("/")
    public ResponseEntity<List<UserEntity>> getAllUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    /**
     * Obtener usuario por ID
     * GET /api/v1/users/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<UserEntity> getUserById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    /**
     * Obtener usuario por username
     * GET /api/v1/users/username/{username}
     */
    @GetMapping("/username/{username}")
    public ResponseEntity<UserEntity> getUserByUsername(@PathVariable String username) {
        return ResponseEntity.ok(userService.getUserByUsername(username));
    }

    /**
     * Crear usuario
     * POST /api/v1/users/
     */
    @PostMapping("/")
    public ResponseEntity<UserEntity> createUser(@RequestBody UserEntity user) {
        UserEntity created = userService.createUser(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * Actualizar usuario
     * PUT /api/v1/users/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<UserEntity> updateUser(
            @PathVariable Long id,
            @RequestBody UserEntity userDetails) {
        return ResponseEntity.ok(userService.updateUser(id, userDetails));
    }

    /**
     * Registrar login
     * POST /api/v1/users/login
     */
    @PostMapping("/login")
    public ResponseEntity<UserEntity> registerLogin(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        return ResponseEntity.ok(userService.registerLogin(username));
    }

    /**
     * Obtener usuarios por rol
     * GET /api/v1/users/role/{role}
     */
    @GetMapping("/role/{role}")
    public ResponseEntity<List<UserEntity>> getUsersByRole(@PathVariable String role) {
        return ResponseEntity.ok(userService.getUsersByRole(role));
    }

    /**
     * Desactivar usuario
     * PUT /api/v1/users/{id}/deactivate
     */
    @PutMapping("/{id}/deactivate")
    public ResponseEntity<UserEntity> deactivateUser(@PathVariable Long id) {
        return ResponseEntity.ok(userService.deactivateUser(id));
    }

    /**
     * Activar usuario
     * PUT /api/v1/users/{id}/activate
     */
    @PutMapping("/{id}/activate")
    public ResponseEntity<UserEntity> activateUser(@PathVariable Long id) {
        return ResponseEntity.ok(userService.activateUser(id));
    }
}
