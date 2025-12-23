package com.toolrent.msreports.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoanDTO {
    private Long id;
    private Long clientId;
    private Long toolId;
    private String clientName;
    private String toolName;
    private LocalDate startDate;
    private LocalDate dueDate;
    private LocalDate returnDate;
    private String status;
    private Double fine;
    private Double rentalCost;
    private Boolean damaged;
    private Boolean irreparable;
}
