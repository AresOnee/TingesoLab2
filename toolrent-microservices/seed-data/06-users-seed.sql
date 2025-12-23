-- ============================================
-- SEED DATA PARA MS-USERS (users_db)
-- Encoding: UTF-8
-- ============================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';

-- Limpiar datos existentes
TRUNCATE TABLE users;

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
