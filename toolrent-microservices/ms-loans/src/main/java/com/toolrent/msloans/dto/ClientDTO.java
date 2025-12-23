package com.toolrent.msloans.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para recibir datos de clientes desde ms-clients
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClientDTO {
    private Long id;
    private String name;
    private String rut;
    private String phone;
    private String email;
    private String state;
}
