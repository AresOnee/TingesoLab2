package com.toolrent.msloans;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;

@SpringBootApplication
@EnableDiscoveryClient
public class MsLoansApplication {

    public static void main(String[] args) {
        SpringApplication.run(MsLoansApplication.class, args);
    }

    /**
     * RestTemplate con @LoadBalanced para comunicación entre microservicios
     * Permite usar nombres de servicio de Eureka en lugar de URLs
     * Ejemplo: http://ms-tools/api/v1/tools/1
     */
    @Bean
    @LoadBalanced
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
