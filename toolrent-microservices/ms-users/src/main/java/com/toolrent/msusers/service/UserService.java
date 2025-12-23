package com.toolrent.msusers.service;

import com.toolrent.msusers.entity.UserEntity;
import com.toolrent.msusers.repository.UserRepository;
import jakarta.annotation.PostConstruct;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class UserService {

    @Autowired
    private UserRepository userRepository;

    /**
     * Inicializar usuarios por defecto si no existen
     */
    @PostConstruct
    public void initDefaultUsers() {
        // Usuario administrador
        if (!userRepository.existsByUsername("admin")) {
            UserEntity admin = new UserEntity();
            admin.setUsername("admin");
            admin.setEmail("admin@toolrent.cl");
            admin.setFullName("Administrador del Sistema");
            admin.setRole("ADMIN");
            admin.setActive(true);
            userRepository.save(admin);
        }

        // Usuario estándar de prueba
        if (!userRepository.existsByUsername("usuario")) {
            UserEntity user = new UserEntity();
            user.setUsername("usuario");
            user.setEmail("usuario@toolrent.cl");
            user.setFullName("Usuario de Prueba");
            user.setRole("USER");
            user.setActive(true);
            userRepository.save(user);
        }
    }

    /**
     * Obtener todos los usuarios
     */
    public List<UserEntity> getAllUsers() {
        return userRepository.findAll();
    }

    /**
     * Obtener usuario por ID
     */
    public UserEntity getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Usuario no encontrado"));
    }

    /**
     * Obtener usuario por username
     */
    public UserEntity getUserByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Usuario no encontrado"));
    }

    /**
     * Crear usuario
     */
    public UserEntity createUser(UserEntity user) {
        if (userRepository.existsByUsername(user.getUsername())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Ya existe un usuario con ese username");
        }

        if (userRepository.existsByEmail(user.getEmail())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Ya existe un usuario con ese email");
        }

        if (user.getActive() == null) {
            user.setActive(true);
        }

        return userRepository.save(user);
    }

    /**
     * Actualizar usuario
     */
    public UserEntity updateUser(Long id, UserEntity userDetails) {
        UserEntity user = getUserById(id);

        if (userDetails.getFullName() != null) {
            user.setFullName(userDetails.getFullName());
        }

        if (userDetails.getEmail() != null &&
                !userDetails.getEmail().equals(user.getEmail()) &&
                userRepository.existsByEmail(userDetails.getEmail())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Ya existe un usuario con ese email");
        } else if (userDetails.getEmail() != null) {
            user.setEmail(userDetails.getEmail());
        }

        if (userDetails.getRole() != null) {
            user.setRole(userDetails.getRole());
        }

        if (userDetails.getActive() != null) {
            user.setActive(userDetails.getActive());
        }

        return userRepository.save(user);
    }

    /**
     * Registrar login
     */
    public UserEntity registerLogin(String username) {
        UserEntity user = getUserByUsername(username);
        user.setLastLogin(LocalDateTime.now());
        return userRepository.save(user);
    }

    /**
     * Obtener usuarios por rol
     */
    public List<UserEntity> getUsersByRole(String role) {
        return userRepository.findByRole(role);
    }

    /**
     * Desactivar usuario
     */
    public UserEntity deactivateUser(Long id) {
        UserEntity user = getUserById(id);
        user.setActive(false);
        return userRepository.save(user);
    }

    /**
     * Activar usuario
     */
    public UserEntity activateUser(Long id) {
        UserEntity user = getUserById(id);
        user.setActive(true);
        return userRepository.save(user);
    }
}
