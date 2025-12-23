package com.toolrent.mstools.controller;

import com.toolrent.mstools.entity.ToolEntity;
import com.toolrent.mstools.service.ToolService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/tools")
public class ToolController {

    @Autowired
    private ToolService toolService;

    /**
     * Obtener todas las herramientas
     * GET /api/v1/tools/
     */
    @GetMapping("/")
    public ResponseEntity<List<ToolEntity>> getAllTools() {
        return ResponseEntity.ok(toolService.getAllTools());
    }

    /**
     * Obtener herramienta por ID
     * GET /api/v1/tools/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ToolEntity> getToolById(@PathVariable Long id) {
        return ResponseEntity.ok(toolService.getToolById(id));
    }

    /**
     * RF1.1: Registrar nueva herramienta
     * POST /api/v1/tools/
     */
    @PostMapping("/")
    public ResponseEntity<ToolEntity> createTool(@RequestBody ToolEntity tool) {
        ToolEntity created = toolService.createTool(tool);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * Actualizar herramienta
     * PUT /api/v1/tools/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<ToolEntity> updateTool(
            @PathVariable Long id,
            @RequestBody ToolEntity toolDetails) {
        return ResponseEntity.ok(toolService.updateTool(id, toolDetails));
    }

    /**
     * RF1.2: Dar de baja herramienta
     * PUT /api/v1/tools/{id}/decommission
     */
    @PutMapping("/{id}/decommission")
    public ResponseEntity<ToolEntity> decommissionTool(@PathVariable Long id) {
        return ResponseEntity.ok(toolService.decommissionTool(id));
    }

    /**
     * Actualizar stock (para comunicación entre microservicios)
     * PUT /api/v1/tools/{id}/stock
     * Body: { "quantity": -1 } para restar o { "quantity": 1 } para sumar
     */
    @PutMapping("/{id}/stock")
    public ResponseEntity<ToolEntity> updateStock(
            @PathVariable Long id,
            @RequestBody Map<String, Integer> body) {
        Integer quantity = body.get("quantity");
        if (quantity == null) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(toolService.updateStock(id, quantity));
    }

    /**
     * Actualizar estado (para comunicación entre microservicios)
     * PUT /api/v1/tools/{id}/status
     * Body: { "status": "Disponible" }
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<ToolEntity> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String status = body.get("status");
        if (status == null || status.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(toolService.updateStatus(id, status));
    }

    /**
     * Obtener herramientas disponibles
     * GET /api/v1/tools/available
     */
    @GetMapping("/available")
    public ResponseEntity<List<ToolEntity>> getAvailableTools() {
        return ResponseEntity.ok(toolService.getAvailableTools());
    }

    /**
     * Eliminar herramienta (solo si está dada de baja)
     * DELETE /api/v1/tools/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTool(@PathVariable Long id) {
        toolService.deleteTool(id);
        return ResponseEntity.noContent().build();
    }
}
