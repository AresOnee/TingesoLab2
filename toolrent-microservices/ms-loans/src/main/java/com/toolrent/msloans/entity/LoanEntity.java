package com.toolrent.msloans.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "loans")
public class LoanEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "client_id", nullable = false)
    private Long clientId;

    @Column(name = "tool_id", nullable = false)
    private Long toolId;

    // Campos desnormalizados para consultas rápidas
    @Column(name = "client_name")
    private String clientName;

    @Column(name = "tool_name")
    private String toolName;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Column(name = "return_date")
    private LocalDate returnDate;

    @Column(nullable = false)
    private String status; // ACTIVO, ATRASADO, CERRADO

    private Double fine;

    @Column(name = "rental_cost")
    private Double rentalCost;

    private Boolean damaged;

    private Boolean irreparable;
}
