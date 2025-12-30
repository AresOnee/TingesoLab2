package com.toolrent.msloans.controller;

import com.toolrent.msloans.entity.LoanEntity;
import com.toolrent.msloans.service.LoanService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/loans")
public class LoanController {

    @Autowired
    private LoanService loanService;

    /**
     * Obtener todos los préstamos
     * GET /api/v1/loans
     */
    @GetMapping("")
    public ResponseEntity<List<LoanEntity>> getAllLoans() {
        return ResponseEntity.ok(loanService.getAllLoans());
    }

    /**
     * Obtener préstamo por ID
     * GET /api/v1/loans/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<LoanEntity> getLoanById(@PathVariable Long id) {
        return ResponseEntity.ok(loanService.getLoanById(id));
    }

    /**
     * RF2.1: Crear préstamo
     * POST /api/v1/loans/create
     */
    @PostMapping("/create")
    public ResponseEntity<LoanEntity> createLoan(
            @RequestParam Long clientId,
            @RequestParam Long toolId,
            @RequestParam String dueDate,
            @RequestParam(defaultValue = "system") String username
    ) {
        LoanEntity loan = loanService.createLoan(clientId, toolId, LocalDate.parse(dueDate), username);
        return ResponseEntity.status(HttpStatus.CREATED).body(loan);
    }

    /**
     * RF2.1: Crear préstamo (alternativa con body JSON)
     * POST /api/v1/loans
     */
    @PostMapping("")
    public ResponseEntity<LoanEntity> createLoanJson(@RequestBody Map<String, Object> body) {
        Long clientId = Long.valueOf(body.get("clientId").toString());
        Long toolId = Long.valueOf(body.get("toolId").toString());
        LocalDate dueDate = LocalDate.parse(body.get("dueDate").toString());
        String username = body.getOrDefault("username", "system").toString();

        LoanEntity loan = loanService.createLoan(clientId, toolId, dueDate, username);
        return ResponseEntity.status(HttpStatus.CREATED).body(loan);
    }

    /**
     * RF2.3: Registrar devolución
     * POST /api/v1/loans/return
     */
    @PostMapping("/return")
    public ResponseEntity<LoanEntity> returnLoan(
            @RequestParam Long loanId,
            @RequestParam boolean isDamaged,
            @RequestParam boolean isIrreparable,
            @RequestParam(defaultValue = "system") String username
    ) {
        LoanEntity loan = loanService.returnTool(loanId, isDamaged, isIrreparable, username);
        return ResponseEntity.ok(loan);
    }

    /**
     * RF2.3: Registrar devolución (alternativa con body JSON)
     * PUT /api/v1/loans/{id}/return
     */
    @PutMapping("/{id}/return")
    public ResponseEntity<LoanEntity> returnLoanJson(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body
    ) {
        boolean isDamaged = Boolean.parseBoolean(body.getOrDefault("damaged", "false").toString());
        boolean isIrreparable = Boolean.parseBoolean(body.getOrDefault("irreparable", "false").toString());
        String username = body.getOrDefault("username", "system").toString();

        LoanEntity loan = loanService.returnTool(id, isDamaged, isIrreparable, username);
        return ResponseEntity.ok(loan);
    }

    /**
     * Obtener préstamos activos
     * GET /api/v1/loans/active
     */
    @GetMapping("/active")
    public ResponseEntity<List<LoanEntity>> getActiveLoans() {
        return ResponseEntity.ok(loanService.getActiveLoans());
    }

    /**
     * Obtener préstamos de un cliente
     * GET /api/v1/loans/client/{clientId}
     */
    @GetMapping("/client/{clientId}")
    public ResponseEntity<List<LoanEntity>> getLoansByClient(@PathVariable Long clientId) {
        return ResponseEntity.ok(loanService.getLoansByClient(clientId));
    }
}
