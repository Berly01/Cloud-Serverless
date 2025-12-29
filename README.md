# BPM Monitoring - Infraestructura Serverless

Sistema de monitoreo de frecuencia cardíaca (BPM) en tiempo real utilizando arquitectura serverless en AWS, desplegado con OpenTofu.


## Arquitectura

<img width="1536" height="684" alt="762c903d-bb5d-4de8-bf1b-575c961f5b7d" src="https://github.com/user-attachments/assets/a3af3b36-ae18-4390-80e0-bfe6d5803530" />

## Descripción

Esta infraestructura implementa un sistema completo de IoT para monitoreo de salud cardíaca, procesando datos de dispositivos en tiempo real, almacenándolos para análisis histórico y generando alertas automáticas cuando se detectan valores anormales.

## Servicios AWS Utilizados

| Servicio | Propósito |
|----------|-----------|
| **AWS IoT Core** | Ingesta de datos MQTT desde dispositivos |
| **AWS Lambda** | Procesamiento serverless de mediciones y API REST |
| **Amazon DynamoDB** | Almacenamiento NoSQL para datos en tiempo real |
| **Amazon S3** | Almacenamiento histórico y hosting del dashboard |
| **Amazon SNS** | Notificaciones y alertas por email/SMS |
| **Amazon Cognito** | Autenticación y autorización de usuarios |
| **Amazon API Gateway** | API REST para el dashboard |
| **Amazon CloudFront** | CDN para distribución del dashboard |
| **Amazon CloudWatch** | Monitoreo y logs |

## Estructura del Proyecto

```
infrastructure/
├── main.tf                 # Configuración principal y módulos
├── variables.tf            # Variables de entrada
├── outputs.tf              # Outputs de la infraestructura
├── providers.tf            # Configuración de providers
├── terraform.tfvars        # Valores de variables (no commitear)
│
└── modules/
    ├── cognito/            # User Pool y App Client
    ├── dynamodb/           # Tablas para mediciones y dispositivos
    ├── s3/                 # Buckets para datos históricos
    ├── sns/                # Topics para alertas
    ├── lambda/             # Funciones de procesamiento y API
    │   └── src/
    │       ├── bpm_processor.py    # Procesador de mediciones IoT
    │       └── api_handler.py      # Manejador de API REST
    ├── iot_core/           # Things, políticas y reglas IoT
    ├── api_gateway/        # API REST con CORS
    └── dashboard/          # CloudFront + S3 para SPA
```

## Requisitos Previos

- [OpenTofu](https://opentofu.org/) >= 1.6.0 (o Terraform >= 1.0)
- [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales
- Python 3.11+ (para desarrollo de Lambdas)
- Node.js 18+ (para el dashboard)

## Despliegue

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/bpm-monitoring.git
cd bpm-monitoring/infrastructure
```

### 2. Configurar variables

Crear archivo `terraform.tfvars`:

```hcl
aws_region   = "us-east-1"
environment  = "dev"
project_name = "bpm-monitoring"

# Umbrales de BPM
bpm_critical_low  = 40
bpm_warning_low   = 50
bpm_warning_high  = 100
bpm_critical_high = 150
```

### 3. Inicializar y desplegar

```bash
# Inicializar OpenTofu
tofu init

# Ver plan de cambios
tofu plan

# Aplicar infraestructura
tofu apply
```

### 4. Outputs importantes

```bash
tofu output

# Outputs principales:
# - api_gateway_url: URL de la API REST
# - dashboard_url: URL del dashboard (CloudFront)
# - cognito_user_pool_id: ID del User Pool
# - cognito_client_id: ID del App Client
# - iot_endpoint: Endpoint para dispositivos MQTT
```

## Modelo de Datos

### Tabla: bpm-measurements

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| `user_id` | String (PK) | ID del usuario Cognito |
| `timestamp_device` | String (SK) | Timestamp#DeviceID |
| `bpm` | Number | Valor de frecuencia cardíaca |
| `status` | String | normal, warning, critical |
| `device_id` | String | ID del dispositivo |
| `ttl` | Number | TTL para expiración (90 días) |

### Tabla: bpm-devices

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| `device_id` | String (PK) | ID único del dispositivo |
| `user_id` | String | ID del usuario propietario |
| `device_name` | String | Nombre descriptivo |
| `status` | String | active, inactive |

## Seguridad

- **Cognito**: Autenticación JWT con grupos (patients, doctors, administrators)
- **IoT Core**: Políticas por dispositivo con certificados X.509
- **API Gateway**: Autorización via Cognito User Pool
- **S3**: Buckets privados con políticas restrictivas
- **SNS**: Encriptación con KMS

## API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/bpm/current` | Última medición del usuario |
| GET | `/bpm/history` | Historial de mediciones |
| GET | `/bpm/statistics` | Estadísticas (min, max, avg) |
| GET | `/devices` | Lista de dispositivos del usuario |
| GET | `/user/profile` | Perfil del usuario |

## Sistema de Alertas

| Nivel | Condición | Acción |
|-------|-----------|--------|
| **Critical** | BPM ≤ 40 o BPM ≥ 150 | Email inmediato vía SNS |
| **Warning** | BPM 41-50 o BPM 100-149 | Email de advertencia vía SNS |
| **Normal** | BPM 51-99 | Solo almacenamiento |

## Configuración de Dispositivos IoT

### Crear nuevo dispositivo con usuario

```powershell
cd simulator
.\setup-iot-device.ps1 -ThingName "bpm-device-001" -UserEmail "usuario@ejemplo.com"
```

### Usar dispositivo con usuario existente

```powershell
.\setup-iot-device.ps1 -ThingName "bpm-device-002" -ExistingUserId "uuid-del-usuario"
```

El script automáticamente:
1. Crea usuario en Cognito
2. Crea Thing en IoT Core
3. Genera certificados X.509
4. Adjunta políticas de seguridad
5. Registra dispositivo en DynamoDB
6. Suscribe al usuario a alertas SNS

## Monitoreo

Los logs están disponibles en CloudWatch:

- `/aws/lambda/bpm-monitoring-{env}-bpm-processor`
- `/aws/lambda/bpm-monitoring-{env}-api-handler`

## Limpieza

```bash
tofu destroy
```
