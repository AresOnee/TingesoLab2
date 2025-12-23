package com.toolrent.msreports.service;

import com.toolrent.msreports.dto.ClientDTO;
import com.toolrent.msreports.dto.LoanDTO;
import com.toolrent.msreports.dto.ToolRankingDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class ReportService {

    private static final Logger log = LoggerFactory.getLogger(ReportService.class);

    @Autowired
    private RestTemplate restTemplate;

    private static final String MS_LOANS_URL = "http://ms-loans";
    private static final String MS_CLIENTS_URL = "http://ms-clients";

    /**
     * RF6.1: Obtener préstamos activos
     */
    public List<LoanDTO> getActiveLoans() {
        try {
            String url = MS_LOANS_URL + "/api/v1/loans/active";
            ResponseEntity<List<LoanDTO>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<LoanDTO>>() {}
            );
            return response.getBody() != null ? response.getBody() : new ArrayList<>();
        } catch (Exception e) {
            log.error("Error al obtener préstamos activos: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * RF6.2: Obtener clientes con atrasos
     */
    public List<ClientDTO> getClientsWithOverdues() {
        try {
            // Obtener préstamos activos
            List<LoanDTO> activeLoans = getActiveLoans();

            // Filtrar los atrasados y obtener IDs de clientes únicos
            Set<Long> clientIdsWithOverdues = activeLoans.stream()
                    .filter(loan -> "ATRASADO".equalsIgnoreCase(loan.getStatus()))
                    .map(LoanDTO::getClientId)
                    .collect(Collectors.toSet());

            // Obtener información de cada cliente
            List<ClientDTO> clients = new ArrayList<>();
            for (Long clientId : clientIdsWithOverdues) {
                try {
                    String url = MS_CLIENTS_URL + "/api/v1/clients/" + clientId;
                    ClientDTO client = restTemplate.getForObject(url, ClientDTO.class);
                    if (client != null) {
                        clients.add(client);
                    }
                } catch (Exception e) {
                    log.warn("Error al obtener cliente {}: {}", clientId, e.getMessage());
                }
            }

            return clients;
        } catch (Exception e) {
            log.error("Error al obtener clientes con atrasos: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * RF6.3: Obtener ranking de herramientas más prestadas
     */
    public List<ToolRankingDTO> getMostLoanedTools(int limit) {
        try {
            // Obtener todos los préstamos
            String url = MS_LOANS_URL + "/api/v1/loans/";
            ResponseEntity<List<LoanDTO>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<LoanDTO>>() {}
            );

            List<LoanDTO> allLoans = response.getBody() != null ? response.getBody() : new ArrayList<>();

            // Contar préstamos por herramienta
            Map<Long, ToolRankingDTO> toolCounts = new HashMap<>();

            for (LoanDTO loan : allLoans) {
                Long toolId = loan.getToolId();
                String toolName = loan.getToolName();

                if (toolCounts.containsKey(toolId)) {
                    ToolRankingDTO ranking = toolCounts.get(toolId);
                    ranking.setLoanCount(ranking.getLoanCount() + 1);
                } else {
                    toolCounts.put(toolId, new ToolRankingDTO(toolId, toolName, 1L));
                }
            }

            // Ordenar por cantidad de préstamos y limitar
            return toolCounts.values().stream()
                    .sorted((a, b) -> Long.compare(b.getLoanCount(), a.getLoanCount()))
                    .limit(limit)
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Error al obtener ranking de herramientas: {}", e.getMessage());
            return new ArrayList<>();
        }
    }
}
