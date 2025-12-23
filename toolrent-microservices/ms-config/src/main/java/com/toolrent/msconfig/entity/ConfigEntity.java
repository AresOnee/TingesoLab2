package com.toolrent.msconfig.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "system_config")
public class ConfigEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "La clave es obligatoria")
    @Column(name = "config_key", unique = true, nullable = false, length = 100)
    private String configKey;

    @NotNull(message = "El valor es obligatorio")
    @Min(value = 0, message = "El valor no puede ser negativo")
    @Column(name = "config_value", nullable = false)
    private Double configValue;

    @Column(length = 255)
    private String description;

    @Column(name = "last_modified", nullable = false)
    private LocalDateTime lastModified;

    @Column(name = "modified_by")
    private String modifiedBy;

    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        this.lastModified = LocalDateTime.now();
    }
}
