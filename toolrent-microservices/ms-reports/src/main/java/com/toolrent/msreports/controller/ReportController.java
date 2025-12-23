package com.toolrent.msreports.controller;

import com.toolrent.msreports.dto.ClientDTO;
import com.toolrent.msreports.dto.LoanDTO;
import com.toolrent.msreports.dto.ToolRankingDTO;
import com.toolrent.msreports.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {

    @Autowired
    private ReportService reportService;

    /**
     * RF6.1: Obtener préstamos activos
     * GET /api/v1/reports/active-loans
     */
    @GetMapping("/active-loans")
    public ResponseEntity<List<LoanDTO>> getActiveLoans() {
        return ResponseEntity.ok(reportService.getActiveLoans());
    }

    /**
     * RF6.2: Obtener clientes con atrasos
     * GET /api/v1/reports/clients-with-overdues
     */
    @GetMapping("/clients-with-overdues")
    public ResponseEntity<List<ClientDTO>> getClientsWithOverdues() {
        return ResponseEntity.ok(reportService.getClientsWithOverdues());
    }

    /**
     * RF6.3: Obtener ranking de herramientas más prestadas
     * GET /api/v1/reports/most-loaned-tools
     */
    @GetMapping("/most-loaned-tools")
    public ResponseEntity<List<ToolRankingDTO>> getMostLoanedTools(
            @RequestParam(defaultValue = "10") int limit
    ) {
        return ResponseEntity.ok(reportService.getMostLoanedTools(limit));
    }
}
