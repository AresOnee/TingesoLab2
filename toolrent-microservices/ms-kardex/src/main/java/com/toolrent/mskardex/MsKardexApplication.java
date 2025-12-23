package com.toolrent.mskardex;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class MsKardexApplication {

    public static void main(String[] args) {
        SpringApplication.run(MsKardexApplication.class, args);
    }
}
