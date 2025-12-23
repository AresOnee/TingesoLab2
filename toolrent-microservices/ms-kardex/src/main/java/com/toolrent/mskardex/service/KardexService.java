package com.toolrent.mskardex.service;

import com.toolrent.mskardex.entity.KardexEntity;
import com.toolrent.mskardex.repository.KardexRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class KardexService {

    @Autowired
    private KardexRepository kardexRepository;

    /**
     * Obtener todos los movimientos
     */
    public List<KardexEntity> getAllMovements() {
        return kardexRepository.findAllByOrderByMovementDateDesc();
    }

    /**
     * RF5.1: Registrar movimiento en kardex
     */
    public KardexEntity registerMovement(
            Long toolId,
            String toolName,
            String movementType,
            Integer quantity,
            String username,
            String observations,
            Long loanId
    ) {
        KardexEntity kardex = new KardexEntity();
        kardex.setToolId(toolId);
        kardex.setToolName(toolName);
        kardex.setMovementType(movementType);
        kardex.setQuantity(quantity);
        kardex.setUsername(username);
        kardex.setMovementDate(LocalDateTime.now());
        kardex.setObservations(observations);
        kardex.setLoanId(loanId);

        return kardexRepository.save(kardex);
    }

    /**
     * RF5.2: Consultar historial de movimientos por herramienta
     */
    public List<KardexEntity> getMovementsByTool(Long toolId) {
        return kardexRepository.findByToolIdOrderByMovementDateDesc(toolId);
    }

    /**
     * RF5.3: Generar listado de movimientos por rango de fechas
     */
    public List<KardexEntity> getMovementsByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        return kardexRepository.findByMovementDateBetweenOrderByMovementDateDesc(startDate, endDate);
    }

    /**
     * Obtener movimientos por tipo
     */
    public List<KardexEntity> getMovementsByType(String movementType) {
        return kardexRepository.findByMovementTypeOrderByMovementDateDesc(movementType);
    }

    /**
     * Obtener movimientos por préstamo
     */
    public List<KardexEntity> getMovementsByLoan(Long loanId) {
        return kardexRepository.findByLoanIdOrderByMovementDateDesc(loanId);
    }
}
