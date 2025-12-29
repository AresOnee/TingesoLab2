-- ============================================
-- SEED DATA PARA MS-LOANS (loans_db)
-- Encoding: UTF-8
-- ============================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';

-- Crear tabla si no existe (estructura basada en LoanEntity.java)
CREATE TABLE IF NOT EXISTS loans (
    id BIGINT NOT NULL AUTO_INCREMENT,
    client_id BIGINT NOT NULL,
    tool_id BIGINT NOT NULL,
    client_name VARCHAR(255),
    tool_name VARCHAR(255),
    start_date DATE,
    due_date DATE,
    return_date DATE,
    status VARCHAR(255) NOT NULL,
    fine DOUBLE,
    rental_cost DOUBLE,
    damaged TINYINT(1),
    irreparable TINYINT(1),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Limpiar datos existentes
DELETE FROM loans;

-- ============================================
-- PRÉSTAMOS (Épica 3)
-- ============================================

-- PRÉSTAMOS ACTIVOS (en plazo, sin problemas)
INSERT INTO loans (id, client_id, tool_id, client_name, tool_name, start_date, due_date, return_date, status, fine, rental_cost, damaged, irreparable) VALUES
(1, 1, 3, 'María González Pérez', 'Taladro de Columna Industrial', '2025-11-25', '2025-12-09', NULL, 'ACTIVO', 0, 70000, FALSE, FALSE),
(2, 1, 6, 'María González Pérez', 'Sierra de Mesa DeWalt 10"', '2025-11-28', '2025-12-12', NULL, 'ACTIVO', 0, 70000, FALSE, FALSE),
(3, 2, 12, 'Pedro Martínez López', 'Escalera Telescópica Aluminio 3.8m', '2025-11-30', '2025-12-14', NULL, 'ACTIVO', 0, 70000, FALSE, FALSE);

-- PRÉSTAMOS ATRASADOS (vencidos, generan multa)
INSERT INTO loans (id, client_id, tool_id, client_name, tool_name, start_date, due_date, return_date, status, fine, rental_cost, damaged, irreparable) VALUES
(4, 8, 1, 'Diego Morales Castro', 'Taladro Percutor Bosch 850W', '2025-10-15', '2025-10-29', NULL, 'ATRASADO', 30000, 70000, FALSE, FALSE),
(5, 9, 4, 'Francisca Herrera Soto', 'Sierra Circular Makita 7-1/4"', '2025-10-01', '2025-10-15', NULL, 'ATRASADO', 60000, 70000, FALSE, FALSE);

-- PRÉSTAMOS CERRADOS (histórico)
INSERT INTO loans (id, client_id, tool_id, client_name, tool_name, start_date, due_date, return_date, status, fine, rental_cost, damaged, irreparable) VALUES
(6, 3, 8, 'Ana Silva Rojas', 'Lijadora Orbital Bosch 250W', '2025-10-01', '2025-10-15', '2025-10-14', 'CERRADO', 0, 70000, FALSE, FALSE),
(7, 3, 13, 'Ana Silva Rojas', 'Nivel Láser Autonivelante', '2025-10-20', '2025-11-03', '2025-11-02', 'CERRADO', 0, 70000, FALSE, FALSE),
(8, 4, 9, 'Carlos Fernández Muñoz', 'Lijadora de Banda Makita', '2025-10-10', '2025-10-24', '2025-10-27', 'CERRADO', 6000, 70000, FALSE, FALSE),
(9, 5, 5, 'Isabel Torres Vargas', 'Sierra Caladora Bosch 650W', '2025-09-15', '2025-09-29', '2025-09-29', 'CERRADO', 10000, 70000, TRUE, FALSE),
(10, 6, 2, 'Roberto Sánchez Díaz', 'Taladro Inalámbrico Dewalt 20V', '2025-09-01', '2025-09-15', '2025-09-14', 'CERRADO', 129990, 70000, TRUE, TRUE),
(11, 7, 14, 'Carmen Ramírez Flores', 'Huincha Métrica Láser 50m', '2025-08-01', '2025-08-15', '2025-08-15', 'CERRADO', 0, 70000, FALSE, FALSE),
(12, 7, 10, 'Carmen Ramírez Flores', 'Kit Llaves Combinadas 12 Piezas', '2025-08-20', '2025-09-03', '2025-09-02', 'CERRADO', 0, 70000, FALSE, FALSE),
(13, 7, 11, 'Carmen Ramírez Flores', 'Juego Destornilladores Profesional', '2025-09-10', '2025-09-24', '2025-09-23', 'CERRADO', 0, 70000, FALSE, FALSE),
(14, 1, 15, 'María González Pérez', 'Compresor de Aire 50L 2HP', '2025-07-01', '2025-07-15', '2025-07-14', 'CERRADO', 0, 70000, FALSE, FALSE),
(15, 2, 16, 'Pedro Martínez López', 'Pistola de Pintura HVLP', '2025-07-10', '2025-07-24', '2025-07-23', 'CERRADO', 0, 70000, FALSE, FALSE),
(16, 3, 17, 'Ana Silva Rojas', 'Soldadora Inverter 200A', '2025-07-15', '2025-07-29', '2025-07-30', 'CERRADO', 2000, 70000, FALSE, FALSE),
(17, 4, 1, 'Carlos Fernández Muñoz', 'Taladro Percutor Bosch 850W', '2025-08-05', '2025-08-19', '2025-08-18', 'CERRADO', 0, 70000, FALSE, FALSE),
(18, 5, 4, 'Isabel Torres Vargas', 'Sierra Circular Makita 7-1/4"', '2025-08-10', '2025-08-24', '2025-08-24', 'CERRADO', 0, 70000, FALSE, FALSE);

SELECT 'Datos de LOANS insertados correctamente' AS resultado;
