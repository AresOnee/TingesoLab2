package com.toolrent.msloans.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para recibir datos de herramientas desde ms-tools
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ToolDTO {
    private Long id;
    private String name;
    private String category;
    private String status;
    private int replacementValue;
    private int stock;
}
