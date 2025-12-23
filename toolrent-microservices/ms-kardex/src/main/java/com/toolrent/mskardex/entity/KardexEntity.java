package com.toolrent.mskardex.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "kardex")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class KardexEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Tipo de movimiento:
     * - REGISTRO (alta de herramienta)
     * - PRESTAMO
     * - DEVOLUCION
     * - BAJA
     * - REPARACION
     */
    @NotBlank(message = "El tipo de movimiento es obligatorio")
    @Column(name = "movement_type", nullable = false, length = 50)
    private String movementType;

    /**
     * ID de la herramienta afectada
     */
    @NotNull(message = "El ID de herramienta es obligatorio")
    @Column(name = "tool_id", nullable = false)
    private Long toolId;

    /**
     * Nombre de la herramienta (desnormalizado para consultas rápidas)
     */
    @Column(name = "tool_name")
    private String toolName;

    /**
     * Cantidad afectada en el movimiento
     */
    @NotNull(message = "La cantidad es obligatoria")
    @Column(nullable = false)
    private Integer quantity;

    /**
     * Usuario que realizó el movimiento
     */
    @Column(length = 100)
    private String username;

    /**
     * Fecha y hora del movimiento
     */
    @NotNull(message = "La fecha de movimiento es obligatoria")
    @Column(name = "movement_date", nullable = false)
    private LocalDateTime movementDate;

    /**
     * Observaciones adicionales del movimiento
     */
    @Column(columnDefinition = "TEXT")
    private String observations;

    /**
     * Referencia opcional al préstamo asociado
     */
    @Column(name = "loan_id")
    private Long loanId;
}
