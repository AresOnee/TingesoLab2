package com.toolrent.msconfig.repository;

import com.toolrent.msconfig.entity.ConfigEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ConfigRepository extends JpaRepository<ConfigEntity, Long> {

    Optional<ConfigEntity> findByConfigKey(String configKey);

    boolean existsByConfigKey(String configKey);
}
