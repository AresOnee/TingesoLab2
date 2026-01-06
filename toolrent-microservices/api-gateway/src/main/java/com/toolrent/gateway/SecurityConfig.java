package com.toolrent.gateway;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.ReactiveJwtAuthenticationConverterAdapter;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsConfigurationSource;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;
import reactor.core.publisher.Mono;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Configuracion de seguridad para el API Gateway.
 * Valida tokens JWT de Keycloak (sisgr-realm) y aplica autorizacion basada en roles.
 *
 * Roles (igual que backend-toolrent):
 * - ADMIN: Acceso total - crear/modificar herramientas, clientes, configuraciones
 * - USER: Acceso a prestamos, devoluciones, reportes y consultas
 */
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
            // Habilitar CORS con configuracion personalizada
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))

            // Deshabilitar CSRF para APIs REST (stateless)
            .csrf(csrf -> csrf.disable())

            // Configurar autorizacion de endpoints
            .authorizeExchange(exchanges -> exchanges
                // ============ ENDPOINTS PUBLICOS ============
                // Health checks y actuator
                .pathMatchers("/actuator/**").permitAll()
                .pathMatchers("/actuator/health/**").permitAll()

                // Preflight CORS
                .pathMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                // Swagger/OpenAPI (si se usa)
                .pathMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()

                // ============ MS-TOOLS (Herramientas) ============
                // GET: USER y ADMIN pueden consultar
                .pathMatchers(HttpMethod.GET, "/api/v1/tools", "/api/v1/tools/**").hasAnyRole("USER", "ADMIN")
                // POST: Solo ADMIN puede crear herramientas
                .pathMatchers(HttpMethod.POST, "/api/v1/tools", "/api/v1/tools/**").hasRole("ADMIN")
                // PUT: Solo ADMIN puede dar de baja herramientas
                .pathMatchers(HttpMethod.PUT, "/api/v1/tools", "/api/v1/tools/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.PATCH, "/api/v1/tools", "/api/v1/tools/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.DELETE, "/api/v1/tools", "/api/v1/tools/**").hasRole("ADMIN")

                // ============ MS-CLIENTS (Clientes) ============
                // GET: USER y ADMIN pueden consultar
                .pathMatchers(HttpMethod.GET, "/api/v1/clients", "/api/v1/clients/**").hasAnyRole("USER", "ADMIN")
                // POST/PUT: Solo ADMIN puede crear/modificar clientes
                .pathMatchers(HttpMethod.POST, "/api/v1/clients", "/api/v1/clients/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.PUT, "/api/v1/clients", "/api/v1/clients/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.DELETE, "/api/v1/clients", "/api/v1/clients/**").hasRole("ADMIN")

                // ============ MS-CONFIG (Configuraciones/Tarifas) ============
                // GET: USER y ADMIN pueden ver configuraciones (con y sin trailing slash)
                .pathMatchers(HttpMethod.GET, "/api/v1/config", "/api/v1/config/**").hasAnyRole("USER", "ADMIN")
                // PUT: Solo ADMIN puede modificar tarifas
                .pathMatchers(HttpMethod.PUT, "/api/v1/config", "/api/v1/config/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.POST, "/api/v1/config", "/api/v1/config/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.DELETE, "/api/v1/config", "/api/v1/config/**").hasRole("ADMIN")

                // ============ MS-LOANS (Prestamos) ============
                // USER y ADMIN pueden crear prestamos y registrar devoluciones
                .pathMatchers("/api/v1/loans", "/api/v1/loans/**").hasAnyRole("USER", "ADMIN")

                // ============ MS-KARDEX (Movimientos) ============
                // USER y ADMIN pueden consultar kardex (con y sin trailing slash)
                .pathMatchers(HttpMethod.GET, "/api/v1/kardex", "/api/v1/kardex/**").hasAnyRole("USER", "ADMIN")
                // Solo ADMIN puede crear movimientos directamente (normalmente se crean via loans)
                .pathMatchers(HttpMethod.POST, "/api/v1/kardex", "/api/v1/kardex/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.PUT, "/api/v1/kardex", "/api/v1/kardex/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.DELETE, "/api/v1/kardex", "/api/v1/kardex/**").hasRole("ADMIN")

                // ============ MS-REPORTS (Reportes) ============
                // USER y ADMIN pueden ver reportes
                .pathMatchers("/api/v1/reports", "/api/v1/reports/**").hasAnyRole("USER", "ADMIN")

                // Cualquier otra peticion requiere autenticacion
                .anyExchange().authenticated()
            )

            // Configurar OAuth2 Resource Server con JWT
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
            );

        return http.build();
    }

    /**
     * Convertidor de JWT para extraer roles de Keycloak.
     * Extrae roles de realm_access y resource_access (igual que backend-toolrent).
     */
    @Bean
    public Converter<Jwt, Mono<org.springframework.security.authentication.AbstractAuthenticationToken>> jwtAuthenticationConverter() {
        JwtAuthenticationConverter jwtConverter = new JwtAuthenticationConverter();
        jwtConverter.setJwtGrantedAuthoritiesConverter(new KeycloakRoleConverter());
        return new ReactiveJwtAuthenticationConverterAdapter(jwtConverter);
    }

    /**
     * Convertidor de roles de Keycloak.
     * Extrae los roles del realm y del cliente desde el JWT.
     * Compatible con la configuracion de sisgr-realm.
     */
    static class KeycloakRoleConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

        private static final Logger log = LoggerFactory.getLogger(KeycloakRoleConverter.class);

        @Override
        @SuppressWarnings("unchecked")
        public Collection<GrantedAuthority> convert(Jwt jwt) {
            List<GrantedAuthority> authorities = new ArrayList<>();

            log.info("=== JWT ROLE EXTRACTION DEBUG ===");
            log.info("JWT Subject: {}", jwt.getSubject());
            log.info("JWT Claims: {}", jwt.getClaims().keySet());

            // 1. Extraer roles de realm_access.roles (roles globales del realm)
            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
            log.info("realm_access claim: {}", realmAccess);

            if (realmAccess != null && realmAccess.containsKey("roles")) {
                List<String> realmRoles = (List<String>) realmAccess.get("roles");
                log.info("Realm roles found: {}", realmRoles);
                if (realmRoles != null) {
                    authorities.addAll(
                        realmRoles.stream()
                            .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                            .collect(Collectors.toList())
                    );
                }
            }

            // 2. Extraer roles de resource_access.[client].roles (roles del cliente)
            Map<String, Object> resourceAccess = jwt.getClaim("resource_access");
            log.info("resource_access claim: {}", resourceAccess);

            if (resourceAccess != null) {
                // Buscar roles en cualquier cliente configurado
                for (Object clientData : resourceAccess.values()) {
                    if (clientData instanceof Map) {
                        Map<String, Object> clientMap = (Map<String, Object>) clientData;
                        if (clientMap.containsKey("roles")) {
                            List<String> clientRoles = (List<String>) clientMap.get("roles");
                            log.info("Client roles found: {}", clientRoles);
                            if (clientRoles != null) {
                                authorities.addAll(
                                    clientRoles.stream()
                                        .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                                        .collect(Collectors.toList())
                                );
                            }
                        }
                    }
                }
            }

            log.info("Final authorities: {}", authorities);
            log.info("=== END JWT DEBUG ===");

            return authorities;
        }
    }

    /**
     * Configuracion CORS para permitir acceso desde IPs privadas (minikube, etc.)
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // Permitir origenes con patrones (IPs privadas, localhost, etc.)
        configuration.setAllowedOriginPatterns(Arrays.asList(
            "http://localhost:*",
            "http://127.0.0.1:*",
            "http://172.*:*",
            "http://192.168.*:*",
            "http://10.*:*",
            "http://frontend:*"
        ));

        // Metodos HTTP permitidos
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));

        // Headers permitidos
        configuration.setAllowedHeaders(Arrays.asList("*"));

        // Permitir credenciales (cookies, authorization headers)
        configuration.setAllowCredentials(true);

        // Tiempo de cache para preflight
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
