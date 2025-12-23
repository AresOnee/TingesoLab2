package com.toolrent.msconfig.service;

import com.toolrent.msconfig.entity.ConfigEntity;
import com.toolrent.msconfig.repository.ConfigRepository;
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
public class ConfigService {

    // Claves de configuración
    public static final String TARIFA_ARRIENDO_DIARIA = "TARIFA_ARRIENDO_DIARIA";
    public static final String TARIFA_MULTA_DIARIA = "TARIFA_MULTA_DIARIA";
    public static final String CARGO_REPARACION = "CARGO_REPARACION";

    // Valores por defecto
    private static final Double DEFAULT_TARIFA_ARRIENDO = 5000.0;
    private static final Double DEFAULT_TARIFA_MULTA = 2000.0;
    private static final Double DEFAULT_CARGO_REPARACION = 10000.0;

    @Autowired
    private ConfigRepository configRepository;

    /**
     * Inicializar configuraciones por defecto si no existen
     */
    @PostConstruct
    public void initDefaultConfigs() {
        createIfNotExists(TARIFA_ARRIENDO_DIARIA, DEFAULT_TARIFA_ARRIENDO,
                "Tarifa base de arriendo por día (CLP)");
        createIfNotExists(TARIFA_MULTA_DIARIA, DEFAULT_TARIFA_MULTA,
                "Multa por día de atraso (CLP)");
        createIfNotExists(CARGO_REPARACION, DEFAULT_CARGO_REPARACION,
                "Cargo fijo por reparación de herramientas con daños leves");
    }

    private void createIfNotExists(String key, Double value, String description) {
        if (!configRepository.existsByConfigKey(key)) {
            ConfigEntity config = new ConfigEntity();
            config.setConfigKey(key);
            config.setConfigValue(value);
            config.setDescription(description);
            config.setLastModified(LocalDateTime.now());
            config.setModifiedBy("system");
            configRepository.save(config);
        }
    }

    /**
     * Obtener todas las configuraciones
     */
    public List<ConfigEntity> getAllConfigs() {
        return configRepository.findAll();
    }

    /**
     * Obtener configuración por ID
     */
    public ConfigEntity getConfigById(Long id) {
        return configRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Configuración no encontrada"));
    }

    /**
     * Obtener configuración por clave
     */
    public ConfigEntity getConfigByKey(String key) {
        return configRepository.findByConfigKey(key)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        String.format("Configuración '%s' no encontrada", key)));
    }

    /**
     * Obtener valor de configuración por clave
     */
    public Double getConfigValue(String key) {
        return getConfigByKey(key).getConfigValue();
    }

    /**
     * RF4.1: Obtener tarifa de arriendo diaria
     */
    public Double getTarifaArriendoDiaria() {
        return getConfigValue(TARIFA_ARRIENDO_DIARIA);
    }

    /**
     * RF4.2: Obtener tarifa de multa diaria
     */
    public Double getTarifaMultaDiaria() {
        return getConfigValue(TARIFA_MULTA_DIARIA);
    }

    /**
     * Obtener cargo por reparación
     */
    public Double getCargoReparacion() {
        return getConfigValue(CARGO_REPARACION);
    }

    /**
     * Actualizar configuración por ID
     */
    public ConfigEntity updateConfigById(Long id, Double newValue, String username) {
        ConfigEntity config = getConfigById(id);
        config.setConfigValue(newValue);
        config.setModifiedBy(username);
        return configRepository.save(config);
    }

    /**
     * Actualizar configuración por clave
     */
    public ConfigEntity updateConfigByKey(String key, Double newValue, String username) {
        ConfigEntity config = getConfigByKey(key);
        config.setConfigValue(newValue);
        config.setModifiedBy(username);
        return configRepository.save(config);
    }

    /**
     * RF4.1: Actualizar tarifa de arriendo
     */
    public ConfigEntity setTarifaArriendoDiaria(Double value, String username) {
        return updateConfigByKey(TARIFA_ARRIENDO_DIARIA, value, username);
    }

    /**
     * RF4.2: Actualizar tarifa de multa
     */
    public ConfigEntity setTarifaMultaDiaria(Double value, String username) {
        return updateConfigByKey(TARIFA_MULTA_DIARIA, value, username);
    }

    /**
     * Actualizar cargo por reparación
     */
    public ConfigEntity setCargoReparacion(Double value, String username) {
        return updateConfigByKey(CARGO_REPARACION, value, username);
    }
}
