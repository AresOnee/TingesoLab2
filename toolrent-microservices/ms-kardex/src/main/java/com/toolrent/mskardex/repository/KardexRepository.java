package com.toolrent.mskardex.repository;

import com.toolrent.mskardex.entity.KardexEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface KardexRepository extends JpaRepository<KardexEntity, Long> {

    /**
     * RF5.2: Consultar historial de movimientos por herramienta
     */
    List<KardexEntity> findByToolIdOrderByMovementDateDesc(Long toolId);

    /**
     * RF5.3: Generar listado de movimientos por rango de fechas
     */
    List<KardexEntity> findByMovementDateBetweenOrderByMovementDateDesc(
            LocalDateTime startDate,
            LocalDateTime endDate
    );

    /**
     * Obtener todos ordenados por fecha descendente
     */
    List<KardexEntity> findAllByOrderByMovementDateDesc();

    /**
     * Buscar por tipo de movimiento
     */
    List<KardexEntity> findByMovementTypeOrderByMovementDateDesc(String movementType);

    /**
     * Buscar por herramienta y tipo
     */
    List<KardexEntity> findByToolIdAndMovementTypeOrderByMovementDateDesc(
            Long toolId,
            String movementType
    );

    /**
     * Buscar por préstamo
     */
    List<KardexEntity> findByLoanIdOrderByMovementDateDesc(Long loanId);
}
