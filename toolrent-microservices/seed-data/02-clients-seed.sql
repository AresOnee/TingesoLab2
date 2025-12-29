-- ============================================
-- SEED DATA PARA MS-CLIENTS (clients_db)
-- Encoding: UTF-8
-- ============================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';

-- Crear tabla si no existe (estructura basada en ClientEntity.java)
CREATE TABLE IF NOT EXISTS clients (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    rut VARCHAR(255) NOT NULL,
    phone VARCHAR(255),
    email VARCHAR(255),
    state VARCHAR(20) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_clients_rut (rut),
    UNIQUE KEY uq_clients_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Limpiar datos existentes
DELETE FROM clients;

-- ============================================
-- CLIENTES (Épica 2)
-- ============================================

-- Clientes ACTIVOS (pueden arrendar)
INSERT INTO clients (id, name, rut, phone, email, state) VALUES
(1, 'María González Pérez', '16.789.234-5', '+56987654321', 'maria.gonzalez@email.cl', 'Activo'),
(2, 'Pedro Martínez López', '18.456.789-2', '+56912345678', 'pedro.martinez@empresa.cl', 'Activo'),
(3, 'Ana Silva Rojas', '20.123.456-7', '+56945678901', 'ana.silva@constructor.cl', 'Activo'),
(4, 'Carlos Fernández Muñoz', '19.876.543-K', '+56923456789', 'carlos.fernandez@taller.cl', 'Activo'),
(5, 'Isabel Torres Vargas', '17.234.567-8', '+56934567890', 'isabel.torres@arquitectura.cl', 'Activo'),
(6, 'Roberto Sánchez Díaz', '21.345.678-9', '+56956789012', 'roberto.sanchez@construcciones.cl', 'Activo'),
(7, 'Carmen Ramírez Flores', '15.987.654-3', '+56978901234', 'carmen.ramirez@hogar.cl', 'Activo');

-- Clientes RESTRINGIDOS (con préstamos atrasados/multas pendientes)
INSERT INTO clients (id, name, rut, phone, email, state) VALUES
(8, 'Diego Morales Castro', '19.234.567-1', '+56967890123', 'diego.morales@email.cl', 'Restringido'),
(9, 'Francisca Herrera Soto', '18.765.432-6', '+56989012345', 'francisca.herrera@empresa.cl', 'Restringido');

SELECT 'Datos de CLIENTS insertados correctamente' AS resultado;
