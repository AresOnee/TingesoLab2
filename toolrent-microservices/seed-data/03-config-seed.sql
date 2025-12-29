-- ============================================
-- SEED DATA PARA MS-CONFIG (config_db)
-- Encoding: UTF-8
-- ============================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';

-- Crear tabla si no existe (estructura basada en ConfigEntity.java)
CREATE TABLE IF NOT EXISTS system_config (
    id BIGINT NOT NULL AUTO_INCREMENT,
    config_key VARCHAR(100) NOT NULL,
    config_value DOUBLE NOT NULL,
    description VARCHAR(255),
    last_modified DATETIME NOT NULL,
    modified_by VARCHAR(255),
    PRIMARY KEY (id),
    UNIQUE KEY uq_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Limpiar datos existentes
DELETE FROM system_config;

-- ============================================
-- CONFIGURACIÓN DEL SISTEMA (Épica 4)
-- ============================================

INSERT INTO system_config (id, config_key, config_value, description, last_modified, modified_by) VALUES
(1, 'TARIFA_ARRIENDO_DIARIA', 5000.00, 'Tarifa base de arriendo por día (CLP)', NOW(), 'admin'),
(2, 'TARIFA_MULTA_DIARIA', 2000.00, 'Multa por día de atraso (CLP)', NOW(), 'admin'),
(3, 'CARGO_REPARACION', 10000.00, 'Cargo fijo por reparación de herramientas con daños leves', NOW(), 'admin');

SELECT 'Datos de CONFIG insertados correctamente' AS resultado;
