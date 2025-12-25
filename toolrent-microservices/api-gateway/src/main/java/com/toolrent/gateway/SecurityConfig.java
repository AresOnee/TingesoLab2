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
import reactor.core.publisher.Mono;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Configuracion de seguridad para el API Gateway.
 * Valida tokens JWT de Keycloak y aplica autorizacion basada en roles.
 *
 * Roles:
 * - ADMIN: Acceso total a todas las operaciones
 * - EMPLEADO: Acceso a prestamos, devoluciones y reportes
 */
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
            // Deshabilitar CSRF para APIs REST (stateless)
            .csrf(csrf -> csrf.disable())

            // Configurar autorizacion de endpoints
            .authorizeExchange(exchanges -> exchanges
                // Endpoints publicos - Health checks y actuator
                .pathMatchers("/actuator/**").permitAll()
                .pathMatchers("/actuator/health/**").permitAll()

                // Endpoints publicos - Consultas GET sin autenticacion
                .pathMatchers(HttpMethod.GET, "/api/v1/tools/**").permitAll()
                .pathMatchers(HttpMethod.GET, "/api/v1/clients/**").permitAll()
                .pathMatchers(HttpMethod.GET, "/api/v1/config/**").permitAll()
                .pathMatchers(HttpMethod.GET, "/api/v1/kardex/**").permitAll()

                // ADMIN ONLY - Operaciones de escritura en herramientas
                .pathMatchers(HttpMethod.POST, "/api/v1/tools/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.PUT, "/api/v1/tools/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.DELETE, "/api/v1/tools/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.PATCH, "/api/v1/tools/**").hasRole("ADMIN")

                // ADMIN ONLY - Operaciones de escritura en clientes
                .pathMatchers(HttpMethod.POST, "/api/v1/clients/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.PUT, "/api/v1/clients/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.DELETE, "/api/v1/clients/**").hasRole("ADMIN")

                // ADMIN ONLY - Configuracion de tarifas
                .pathMatchers(HttpMethod.POST, "/api/v1/config/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.PUT, "/api/v1/config/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.DELETE, "/api/v1/config/**").hasRole("ADMIN")

                // ADMIN + EMPLEADO - Prestamos y devoluciones
                .pathMatchers("/api/v1/loans/**").hasAnyRole("ADMIN", "EMPLEADO")

                // ADMIN + EMPLEADO - Reportes
                .pathMatchers("/api/v1/reports/**").hasAnyRole("ADMIN", "EMPLEADO")

                // ADMIN ONLY - Kardex (operaciones de escritura)
                .pathMatchers(HttpMethod.POST, "/api/v1/kardex/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.PUT, "/api/v1/kardex/**").hasRole("ADMIN")
                .pathMatchers(HttpMethod.DELETE, "/api/v1/kardex/**").hasRole("ADMIN")

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
     * Keycloak almacena los roles en el claim "realm_access.roles" o directamente en "roles".
     */
    @Bean
    public Converter<Jwt, Mono<org.springframework.security.authentication.AbstractAuthenticationToken>> jwtAuthenticationConverter() {
        JwtAuthenticationConverter jwtConverter = new JwtAuthenticationConverter();
        jwtConverter.setJwtGrantedAuthoritiesConverter(new KeycloakRealmRoleConverter());
        return new ReactiveJwtAuthenticationConverterAdapter(jwtConverter);
    }

    /**
     * Convertidor de roles de Keycloak.
     * Extrae los roles del realm desde el JWT y los convierte a GrantedAuthority.
     */
    static class KeycloakRealmRoleConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

        @Override
        @SuppressWarnings("unchecked")
        public Collection<GrantedAuthority> convert(Jwt jwt) {
            // Intentar obtener roles desde realm_access (formato estandar de Keycloak)
            Map<String, Object> realmAccess = jwt.getClaim("realm_access");
            if (realmAccess != null) {
                List<String> roles = (List<String>) realmAccess.get("roles");
                if (roles != null) {
                    return roles.stream()
                        .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                        .collect(Collectors.toList());
                }
            }

            // Intentar obtener roles directamente del claim "roles" (configuracion personalizada)
            List<String> directRoles = jwt.getClaim("roles");
            if (directRoles != null) {
                return directRoles.stream()
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                    .collect(Collectors.toList());
            }

            return Collections.emptyList();
        }
    }
}
