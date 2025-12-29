-- ============================================
-- SEED DATA PARA MS-USERS (users_db)
-- Encoding: UTF-8
-- ============================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';

-- Crear tabla si no existe (estructura basada en UserEntity.java)
CREATE TABLE IF NOT EXISTS users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME,
    last_login DATETIME,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_username (username),
    UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Limpiar datos existentes
DELETE FROM users;

-- ============================================
-- USUARIOS (Épica 7)
-- ============================================

INSERT INTO users (id, username, email, full_name, role, active, created_at, last_login) VALUES
(1, 'admin', 'admin@toolrent.cl', 'Administrador del Sistema', 'ADMIN', TRUE, NOW(), NOW()),
(2, 'usuario', 'usuario@toolrent.cl', 'Usuario de Prueba', 'USER', TRUE, NOW(), NULL),
(3, 'maria.gonzalez', 'maria.gonzalez@email.cl', 'María González Pérez', 'USER', TRUE, NOW(), NULL),
(4, 'pedro.martinez', 'pedro.martinez@empresa.cl', 'Pedro Martínez López', 'USER', TRUE, NOW(), NULL),
(5, 'diego.morales', 'diego.morales@email.cl', 'Diego Morales Castro', 'USER', TRUE, NOW(), NULL);

SELECT 'Datos de USERS insertados correctamente' AS resultado;
