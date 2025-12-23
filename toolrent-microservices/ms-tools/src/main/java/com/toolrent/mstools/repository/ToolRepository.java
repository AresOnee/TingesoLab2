package com.toolrent.mstools.repository;

import com.toolrent.mstools.entity.ToolEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ToolRepository extends JpaRepository<ToolEntity, Long> {

    boolean existsByNameIgnoreCase(String name);

    List<ToolEntity> findByStatus(String status);

    List<ToolEntity> findByCategory(String category);

    List<ToolEntity> findByStockGreaterThan(int stock);
}
