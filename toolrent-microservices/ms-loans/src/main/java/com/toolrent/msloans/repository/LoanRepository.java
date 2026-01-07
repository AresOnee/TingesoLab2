package com.toolrent.msloans.repository;

import com.toolrent.msloans.entity.LoanEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface LoanRepository extends JpaRepository<LoanEntity, Long> {

    /**
     * Cuenta préstamos activos de un cliente
     */
    @Query("SELECT COUNT(l) FROM LoanEntity l WHERE l.clientId = :clientId AND l.status IN ('ACTIVO', 'ATRASADO')")
    long countActiveByClientId(@Param("clientId") Long clientId);

    /**
     * Cuenta préstamos activos de una herramienta (para calcular disponibilidad)
     */
    @Query("SELECT COUNT(l) FROM LoanEntity l WHERE l.toolId = :toolId AND l.returnDate IS NULL")
    long countActiveByToolId(@Param("toolId") Long toolId);

    /**
     * Verifica si un cliente tiene préstamo activo con una herramienta
     */
    @Query("SELECT (COUNT(l) > 0) FROM LoanEntity l WHERE l.clientId = :clientId AND l.toolId = :toolId AND l.status IN ('ACTIVO', 'ATRASADO')")
    boolean existsActiveByClientAndTool(@Param("clientId") Long clientId, @Param("toolId") Long toolId);

    /**
     * RF3.2: Verifica si un cliente tiene préstamos ACTIVOS atrasados
     * IMPORTANTE: Solo considera préstamos NO devueltos que están atrasados
     * Las multas por daño NO deben restringir al cliente (solo los atrasos)
     */
    @Query("SELECT (COUNT(l) > 0) FROM LoanEntity l WHERE l.clientId = :clientId AND l.returnDate IS NULL AND l.dueDate < CURRENT_DATE")
    boolean hasActiveOverdueLoans(@Param("clientId") Long clientId);

    /**
     * Obtener préstamos activos (sin devolver)
     */
    @Query("SELECT l FROM LoanEntity l WHERE l.returnDate IS NULL ORDER BY l.dueDate ASC")
    List<LoanEntity> findActiveLoans();

    /**
     * Préstamos activos por rango de fechas
     */
    @Query("SELECT l FROM LoanEntity l WHERE l.returnDate IS NULL AND l.startDate >= :startDate AND l.startDate <= :endDate ORDER BY l.dueDate ASC")
    List<LoanEntity> findActiveLoansByDateRange(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    /**
     * Préstamos por cliente
     */
    List<LoanEntity> findByClientIdOrderByStartDateDesc(Long clientId);

    /**
     * Préstamos por herramienta
     */
    List<LoanEntity> findByToolIdOrderByStartDateDesc(Long toolId);

    /**
     * Préstamos atrasados
     */
    @Query("SELECT l FROM LoanEntity l WHERE l.returnDate IS NULL AND l.dueDate < :today")
    List<LoanEntity> findOverdueLoans(@Param("today") LocalDate today);

    /**
     * IDs de clientes con préstamos atrasados
     */
    @Query("SELECT DISTINCT l.clientId FROM LoanEntity l WHERE l.returnDate IS NULL AND l.dueDate < :today")
    List<Long> findClientIdsWithOverdues(@Param("today") LocalDate today);
}
