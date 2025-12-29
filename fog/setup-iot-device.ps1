<#
.SYNOPSIS
    Script para configurar el simulador BPM y crear certificados IoT
.DESCRIPTION
    Este script:
    1. Crea un Thing en AWS IoT Core
    2. Genera certificados
    3. Adjunta la política de seguridad
    4. Descarga el CA root de Amazon
#>

param(
    [string]$ThingName = "bpm-simulator-001",
    [string]$PolicyName = "bpm-monitoring-dev-device-policy",
    [string]$OutputDir = ".\certs"
)

Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Configuracion del Simulador BPM" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

# Crear directorio de certificados
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host " Creado directorio: $OutputDir" -ForegroundColor Green
}

# 1. Crear Thing
Write-Host ""
Write-Host " Creando Thing: $ThingName" -ForegroundColor Yellow
aws iot create-thing --thing-name $ThingName --thing-type-name "bpm-monitoring-dev-bpm-device" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Thing ya existe o error al crear" -ForegroundColor Yellow
} else {
    Write-Host "   Thing creado" -ForegroundColor Green
}

# 2. Crear certificado
Write-Host ""
Write-Host " Creando certificados..." -ForegroundColor Yellow
$certOutput = aws iot create-keys-and-certificate `
    --set-as-active `
    --certificate-pem-outfile "$OutputDir\device.pem.crt" `
    --private-key-outfile "$OutputDir\private.pem.key" `
    --public-key-outfile "$OutputDir\public.pem.key" `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -eq 0) {
    $certificateArn = $certOutput.certificateArn
    $certificateId = $certOutput.certificateId
    Write-Host "   Certificado creado: $certificateId" -ForegroundColor Green
    
    # Guardar ARN para referencia
    $certificateArn | Out-File "$OutputDir\certificate-arn.txt"
} else {
    Write-Host "   Error al crear certificado" -ForegroundColor Red
    exit 1
}

# 3. Adjuntar politica al certificado
Write-Host ""
Write-Host " Adjuntando politica: $PolicyName" -ForegroundColor Yellow
aws iot attach-policy --policy-name $PolicyName --target $certificateArn
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Politica adjuntada" -ForegroundColor Green
} else {
    Write-Host "   Error al adjuntar politica" -ForegroundColor Red
}

# 4. Adjuntar certificado al Thing
Write-Host ""
Write-Host " Adjuntando certificado al Thing" -ForegroundColor Yellow
aws iot attach-thing-principal --thing-name $ThingName --principal $certificateArn
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Certificado adjuntado al Thing" -ForegroundColor Green
} else {
    Write-Host "   Error al adjuntar certificado" -ForegroundColor Red
}

# 5. Descargar CA Root de Amazon
Write-Host ""
Write-Host " Descargando Amazon Root CA..." -ForegroundColor Yellow
$caUrl = "https://www.amazontrust.com/repository/AmazonRootCA1.pem"
Invoke-WebRequest -Uri $caUrl -OutFile "$OutputDir\AmazonRootCA1.pem"
if (Test-Path "$OutputDir\AmazonRootCA1.pem") {
    Write-Host "  CA Root descargado" -ForegroundColor Green
} else {
    Write-Host "  Error al descargar CA" -ForegroundColor Red
}

# 6. Obtener endpoint
Write-Host ""
Write-Host " Obteniendo IoT Endpoint..." -ForegroundColor Yellow
$endpoint = aws iot describe-endpoint --endpoint-type iot:Data-ATS --query 'endpointAddress' --output text
Write-Host "   Endpoint: $endpoint" -ForegroundColor Cyan

# Resumen
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "CONFIGURACION COMPLETADA" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host ""
Write-Host "Archivos creados en ${OutputDir}:"
Write-Host "  device.pem.crt    - Certificado del dispositivo"
Write-Host "  private.pem.key   - Clave privada"
Write-Host "  public.pem.key    - Clave publica"
Write-Host "  AmazonRootCA1.pem - CA Root de Amazon"
Write-Host ""
Write-Host "Para ejecutar el simulador:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  cd simulator"
Write-Host "  pip install -r requirements.txt"
$cmd = "  python bpm_simulator.py --endpoint $endpoint --cert certs/device.pem.crt --key certs/private.pem.key --root-ca certs/AmazonRootCA1.pem --user-id test_user_001 --device-id simulator_001 --interval 5"
Write-Host $cmd
Write-Host ""
