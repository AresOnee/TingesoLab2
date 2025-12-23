package com.toolrent.msclients.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "clients")
public class ClientEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(nullable = false)
    private String name;

    @NotBlank(message = "El RUT es obligatorio")
    @Column(nullable = false, unique = true)
    private String rut;

    @Pattern(regexp = "^\\+?[0-9]{9,15}$", message = "Teléfono inválido")
    private String phone;

    @Email(message = "Email inválido")
    @Column(unique = true)
    private String email;

    @NotBlank(message = "El estado es obligatorio")
    @Pattern(regexp = "^(Activo|Restringido)$", message = "Estado inválido. Valores: Activo, Restringido")
    @Column(nullable = false, length = 20)
    private String state;

    // Constructor sin state (se asigna "Activo" por defecto)
    public ClientEntity(Long id, String name, String rut, String phone, String email) {
        this.id = id;
        this.name = name;
        this.rut = rut;
        this.phone = phone;
        this.email = email;
        this.state = "Activo";
    }
}
