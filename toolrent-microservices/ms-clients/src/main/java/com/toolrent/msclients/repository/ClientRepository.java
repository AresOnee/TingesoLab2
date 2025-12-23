package com.toolrent.msclients.repository;

import com.toolrent.msclients.entity.ClientEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClientRepository extends JpaRepository<ClientEntity, Long> {

    boolean existsByRut(String rut);

    boolean existsByEmail(String email);

    Optional<ClientEntity> findByRut(String rut);

    List<ClientEntity> findByState(String state);

    @Modifying
    @Query("UPDATE ClientEntity c SET c.state = :newState WHERE c.id = :clientId")
    void updateClientState(@Param("clientId") Long clientId, @Param("newState") String newState);
}
