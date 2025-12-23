package com.toolrent.msloans.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

/**
 * DTO para recibir tarifas desde ms-config
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConfigDTO {
    private Double tarifaArriendoDiaria;
    private Double tarifaMultaDiaria;
    private Double cargoReparacion;
}
