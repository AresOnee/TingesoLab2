package com.toolrent.msconfig.controller;

import com.toolrent.msconfig.entity.ConfigEntity;
import com.toolrent.msconfig.service.ConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/config")
public class ConfigController {

    @Autowired
    private ConfigService configService;

    /**
     * Obtener todas las configuraciones
     * GET /api/v1/config/
     */
    @GetMapping("/")
    public ResponseEntity<List<ConfigEntity>> getAllConfigs() {
        return ResponseEntity.ok(configService.getAllConfigs());
    }

    /**
     * Obtener configuración por ID
     * GET /api/v1/config/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ConfigEntity> getConfigById(@PathVariable Long id) {
        return ResponseEntity.ok(configService.getConfigById(id));
    }

    /**
     * RF4.1: Obtener tarifa de arriendo diaria
     * GET /api/v1/config/tarifa-arriendo
     */
    @GetMapping("/tarifa-arriendo")
    public ResponseEntity<Map<String, Double>> getTarifaArriendo() {
        Double tarifa = configService.getTarifaArriendoDiaria();
        return ResponseEntity.ok(Map.of("tarifaArriendoDiaria", tarifa));
    }

    /**
     * RF4.2: Obtener tarifa de multa diaria
     * GET /api/v1/config/tarifa-multa
     */
    @GetMapping("/tarifa-multa")
    public ResponseEntity<Map<String, Double>> getTarifaMulta() {
        Double tarifa = configService.getTarifaMultaDiaria();
        return ResponseEntity.ok(Map.of("tarifaMultaDiaria", tarifa));
    }

    /**
     * Obtener cargo por reparación
     * GET /api/v1/config/cargo-reparacion
     */
    @GetMapping("/cargo-reparacion")
    public ResponseEntity<Map<String, Double>> getCargoReparacion() {
        Double cargo = configService.getCargoReparacion();
        return ResponseEntity.ok(Map.of("cargoReparacion", cargo));
    }

    /**
     * Actualizar configuración por ID
     * PUT /api/v1/config/{id}
     * Body: { "value": 5000.0 }
     */
    @PutMapping("/{id}")
    public ResponseEntity<ConfigEntity> updateConfig(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Double newValue = Double.valueOf(body.get("value").toString());
        String username = body.getOrDefault("username", "admin").toString();
        return ResponseEntity.ok(configService.updateConfigById(id, newValue, username));
    }

    /**
     * RF4.1: Actualizar tarifa de arriendo
     * PUT /api/v1/config/tarifa-arriendo
     * Body: { "value": 5000.0 }
     */
    @PutMapping("/tarifa-arriendo")
    public ResponseEntity<ConfigEntity> updateTarifaArriendo(@RequestBody Map<String, Object> body) {
        Double newValue = Double.valueOf(body.get("value").toString());
        String username = body.getOrDefault("username", "admin").toString();
        return ResponseEntity.ok(configService.setTarifaArriendoDiaria(newValue, username));
    }

    /**
     * RF4.2: Actualizar tarifa de multa
     * PUT /api/v1/config/tarifa-multa
     * Body: { "value": 2000.0 }
     */
    @PutMapping("/tarifa-multa")
    public ResponseEntity<ConfigEntity> updateTarifaMulta(@RequestBody Map<String, Object> body) {
        Double newValue = Double.valueOf(body.get("value").toString());
        String username = body.getOrDefault("username", "admin").toString();
        return ResponseEntity.ok(configService.setTarifaMultaDiaria(newValue, username));
    }

    /**
     * Actualizar cargo por reparación
     * PUT /api/v1/config/cargo-reparacion
     * Body: { "value": 10000.0 }
     */
    @PutMapping("/cargo-reparacion")
    public ResponseEntity<ConfigEntity> updateCargoReparacion(@RequestBody Map<String, Object> body) {
        Double newValue = Double.valueOf(body.get("value").toString());
        String username = body.getOrDefault("username", "admin").toString();
        return ResponseEntity.ok(configService.setCargoReparacion(newValue, username));
    }
}
