package com.toolrent.msloans.service;

import com.toolrent.msloans.dto.ClientDTO;
import com.toolrent.msloans.dto.ToolDTO;
import com.toolrent.msloans.entity.LoanEntity;
import com.toolrent.msloans.repository.LoanRepository;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Transactional
public class LoanService {

    private static final Logger log = LoggerFactory.getLogger(LoanService.class);

    @Autowired
    private LoanRepository loanRepository;

    @Autowired
    private RestTemplate restTemplate;

    // URLs de microservicios (usando nombres de Eureka)
    private static final String MS_TOOLS_URL = "http://ms-tools";
    private static final String MS_CLIENTS_URL = "http://ms-clients";
    private static final String MS_CONFIG_URL = "http://ms-config";
    private static final String MS_KARDEX_URL = "http://ms-kardex";

    /**
     * Obtener todos los préstamos
     * Calcula dinámicamente el status ATRASADO para préstamos activos vencidos
     */
    public List<LoanEntity> getAllLoans() {
        List<LoanEntity> loans = loanRepository.findAll();

        // Calcular status y multas dinámicamente para préstamos activos
        LocalDate today = LocalDate.now();
        Double tarifaMulta = getTarifaMulta();

        for (LoanEntity loan : loans) {
            // Solo procesar préstamos activos (sin fecha de devolución)
            if (loan.getReturnDate() == null) {
                if (today.isAfter(loan.getDueDate())) {
                    long diasAtraso = ChronoUnit.DAYS.between(loan.getDueDate(), today);
                    loan.setFine(diasAtraso * tarifaMulta);
                    loan.setStatus("ATRASADO");
                } else {
                    loan.setStatus("ACTIVO");
                }
            }
        }

        return loans;
    }

    /**
     * Obtener préstamo por ID
     */
    public LoanEntity getLoanById(Long id) {
        return loanRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        String.format("Préstamo con ID %d no encontrado", id)));
    }

    /**
     * RF2.1: Crear préstamo aplicando reglas de negocio
     */
    public LoanEntity createLoan(Long clientId, Long toolId, LocalDate dueDate, String username) {
        log.info("Creando préstamo - Cliente: {}, Herramienta: {}, Vencimiento: {}", clientId, toolId, dueDate);

        // 1. Obtener datos del cliente desde ms-clients
        ClientDTO client = getClient(clientId);
        log.info("Cliente obtenido: {} - Estado: {}", client.getName(), client.getState());

        // 2. Validar estado del cliente
        if (!"Activo".equalsIgnoreCase(client.getState())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    String.format("El cliente '%s' está en estado '%s'. Solo clientes Activos pueden arrendar.",
                            client.getName(), client.getState()));
        }

        // 2.1 Validar límite de 5 préstamos activos por cliente
        long activeLoanCount = loanRepository.countActiveByClientId(clientId);
        if (activeLoanCount >= 5) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    String.format("El cliente '%s' ya tiene %d préstamos activos. El máximo permitido es 5.",
                            client.getName(), activeLoanCount));
        }
        log.info("Cliente {} tiene {} préstamos activos", client.getName(), activeLoanCount);

        // 3. Obtener datos de la herramienta desde ms-tools
        ToolDTO tool = getTool(toolId);
        log.info("Herramienta obtenida: {} - Stock: {} - Estado: {}", tool.getName(), tool.getStock(), tool.getStatus());

        // 4. Validar disponibilidad de herramienta
        // Contar préstamos activos de esta herramienta para calcular disponibilidad real
        long activeLoansForTool = loanRepository.countActiveByToolId(toolId);
        int availableUnits = tool.getStock() - (int) activeLoansForTool;

        log.info("Herramienta {} - Stock total: {}, Prestadas: {}, Disponibles: {}",
                tool.getName(), tool.getStock(), activeLoansForTool, availableUnits);

        if (availableUnits <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    String.format("La herramienta '%s' no tiene unidades disponibles (Stock: %d, Prestadas: %d)",
                            tool.getName(), tool.getStock(), activeLoansForTool));
        }

        if ("Baja".equalsIgnoreCase(tool.getStatus()) || "En Reparación".equalsIgnoreCase(tool.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    String.format("La herramienta '%s' no está disponible (Estado: %s)", tool.getName(), tool.getStatus()));
        }

        // 5. Validar que el cliente no tenga ya esta herramienta prestada
        if (loanRepository.existsActiveByClientAndTool(clientId, toolId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    String.format("El cliente '%s' ya tiene un préstamo activo de '%s'", client.getName(), tool.getName()));
        }

        // 6. Obtener tarifa de arriendo desde ms-config
        Double tarifaArriendo = getTarifaArriendo();
        log.info("Tarifa de arriendo obtenida: {}", tarifaArriendo);

        // 7. Calcular costo del arriendo
        LocalDate today = LocalDate.now();
        long dias = ChronoUnit.DAYS.between(today, dueDate);
        if (dias <= 0) dias = 1;
        Double rentalCost = dias * tarifaArriendo;

        // 8. Crear el préstamo
        LoanEntity loan = new LoanEntity();
        loan.setClientId(clientId);
        loan.setToolId(toolId);
        loan.setClientName(client.getName());
        loan.setToolName(tool.getName());
        loan.setStartDate(today);
        loan.setDueDate(dueDate);
        loan.setStatus("ACTIVO");
        loan.setFine(0.0);
        loan.setRentalCost(rentalCost);
        loan.setDamaged(false);
        loan.setIrreparable(false);

        LoanEntity saved = loanRepository.save(loan);
        log.info("Préstamo creado con ID: {}", saved.getId());

        // 9. Registrar movimiento en kardex (NO modificamos stock, se calcula dinámicamente)
        registerKardexMovement(toolId, tool.getName(), "PRESTAMO", -1, username,
                String.format("Préstamo a %s", client.getName()), saved.getId());
        log.info("Movimiento de kardex registrado para préstamo");

        return saved;
    }

    /**
     * RF2.3: Registrar devolución
     */
    public LoanEntity returnTool(Long loanId, boolean isDamaged, boolean isIrreparable, String username) {
        log.info("Procesando devolución - Préstamo: {}, Dañado: {}, Irreparable: {}", loanId, isDamaged, isIrreparable);

        LoanEntity loan = getLoanById(loanId);

        if ("CERRADO".equalsIgnoreCase(loan.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Este préstamo ya fue cerrado");
        }

        LocalDate today = LocalDate.now();
        loan.setReturnDate(today);
        loan.setDamaged(isDamaged);
        loan.setIrreparable(isIrreparable);

        // Calcular multa por atraso
        Double multa = 0.0;
        if (today.isAfter(loan.getDueDate())) {
            long diasAtraso = ChronoUnit.DAYS.between(loan.getDueDate(), today);
            Double tarifaMulta = getTarifaMulta();
            multa = diasAtraso * tarifaMulta;
            log.info("Días de atraso: {}, Multa por atraso: {}", diasAtraso, multa);
        }

        // Agregar cargo por daño
        if (isDamaged) {
            ToolDTO tool = getTool(loan.getToolId());
            if (isIrreparable) {
                // Daño irreparable: cobrar valor de reposición
                multa += tool.getReplacementValue();
                log.info("Daño irreparable - Cargo reposición: {}", tool.getReplacementValue());
            } else {
                // Daño reparable: cobrar cargo de reparación
                Double cargoReparacion = getCargoReparacion();
                multa += cargoReparacion;
                log.info("Daño reparable - Cargo reparación: {}", cargoReparacion);
            }
        }

        loan.setFine(multa);
        loan.setStatus("CERRADO");

        LoanEntity saved = loanRepository.save(loan);

        // Actualizar herramienta según daño
        if (isDamaged && isIrreparable) {
            // Dar de baja la herramienta
            updateToolStatus(loan.getToolId(), "Baja");
            registerKardexMovement(loan.getToolId(), loan.getToolName(), "BAJA", 0, username,
                    "Baja por daño irreparable en préstamo #" + loanId, loanId);
        } else if (isDamaged) {
            // Enviar a reparación
            updateToolStatus(loan.getToolId(), "En Reparación");
            registerKardexMovement(loan.getToolId(), loan.getToolName(), "REPARACION", 0, username,
                    "Enviada a reparación por daño en préstamo #" + loanId, loanId);
        } else {
            // Devolución normal: solo registrar en kardex (stock se calcula dinámicamente)
            registerKardexMovement(loan.getToolId(), loan.getToolName(), "DEVOLUCION", 1, username,
                    "Devolución normal", loanId);
        }

        // Actualizar estado del cliente si tiene atrasos
        updateClientStateIfNeeded(loan.getClientId());

        return saved;
    }

    /**
     * Obtener préstamos activos
     */
    public List<LoanEntity> getActiveLoans() {
        List<LoanEntity> loans = loanRepository.findActiveLoans();

        // Calcular multas dinámicamente
        LocalDate today = LocalDate.now();
        Double tarifaMulta = getTarifaMulta();

        for (LoanEntity loan : loans) {
            if (today.isAfter(loan.getDueDate())) {
                long diasAtraso = ChronoUnit.DAYS.between(loan.getDueDate(), today);
                loan.setFine(diasAtraso * tarifaMulta);
                loan.setStatus("ATRASADO");
            } else {
                loan.setStatus("ACTIVO");
            }
        }

        return loans;
    }

    /**
     * Obtener préstamos de un cliente
     */
    public List<LoanEntity> getLoansByClient(Long clientId) {
        return loanRepository.findByClientIdOrderByStartDateDesc(clientId);
    }

    // ==================== COMUNICACIÓN CON MICROSERVICIOS ====================

    private ClientDTO getClient(Long clientId) {
        try {
            String url = MS_CLIENTS_URL + "/api/v1/clients/" + clientId;
            return restTemplate.getForObject(url, ClientDTO.class);
        } catch (Exception e) {
            log.error("Error al obtener cliente {}: {}", clientId, e.getMessage());
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "No se pudo conectar con el servicio de clientes");
        }
    }

    private ToolDTO getTool(Long toolId) {
        try {
            String url = MS_TOOLS_URL + "/api/v1/tools/" + toolId;
            return restTemplate.getForObject(url, ToolDTO.class);
        } catch (Exception e) {
            log.error("Error al obtener herramienta {}: {}", toolId, e.getMessage());
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "No se pudo conectar con el servicio de herramientas");
        }
    }

    @SuppressWarnings("unchecked")
    private Double getTarifaArriendo() {
        try {
            String url = MS_CONFIG_URL + "/api/v1/config/tarifa-arriendo";
            Map<String, Double> response = restTemplate.getForObject(url, Map.class);
            return response != null ? ((Number) response.get("tarifaArriendoDiaria")).doubleValue() : 5000.0;
        } catch (Exception e) {
            log.warn("Error al obtener tarifa de arriendo, usando default: {}", e.getMessage());
            return 5000.0;
        }
    }

    @SuppressWarnings("unchecked")
    private Double getTarifaMulta() {
        try {
            String url = MS_CONFIG_URL + "/api/v1/config/tarifa-multa";
            Map<String, Double> response = restTemplate.getForObject(url, Map.class);
            return response != null ? ((Number) response.get("tarifaMultaDiaria")).doubleValue() : 2000.0;
        } catch (Exception e) {
            log.warn("Error al obtener tarifa de multa, usando default: {}", e.getMessage());
            return 2000.0;
        }
    }

    @SuppressWarnings("unchecked")
    private Double getCargoReparacion() {
        try {
            String url = MS_CONFIG_URL + "/api/v1/config/cargo-reparacion";
            Map<String, Double> response = restTemplate.getForObject(url, Map.class);
            return response != null ? ((Number) response.get("cargoReparacion")).doubleValue() : 10000.0;
        } catch (Exception e) {
            log.warn("Error al obtener cargo reparación, usando default: {}", e.getMessage());
            return 10000.0;
        }
    }

    private void updateToolStock(Long toolId, int quantity) {
        try {
            String url = MS_TOOLS_URL + "/api/v1/tools/" + toolId + "/stock";
            Map<String, Integer> body = new HashMap<>();
            body.put("quantity", quantity);
            restTemplate.put(url, body);
        } catch (Exception e) {
            log.error("Error al actualizar stock de herramienta {}: {}", toolId, e.getMessage());
        }
    }

    private void updateToolStatus(Long toolId, String status) {
        try {
            String url = MS_TOOLS_URL + "/api/v1/tools/" + toolId + "/status";
            Map<String, String> body = new HashMap<>();
            body.put("status", status);
            restTemplate.put(url, body);
        } catch (Exception e) {
            log.error("Error al actualizar estado de herramienta {}: {}", toolId, e.getMessage());
        }
    }

    private void registerKardexMovement(Long toolId, String toolName, String type, int quantity,
                                        String username, String observations, Long loanId) {
        try {
            String url = MS_KARDEX_URL + "/api/v1/kardex";
            Map<String, Object> body = new HashMap<>();
            body.put("toolId", toolId);
            body.put("toolName", toolName);
            body.put("movementType", type);
            body.put("quantity", quantity);
            body.put("username", username);
            body.put("observations", observations);
            body.put("loanId", loanId);
            restTemplate.postForObject(url, body, Object.class);
            log.info("Kardex registrado exitosamente: {} - {} unidades de herramienta {}", type, quantity, toolName);
        } catch (Exception e) {
            log.error("Error al registrar movimiento en kardex: {} - URL: {}", e.getMessage(), MS_KARDEX_URL + "/api/v1/kardex");
        }
    }

    private void updateClientStateIfNeeded(Long clientId) {
        try {
            // RF3.2: Verificar si el cliente tiene préstamos ACTIVOS atrasados
            // Solo los atrasos deben restringir, NO las multas por daño
            boolean hasActiveOverdues = loanRepository.hasActiveOverdueLoans(clientId);
            String newState = hasActiveOverdues ? "Restringido" : "Activo";

            String url = MS_CLIENTS_URL + "/api/v1/clients/" + clientId + "/state";
            Map<String, String> body = new HashMap<>();
            body.put("state", newState);
            restTemplate.put(url, body);
            log.info("Estado del cliente {} actualizado a: {}", clientId, newState);
        } catch (Exception e) {
            log.error("Error al actualizar estado del cliente {}: {}", clientId, e.getMessage());
        }
    }
}
