package com.toolrent.mstools.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(
        name = "tools",
        uniqueConstraints = @UniqueConstraint(name = "uq_tools_name", columnNames = "name")
)
public class ToolEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(nullable = false)
    private String name;

    @NotBlank(message = "La categoría es obligatoria")
    @Column(nullable = false)
    private String category;

    @NotBlank(message = "El estado es obligatorio")
    @Column(nullable = false)
    private String status;

    @Min(value = 1, message = "El valor de reposición debe ser mayor a 0")
    @Column(name = "replacement_value", nullable = false)
    private int replacementValue;

    @Min(value = 0, message = "El stock no puede ser negativo")
    @Column(nullable = false)
    private int stock;
}
