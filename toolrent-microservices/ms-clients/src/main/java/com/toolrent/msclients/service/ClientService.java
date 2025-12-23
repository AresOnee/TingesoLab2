package com.toolrent.msclients.service;

import com.toolrent.msclients.entity.ClientEntity;
import com.toolrent.msclients.repository.ClientRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@Transactional
public class ClientService {

    @Autowired
    private ClientRepository clientRepository;

    /**
     * Obtener todos los clientes
     */
    public List<ClientEntity> getAllClients() {
        return clientRepository.findAll();
    }

    /**
     * Obtener cliente por ID
     */
    public ClientEntity getClientById(Long id) {
        return clientRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        String.format("Cliente con ID %d no encontrado", id)));
    }

    /**
     * Obtener cliente por RUT
     */
    public ClientEntity getClientByRut(String rut) {
        return clientRepository.findByRut(rut)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        String.format("Cliente con RUT %s no encontrado", rut)));
    }

    /**
     * RF3.1: Crear nuevo cliente
     */
    public ClientEntity createClient(ClientEntity client) {
        // Validar RUT único
        if (clientRepository.existsByRut(client.getRut())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Ya existe un cliente con ese RUT");
        }

        // Validar email único
        if (client.getEmail() != null && clientRepository.existsByEmail(client.getEmail())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Ya existe un cliente con ese email");
        }

        // Estado por defecto: Activo
        if (client.getState() == null || client.getState().isBlank()) {
            client.setState("Activo");
        }

        return clientRepository.save(client);
    }

    /**
     * Actualizar cliente
     */
    public ClientEntity updateClient(Long id, ClientEntity clientDetails) {
        ClientEntity client = getClientById(id);

        if (clientDetails.getName() != null && !clientDetails.getName().isBlank()) {
            client.setName(clientDetails.getName());
        }

        if (clientDetails.getPhone() != null) {
            client.setPhone(clientDetails.getPhone());
        }

        if (clientDetails.getEmail() != null) {
            // Validar email único si se está cambiando
            if (!clientDetails.getEmail().equals(client.getEmail()) &&
                    clientRepository.existsByEmail(clientDetails.getEmail())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Ya existe un cliente con ese email");
            }
            client.setEmail(clientDetails.getEmail());
        }

        return clientRepository.save(client);
    }

    /**
     * RF3.2: Actualizar estado del cliente
     */
    public ClientEntity updateState(Long id, String newState) {
        if (!newState.equals("Activo") && !newState.equals("Restringido")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Estado inválido. Valores permitidos: Activo, Restringido");
        }

        ClientEntity client = getClientById(id);
        client.setState(newState);
        return clientRepository.save(client);
    }

    /**
     * Obtener clientes por estado
     */
    public List<ClientEntity> getClientsByState(String state) {
        return clientRepository.findByState(state);
    }

    /**
     * Eliminar cliente
     */
    public void deleteClient(Long id) {
        ClientEntity client = getClientById(id);
        clientRepository.delete(client);
    }

    /**
     * Verificar si un cliente puede realizar préstamos
     */
    public boolean canClientBorrow(Long id) {
        ClientEntity client = getClientById(id);
        return "Activo".equalsIgnoreCase(client.getState());
    }
}
