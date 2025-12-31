# =====================================================
# SCRIPT: Export Keycloak Realm Configuration (PowerShell)
# =====================================================
# Exporta la configuración completa del realm sisgr-realm
# incluyendo usuarios, roles, clients y configuraciones
# =====================================================

param(
    [string]$MinikubeIP = "",
    [string]$Namespace = "toolrent",
    [string]$RealmName = "sisgr-realm",
    [string]$KeycloakPort = "30090",
    [string]$AdminUser = "admin",
    [string]$AdminPassword = "admin"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Keycloak Realm Export Tool (PowerShell)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Obtener IP de Minikube si no se proporciona
if ([string]::IsNullOrEmpty($MinikubeIP)) {
    try {
        $MinikubeIP = (minikube ip 2>$null).Trim()
        Write-Host "[OK] Minikube IP: $MinikubeIP" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] No se pudo obtener la IP de minikube" -ForegroundColor Red
        Write-Host "        Usa: .\export-keycloak.ps1 -MinikubeIP <IP>" -ForegroundColor Yellow
        exit 1
    }
}

$KeycloakUrl = "http://${MinikubeIP}:${KeycloakPort}"
Write-Host "[INFO] Keycloak URL: $KeycloakUrl" -ForegroundColor Gray

# Crear directorio de salida
$OutputDir = ".\keycloak-export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Write-Host "[OK] Directorio creado: $OutputDir" -ForegroundColor Green

# Obtener token de admin
Write-Host "`n[1/5] Obteniendo token de administrador..." -ForegroundColor Yellow
try {
    $tokenResponse = Invoke-RestMethod -Method Post `
        -Uri "$KeycloakUrl/realms/master/protocol/openid-connect/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            username = $AdminUser
            password = $AdminPassword
            grant_type = "password"
            client_id = "admin-cli"
        }
    $TOKEN = $tokenResponse.access_token
    Write-Host "      Token obtenido correctamente" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] No se pudo obtener el token: $_" -ForegroundColor Red
    exit 1
}

$headers = @{ Authorization = "Bearer $TOKEN" }

# Exportar realm
Write-Host "[2/5] Exportando configuracion del realm..." -ForegroundColor Yellow
try {
    $realmConfig = Invoke-RestMethod -Method Get `
        -Uri "$KeycloakUrl/admin/realms/$RealmName" `
        -Headers $headers
    $realmConfig | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputDir\realm-config.json" -Encoding UTF8
    Write-Host "      realm-config.json exportado" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Error exportando realm: $_" -ForegroundColor Red
}

# Exportar usuarios
Write-Host "[3/5] Exportando usuarios..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Method Get `
        -Uri "$KeycloakUrl/admin/realms/$RealmName/users?max=1000" `
        -Headers $headers
    $users | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputDir\realm-users.json" -Encoding UTF8
    Write-Host "      realm-users.json exportado ($($users.Count) usuarios)" -ForegroundColor Green

    # Mostrar usuarios encontrados
    foreach ($user in $users) {
        Write-Host "        - $($user.username) ($($user.email))" -ForegroundColor Gray
    }
} catch {
    Write-Host "[ERROR] Error exportando usuarios: $_" -ForegroundColor Red
}

# Exportar clients
Write-Host "[4/5] Exportando clients..." -ForegroundColor Yellow
try {
    $clients = Invoke-RestMethod -Method Get `
        -Uri "$KeycloakUrl/admin/realms/$RealmName/clients" `
        -Headers $headers
    $clients | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputDir\realm-clients.json" -Encoding UTF8

    # Filtrar solo clients personalizados (no los de sistema)
    $customClients = $clients | Where-Object { $_.clientId -notlike "account*" -and $_.clientId -notlike "admin-cli" -and $_.clientId -notlike "broker" -and $_.clientId -notlike "realm-management" -and $_.clientId -notlike "security-admin-console" }
    Write-Host "      realm-clients.json exportado ($($customClients.Count) clients personalizados)" -ForegroundColor Green
    foreach ($client in $customClients) {
        Write-Host "        - $($client.clientId)" -ForegroundColor Gray
    }
} catch {
    Write-Host "[ERROR] Error exportando clients: $_" -ForegroundColor Red
}

# Exportar roles
Write-Host "[5/5] Exportando roles..." -ForegroundColor Yellow
try {
    $roles = Invoke-RestMethod -Method Get `
        -Uri "$KeycloakUrl/admin/realms/$RealmName/roles" `
        -Headers $headers
    $roles | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputDir\realm-roles.json" -Encoding UTF8

    # Filtrar roles personalizados
    $customRoles = $roles | Where-Object { $_.name -notlike "uma_authorization" -and $_.name -notlike "offline_access" -and $_.name -notlike "default-roles*" }
    Write-Host "      realm-roles.json exportado ($($customRoles.Count) roles personalizados)" -ForegroundColor Green
    foreach ($role in $customRoles) {
        Write-Host "        - $($role.name): $($role.description)" -ForegroundColor Gray
    }
} catch {
    Write-Host "[ERROR] Error exportando roles: $_" -ForegroundColor Red
}

# Crear archivo combinado para import
Write-Host "`n[EXTRA] Creando archivo combinado para import..." -ForegroundColor Yellow
try {
    # Leer archivos exportados
    $realmJson = Get-Content "$OutputDir\realm-config.json" -Raw | ConvertFrom-Json
    $usersJson = Get-Content "$OutputDir\realm-users.json" -Raw | ConvertFrom-Json
    $clientsJson = Get-Content "$OutputDir\realm-clients.json" -Raw | ConvertFrom-Json
    $rolesJson = Get-Content "$OutputDir\realm-roles.json" -Raw | ConvertFrom-Json

    # Agregar usuarios al realm (con credenciales placeholder)
    $usersForImport = @()
    foreach ($user in $usersJson) {
        $userForImport = @{
            username = $user.username
            enabled = $user.enabled
            emailVerified = $user.emailVerified
            firstName = $user.firstName
            lastName = $user.lastName
            email = $user.email
            credentials = @(
                @{
                    type = "password"
                    value = "$($user.username)123"  # Password por defecto
                    temporary = $false
                }
            )
            realmRoles = @()
        }

        # Obtener roles del usuario
        try {
            $userRoles = Invoke-RestMethod -Method Get `
                -Uri "$KeycloakUrl/admin/realms/$RealmName/users/$($user.id)/role-mappings/realm" `
                -Headers $headers
            $userForImport.realmRoles = @($userRoles | ForEach-Object { $_.name })
        } catch {}

        $usersForImport += $userForImport
    }

    # Crear objeto de import completo
    $importObject = @{
        realm = $RealmName
        enabled = $true
        sslRequired = "external"
        registrationAllowed = $false
        loginWithEmailAllowed = $true
        duplicateEmailsAllowed = $false
        resetPasswordAllowed = $false
        editUsernameAllowed = $false
        bruteForceProtected = $false
        roles = @{
            realm = @($rolesJson | Where-Object { $_.name -eq "ADMIN" -or $_.name -eq "USER" } | ForEach-Object {
                @{
                    name = $_.name
                    description = $_.description
                }
            })
        }
        users = $usersForImport
        clients = @($clientsJson | Where-Object { $_.clientId -like "sisgr-*" } | ForEach-Object {
            @{
                clientId = $_.clientId
                name = $_.name
                enabled = $_.enabled
                publicClient = $_.publicClient
                directAccessGrantsEnabled = $_.directAccessGrantsEnabled
                standardFlowEnabled = $_.standardFlowEnabled
                implicitFlowEnabled = $_.implicitFlowEnabled
                bearerOnly = $_.bearerOnly
                redirectUris = $_.redirectUris
                webOrigins = $_.webOrigins
                protocol = $_.protocol
            }
        })
    }

    $importObject | ConvertTo-Json -Depth 100 | Out-File -FilePath "$OutputDir\sisgr-realm-import.json" -Encoding UTF8
    Write-Host "      sisgr-realm-import.json creado" -ForegroundColor Green
} catch {
    Write-Host "[WARN] No se pudo crear archivo combinado: $_" -ForegroundColor Yellow
}

# Resumen
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  EXPORTACION COMPLETADA" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "`nArchivos generados en: $OutputDir" -ForegroundColor White
Get-ChildItem $OutputDir | ForEach-Object {
    $size = "{0:N2} KB" -f ($_.Length / 1KB)
    Write-Host "  - $($_.Name) ($size)" -ForegroundColor Gray
}

Write-Host "`n[IMPORTANTE] Para usar esta configuracion:" -ForegroundColor Yellow
Write-Host "  1. Revisa sisgr-realm-import.json" -ForegroundColor White
Write-Host "  2. Modifica los passwords (actualmente: <username>123)" -ForegroundColor White
Write-Host "  3. Copia el contenido al ConfigMap de Kubernetes" -ForegroundColor White
Write-Host "  4. kubectl apply -f keycloak-realm-configmap.yaml" -ForegroundColor White
Write-Host "  5. kubectl rollout restart deployment/keycloak -n toolrent" -ForegroundColor White
