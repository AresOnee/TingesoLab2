-- ============================================
-- SEED DATA PARA MS-TOOLS (tools_db)
-- Encoding: UTF-8
-- ============================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';

-- Limpiar datos existentes
TRUNCATE TABLE tools;

-- ============================================
-- HERRAMIENTAS (Épica 1)
-- ============================================

-- Categoría: TALADROS
INSERT INTO tools (id, name, category, status, replacement_value, stock) VALUES
(1, 'Taladro Percutor Bosch 850W', 'Taladros', 'Disponible', 89990, 5),
(2, 'Taladro Inalámbrico Dewalt 20V', 'Taladros', 'Disponible', 129990, 3),
(3, 'Taladro de Columna Industrial', 'Taladros', 'Prestada', 450000, 0);

-- Categoría: SIERRAS
INSERT INTO tools (id, name, category, status, replacement_value, stock) VALUES
(4, 'Sierra Circular Makita 7-1/4"', 'Sierras', 'Disponible', 109990, 4),
(5, 'Sierra Caladora Bosch 650W', 'Sierras', 'Disponible', 69990, 6),
(6, 'Sierra de Mesa DeWalt 10"', 'Sierras', 'Prestada', 389990, 0),
(7, 'Sierra Sable Black+Decker', 'Sierras', 'En Reparación', 79990, 1);

-- Categoría: LIJADORAS
INSERT INTO tools (id, name, category, status, replacement_value, stock) VALUES
(8, 'Lijadora Orbital Bosch 250W', 'Lijadoras', 'Disponible', 59990, 8),
(9, 'Lijadora de Banda Makita', 'Lijadoras', 'Disponible', 149990, 2);

-- Categoría: HERRAMIENTAS MANUALES
INSERT INTO tools (id, name, category, status, replacement_value, stock) VALUES
(10, 'Kit Llaves Combinadas 12 Piezas', 'Herramientas Manuales', 'Disponible', 45990, 10),
(11, 'Juego Destornilladores Profesional', 'Herramientas Manuales', 'Disponible', 29990, 15),
(12, 'Escalera Telescópica Aluminio 3.8m', 'Herramientas Manuales', 'Prestada', 129990, 0);

-- Categoría: EQUIPOS DE MEDICIÓN
INSERT INTO tools (id, name, category, status, replacement_value, stock) VALUES
(13, 'Nivel Láser Autonivelante', 'Equipos de Medición', 'Disponible', 89990, 3),
(14, 'Huincha Métrica Láser 50m', 'Equipos de Medición', 'Disponible', 39990, 7);

-- Categoría: COMPRESORES
INSERT INTO tools (id, name, category, status, replacement_value, stock) VALUES
(15, 'Compresor de Aire 50L 2HP', 'Compresores', 'Disponible', 189990, 2),
(16, 'Pistola de Pintura HVLP', 'Compresores', 'Disponible', 79990, 4);

-- Categoría: SOLDADURA
INSERT INTO tools (id, name, category, status, replacement_value, stock) VALUES
(17, 'Soldadora Inverter 200A', 'Soldadura', 'Disponible', 159990, 2);

-- Herramientas dadas de BAJA
INSERT INTO tools (id, name, category, status, replacement_value, stock) VALUES
(18, 'Taladro Antiguo (Obsoleto)', 'Taladros', 'Baja', 45000, 0),
(19, 'Sierra Circular Dañada', 'Sierras', 'Baja', 89990, 0);

SELECT 'Datos de TOOLS insertados correctamente' AS resultado;
