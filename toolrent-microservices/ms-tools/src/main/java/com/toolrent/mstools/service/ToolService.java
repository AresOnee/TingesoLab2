package com.toolrent.mstools.service;

import com.toolrent.mstools.entity.ToolEntity;
import com.toolrent.mstools.repository.ToolRepository;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@Transactional
public class ToolService {

    private static final Logger log = LoggerFactory.getLogger(ToolService.class);

    @Autowired
    private ToolRepository toolRepository;

    @Autowired
    private RestTemplate restTemplate;

    // URL de ms-kardex (usando nombre de Eureka)
    private static final String MS_KARDEX_URL = "http://ms-kardex";

    /**
     * Obtener todas las herramientas
     */
    public List<ToolEntity> getAllTools() {
        return toolRepository.findAll();
    }

    /**
     * Obtener herramienta por ID
     */
    public ToolEntity getToolById(Long id) {
        return toolRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        String.format("Herramienta con ID %d no encontrada", id)));
    }

    /**
     * RF1.1: Registrar nuevas herramientas
     * RF5.1: Registrar automáticamente en kardex
     */
    public ToolEntity createTool(ToolEntity tool, String username) {
        String name = Optional.ofNullable(tool.getName()).orElse("").trim();
        if (name.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El nombre es obligatorio");
        }

        if (toolRepository.existsByNameIgnoreCase(name)) {
            throw new DataIntegrityViolationException("Ya existe una herramienta con ese nombre");
        }

        tool.setName(name);
        if (tool.getStatus() == null || tool.getStatus().isBlank()) {
            tool.setStatus("Disponible");
        }

        // Guardar herramienta
        ToolEntity saved = toolRepository.save(tool);
        log.info("Herramienta creada: {} con ID: {}", saved.getName(), saved.getId());

        // RF5.1: Registrar movimiento en kardex
        registerKardexMovement(
                saved.getId(),
                saved.getName(),
                "REGISTRO",
                saved.getStock(),
                username,
                "Alta de herramienta: " + saved.getName(),
                null
        );

        return saved;
    }

    /**
     * Actualizar herramienta
     */
    public ToolEntity updateTool(Long id, ToolEntity toolDetails) {
        ToolEntity tool = getToolById(id);

        if (toolDetails.getName() != null && !toolDetails.getName().isBlank()) {
            // Verificar nombre duplicado si se está cambiando
            if (!tool.getName().equalsIgnoreCase(toolDetails.getName()) &&
                    toolRepository.existsByNameIgnoreCase(toolDetails.getName())) {
                throw new DataIntegrityViolationException("Ya existe una herramienta con ese nombre");
            }
            tool.setName(toolDetails.getName().trim());
        }

        if (toolDetails.getCategory() != null) {
            tool.setCategory(toolDetails.getCategory());
        }

        if (toolDetails.getStatus() != null) {
            tool.setStatus(toolDetails.getStatus());
        }

        if (toolDetails.getReplacementValue() > 0) {
            tool.setReplacementValue(toolDetails.getReplacementValue());
        }

        if (toolDetails.getStock() >= 0) {
            tool.setStock(toolDetails.getStock());
        }

        return toolRepository.save(tool);
    }

    /**
     * RF1.2: Dar de baja herramientas dañadas o en desuso
     * RF5.1: Registrar automáticamente en kardex
     */
    public ToolEntity decommissionTool(Long id, String username) {
        ToolEntity tool = getToolById(id);

        if ("Baja".equalsIgnoreCase(tool.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La herramienta ya está dada de baja");
        }

        if ("Prestada".equalsIgnoreCase(tool.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "No se puede dar de baja una herramienta que está prestada");
        }

        // Guardar stock anterior para el kardex
        int stockAnterior = tool.getStock();

        // Dar de baja
        tool.setStatus("Baja");
        tool.setStock(0);
        ToolEntity saved = toolRepository.save(tool);
        log.info("Herramienta dada de baja: {} con ID: {}", saved.getName(), saved.getId());

        // RF5.1: Registrar baja en kardex
        registerKardexMovement(
                saved.getId(),
                saved.getName(),
                "BAJA",
                -stockAnterior,
                username,
                "Baja de herramienta: " + saved.getName(),
                null
        );

        return saved;
    }

    /**
     * Actualizar stock de una herramienta
     */
    public ToolEntity updateStock(Long id, int quantity) {
        ToolEntity tool = getToolById(id);

        int newStock = tool.getStock() + quantity;
        if (newStock < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El stock no puede ser negativo");
        }

        tool.setStock(newStock);

        // Actualizar estado según stock
        if (newStock == 0 && !"Baja".equalsIgnoreCase(tool.getStatus())) {
            tool.setStatus("Prestada");
        } else if (newStock > 0 && "Prestada".equalsIgnoreCase(tool.getStatus())) {
            tool.setStatus("Disponible");
        }

        return toolRepository.save(tool);
    }

    /**
     * Actualizar estado de una herramienta
     */
    public ToolEntity updateStatus(Long id, String newStatus) {
        ToolEntity tool = getToolById(id);
        tool.setStatus(newStatus);
        return toolRepository.save(tool);
    }

    /**
     * Obtener herramientas disponibles (stock > 0 y estado Disponible)
     */
    public List<ToolEntity> getAvailableTools() {
        return toolRepository.findByStockGreaterThan(0).stream()
                .filter(t -> "Disponible".equalsIgnoreCase(t.getStatus()))
                .toList();
    }

    /**
     * Eliminar herramienta (solo si está en estado Baja)
     */
    public void deleteTool(Long id) {
        ToolEntity tool = getToolById(id);

        if (!"Baja".equalsIgnoreCase(tool.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Solo se pueden eliminar herramientas dadas de baja");
        }

        toolRepository.delete(tool);
    }

    // ==================== COMUNICACIÓN CON MS-KARDEX ====================

    /**
     * Registrar movimiento en el kardex vía HTTP
     */
    private void registerKardexMovement(Long toolId, String toolName, String type, int quantity,
                                        String username, String observations, Long loanId) {
        try {
            String url = MS_KARDEX_URL + "/api/v1/kardex";
            Map<String, Object> body = new HashMap<>();
            body.put("toolId", toolId);
            body.put("toolName", toolName);
            body.put("movementType", type);
            body.put("quantity", quantity);
            body.put("username", username != null ? username : "system");
            body.put("observations", observations);
            body.put("loanId", loanId);
            restTemplate.postForObject(url, body, Object.class);
            log.info("Movimiento de kardex registrado: {} para herramienta {}", type, toolName);
        } catch (Exception e) {
            log.error("Error al registrar movimiento en kardex: {}", e.getMessage());
            // No lanzamos excepción para no afectar la operación principal
        }
    }
}
