package com.toolrent.mskardex.controller;

import com.toolrent.mskardex.entity.KardexEntity;
import com.toolrent.mskardex.service.KardexService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/kardex")
public class KardexController {

    @Autowired
    private KardexService kardexService;

    /**
     * Obtener todos los movimientos
     * GET /api/v1/kardex/
     */
    @GetMapping("/")
    public ResponseEntity<List<KardexEntity>> getAllMovements() {
        return ResponseEntity.ok(kardexService.getAllMovements());
    }

    /**
     * RF5.1: Registrar movimiento en kardex
     * POST /api/v1/kardex/
     */
    @PostMapping("/")
    public ResponseEntity<KardexEntity> registerMovement(@RequestBody Map<String, Object> body) {
        Long toolId = Long.valueOf(body.get("toolId").toString());
        String toolName = body.getOrDefault("toolName", "").toString();
        String movementType = body.get("movementType").toString();
        Integer quantity = Integer.valueOf(body.get("quantity").toString());
        String username = body.getOrDefault("username", "system").toString();
        String observations = body.getOrDefault("observations", "").toString();
        Long loanId = body.get("loanId") != null ? Long.valueOf(body.get("loanId").toString()) : null;

        KardexEntity kardex = kardexService.registerMovement(
                toolId, toolName, movementType, quantity, username, observations, loanId
        );

        return ResponseEntity.status(HttpStatus.CREATED).body(kardex);
    }

    /**
     * RF5.2: Consultar historial de movimientos por herramienta
     * GET /api/v1/kardex/tool/{toolId}
     */
    @GetMapping("/tool/{toolId}")
    public ResponseEntity<List<KardexEntity>> getMovementsByTool(@PathVariable Long toolId) {
        return ResponseEntity.ok(kardexService.getMovementsByTool(toolId));
    }

    /**
     * RF5.3: Generar listado de movimientos por rango de fechas
     * GET /api/v1/kardex/date-range?startDate=2025-01-01&endDate=2025-12-31
     */
    @GetMapping("/date-range")
    public ResponseEntity<List<KardexEntity>> getMovementsByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        LocalDateTime start = startDate.atStartOfDay();
        LocalDateTime end = endDate.atTime(LocalTime.MAX);

        return ResponseEntity.ok(kardexService.getMovementsByDateRange(start, end));
    }

    /**
     * Obtener movimientos por tipo
     * GET /api/v1/kardex/type/{movementType}
     */
    @GetMapping("/type/{movementType}")
    public ResponseEntity<List<KardexEntity>> getMovementsByType(@PathVariable String movementType) {
        return ResponseEntity.ok(kardexService.getMovementsByType(movementType));
    }

    /**
     * Obtener movimientos por préstamo
     * GET /api/v1/kardex/loan/{loanId}
     */
    @GetMapping("/loan/{loanId}")
    public ResponseEntity<List<KardexEntity>> getMovementsByLoan(@PathVariable Long loanId) {
        return ResponseEntity.ok(kardexService.getMovementsByLoan(loanId));
    }
}
