-- ============================================
-- SEED DATA PARA MS-KARDEX (kardex_db)
-- Encoding: UTF-8
-- ============================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';

-- Limpiar datos existentes
TRUNCATE TABLE kardex;

-- ============================================
-- KARDEX (Épica 5: Trazabilidad de Inventario)
-- ============================================

-- REGISTRO inicial de herramientas
INSERT INTO kardex (id, movement_type, tool_id, tool_name, quantity, username, movement_date, observations, loan_id) VALUES
(1, 'REGISTRO', 1, 'Taladro Percutor Bosch 850W', 5, 'admin', '2025-01-15 10:00:00', 'Alta inicial de taladros Bosch', NULL),
(2, 'REGISTRO', 2, 'Taladro Inalámbrico Dewalt 20V', 3, 'admin', '2025-01-15 10:15:00', 'Alta inicial de taladros Dewalt', NULL),
(3, 'REGISTRO', 3, 'Taladro de Columna Industrial', 1, 'admin', '2025-01-15 10:30:00', 'Alta taladro de columna industrial', NULL),
(4, 'REGISTRO', 4, 'Sierra Circular Makita 7-1/4"', 4, 'admin', '2025-01-16 09:00:00', 'Alta sierras circulares Makita', NULL),
(5, 'REGISTRO', 5, 'Sierra Caladora Bosch 650W', 6, 'admin', '2025-01-16 09:30:00', 'Alta sierras caladoras Bosch', NULL),
(6, 'REGISTRO', 8, 'Lijadora Orbital Bosch 250W', 8, 'admin', '2025-01-20 11:00:00', 'Alta lijadoras orbitales', NULL),
(7, 'REGISTRO', 13, 'Nivel Láser Autonivelante', 3, 'admin', '2025-01-25 14:00:00', 'Alta niveles láser', NULL),
(8, 'REGISTRO', 15, 'Compresor de Aire 50L 2HP', 2, 'admin', '2025-02-01 10:00:00', 'Alta compresores de aire', NULL);

-- PRÉSTAMOS (salidas de stock)
INSERT INTO kardex (id, movement_type, tool_id, tool_name, quantity, username, movement_date, observations, loan_id) VALUES
(9, 'PRESTAMO', 3, 'Taladro de Columna Industrial', -1, 'maria.gonzalez', '2025-11-25 14:30:00', 'Préstamo taladro columna a María González', 1),
(10, 'PRESTAMO', 6, 'Sierra de Mesa DeWalt 10"', -1, 'maria.gonzalez', '2025-11-28 10:15:00', 'Préstamo sierra de mesa a María González', 2),
(11, 'PRESTAMO', 12, 'Escalera Telescópica Aluminio 3.8m', -1, 'pedro.martinez', '2025-11-30 11:00:00', 'Préstamo escalera a Pedro Martínez', 3),
(12, 'PRESTAMO', 1, 'Taladro Percutor Bosch 850W', -1, 'diego.morales', '2025-10-15 09:00:00', 'Préstamo taladro Bosch a Diego (ATRASADO)', 4),
(13, 'PRESTAMO', 4, 'Sierra Circular Makita 7-1/4"', -1, 'francisca.herrera', '2025-10-01 10:30:00', 'Préstamo sierra circular a Francisca (ATRASADO)', 5);

-- DEVOLUCIONES (ingresos de stock)
INSERT INTO kardex (id, movement_type, tool_id, tool_name, quantity, username, movement_date, observations, loan_id) VALUES
(14, 'DEVOLUCION', 8, 'Lijadora Orbital Bosch 250W', 1, 'ana.silva', '2025-10-14 16:00:00', 'Devolución lijadora en perfecto estado', 6),
(15, 'DEVOLUCION', 13, 'Nivel Láser Autonivelante', 1, 'ana.silva', '2025-11-02 15:30:00', 'Devolución nivel láser sin problemas', 7),
(16, 'DEVOLUCION', 9, 'Lijadora de Banda Makita', 1, 'carlos.fernandez', '2025-10-27 17:00:00', 'Devolución con 3 días de atraso', 8),
(17, 'DEVOLUCION', 5, 'Sierra Caladora Bosch 650W', 1, 'isabel.torres', '2025-09-29 14:00:00', 'Devolución con daño reparable detectado', 9),
(18, 'DEVOLUCION', 2, 'Taladro Inalámbrico Dewalt 20V', 1, 'roberto.sanchez', '2025-09-14 16:30:00', 'Devolución con daño IRREPARABLE - reposición cobrada', 10);

-- REPARACIONES
INSERT INTO kardex (id, movement_type, tool_id, tool_name, quantity, username, movement_date, observations, loan_id) VALUES
(19, 'REPARACION', 7, 'Sierra Sable Black+Decker', -1, 'admin', '2025-11-15 10:00:00', 'Sierra sable enviada a reparación por desgaste', NULL),
(20, 'REPARACION', 5, 'Sierra Caladora Bosch 650W', -1, 'admin', '2025-09-29 16:00:00', 'Sierra caladora en reparación por daño en préstamo #9', 9),
(21, 'DEVOLUCION', 5, 'Sierra Caladora Bosch 650W', 1, 'admin', '2025-10-05 11:00:00', 'Sierra caladora reparada y lista para uso', 9);

-- BAJAS (herramientas dadas de baja)
INSERT INTO kardex (id, movement_type, tool_id, tool_name, quantity, username, movement_date, observations, loan_id) VALUES
(22, 'BAJA', 18, 'Taladro Antiguo (Obsoleto)', 0, 'admin', '2025-08-01 09:00:00', 'Taladro obsoleto dado de baja por antigüedad', NULL),
(23, 'BAJA', 19, 'Sierra Circular Dañada', 0, 'admin', '2025-08-15 10:00:00', 'Sierra circular con daño irreparable - baja definitiva', NULL),
(24, 'BAJA', 2, 'Taladro Inalámbrico Dewalt 20V', -1, 'admin', '2025-09-14 17:00:00', 'Taladro Dewalt dado de baja tras daño irreparable en préstamo #10', 10);

SELECT 'Datos de KARDEX insertados correctamente' AS resultado;
