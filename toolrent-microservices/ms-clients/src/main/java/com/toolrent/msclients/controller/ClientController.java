package com.toolrent.msclients.controller;

import com.toolrent.msclients.entity.ClientEntity;
import com.toolrent.msclients.service.ClientService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/clients")
public class ClientController {

    @Autowired
    private ClientService clientService;

    /**
     * Obtener todos los clientes
     * GET /api/v1/clients/
     */
    @GetMapping("/")
    public ResponseEntity<List<ClientEntity>> getAllClients() {
        return ResponseEntity.ok(clientService.getAllClients());
    }

    /**
     * Obtener cliente por ID
     * GET /api/v1/clients/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ClientEntity> getClientById(@PathVariable Long id) {
        return ResponseEntity.ok(clientService.getClientById(id));
    }

    /**
     * Obtener cliente por RUT
     * GET /api/v1/clients/rut/{rut}
     */
    @GetMapping("/rut/{rut}")
    public ResponseEntity<ClientEntity> getClientByRut(@PathVariable String rut) {
        return ResponseEntity.ok(clientService.getClientByRut(rut));
    }

    /**
     * RF3.1: Crear nuevo cliente
     * POST /api/v1/clients/
     */
    @PostMapping("/")
    public ResponseEntity<ClientEntity> createClient(@RequestBody ClientEntity client) {
        ClientEntity created = clientService.createClient(client);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * Actualizar cliente
     * PUT /api/v1/clients/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<ClientEntity> updateClient(
            @PathVariable Long id,
            @RequestBody ClientEntity clientDetails) {
        return ResponseEntity.ok(clientService.updateClient(id, clientDetails));
    }

    /**
     * RF3.2: Actualizar estado del cliente
     * PUT /api/v1/clients/{id}/state
     * Body: { "state": "Activo" } o { "state": "Restringido" }
     */
    @PutMapping("/{id}/state")
    public ResponseEntity<ClientEntity> updateState(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String newState = body.get("state");
        if (newState == null || newState.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(clientService.updateState(id, newState));
    }

    /**
     * Obtener clientes por estado
     * GET /api/v1/clients/state/{state}
     */
    @GetMapping("/state/{state}")
    public ResponseEntity<List<ClientEntity>> getClientsByState(@PathVariable String state) {
        return ResponseEntity.ok(clientService.getClientsByState(state));
    }

    /**
     * Verificar si un cliente puede realizar préstamos
     * GET /api/v1/clients/{id}/can-borrow
     */
    @GetMapping("/{id}/can-borrow")
    public ResponseEntity<Map<String, Boolean>> canClientBorrow(@PathVariable Long id) {
        boolean canBorrow = clientService.canClientBorrow(id);
        return ResponseEntity.ok(Map.of("canBorrow", canBorrow));
    }

    /**
     * Eliminar cliente
     * DELETE /api/v1/clients/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteClient(@PathVariable Long id) {
        clientService.deleteClient(id);
        return ResponseEntity.noContent().build();
    }
}
