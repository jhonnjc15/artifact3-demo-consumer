# Documento Funcional - Artifact 3 Demo Consumer

## Objetivo

`artifact3-demo-consumer` demuestra como un repositorio consumidor usa los modulos de `artifact3-terraform-templates` para desplegar Glue Jobs, tablas Glue/Athena y Lambdas desde un manifest `deploy.json`.

## Rol Del Repo

Este repo representa el patron que puede seguir un Data Engineer o equipo para declarar sus propios componentes sin modificar los templates centrales.

| Responsabilidad | Descripcion |
|---|---|
| Manifest | Declarar jobs, tablas y lambdas en `deploy.json` |
| Codigo | Mantener scripts Glue y codigo Lambda |
| SQL | Mantener DDL de tablas Athena |
| Workflow | Ejecutar validaciones y Terraform en DEV |
| State | Mantener state remoto separado por repo |

## Estructura

```text
artifact3-demo-consumer/
├── deploy.json
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── backend.tf
├── terraform.tfvars.example
├── .github/workflows/
│   ├── local-test.yml
│   └── terraform-dev.yml
└── src/
    ├── libs/demo_print_parameters.py
    ├── lambda/main.py
    └── sql/ybwds_copa_brz/create_table.sql
```

## Componentes Demo

| Componente | Nombre fisico | Funcion |
|---|---|---|
| Glue Job | `glue-demo-print-parameters` | Job demo con estructura minima Glue |
| Athena database | `db_demo` | Database Glue/Athena |
| Athena table | `ybwds_copa_brz` | Tabla demo particionada |
| Lambda | `lambda-demo` | Funcion Lambda demo Python |

No se agregan sufijos `-dev` a los nombres fisicos porque el ambiente se separa por cuenta AWS y bucket de state.

## Manifest deploy.json

`deploy.json` tiene cuatro bloques principales:

| Bloque | Funcion |
|---|---|
| `databases` | Declara Glue Databases como `create` o `existing` |
| `glue_jobs` | Define Glue Jobs |
| `athena` | Define tablas Glue/Athena |
| `lambda` | Define funciones Lambda |

### Databases

La entrada `databases.demo` define:

| Campo | Funcion |
|---|---|
| `enabled` | Activa o desactiva la database para el ambiente |
| `enabled_environments` | Ambientes donde aplica |
| `name` | Nombre fisico de Glue Database, actualmente `db_demo` |
| `mode` | `existing` usa una DB existente; `create` la crea desde Terraform |

### Glue Job

La entrada `glue_jobs.demo_print_parameters` define:

| Campo | Funcion |
|---|---|
| `enabled` | Activa o desactiva el job |
| `enabled_environments` | Ambientes donde aplica |
| `job_name` | Nombre fisico del Glue Job |
| `description` | Descripcion funcional |
| `script_local_path` | Script local que se sube a S3 |
| `glue_version` | Version Glue |
| `python_version` | Version Python para Glue |
| `worker_type` | Tipo de worker |
| `number_of_workers` | Numero de workers |
| `timeout` | Timeout del job |
| `max_retries` | Reintentos |
| `athena_table_key` | Relacion logica con una tabla Athena |
| `validations.enabled` | Control de validaciones pre-deploy |
| `default_arguments` | Argumentos runtime adicionales |

El `main.tf` agrega tambien:

```text
--demo_env = var.environment
```

### Athena

La entrada `athena.ybwds_copa_brz` define:

| Campo | Funcion |
|---|---|
| `enabled` | Activa o desactiva la tabla |
| `enabled_environments` | Ambientes donde aplica |
| `sql_path` | DDL base |
| `database_key` | Referencia a una entrada del bloque `databases` |
| `table_name` | Tabla final |
| `merge_existing` | Control de merge con tabla existente |
| `environment_values.dev.s3_location` | Ruta S3 fisica para DEV |
| `environment_values.dev.parameters` | Parametros adicionales de tabla |

### Lambda

La entrada `lambda.demo` define:

| Campo | Funcion |
|---|---|
| `enabled` | Activa o desactiva la Lambda |
| `enabled_environments` | Ambientes donde aplica |
| `function_name` | Nombre fisico |
| `description` | Descripcion funcional |
| `source_path` | Codigo fuente |
| `handler` | Handler Python |
| `runtime` | Runtime Lambda |
| `timeout` | Timeout explicito |
| `memory_size` | Memoria explicita |

## Relacion Glue Job - Athena

El campo:

```json
"athena_table_key": "ybwds_copa_brz"
```

es una relacion logica entre el Glue Job y la tabla declarada en el bloque `athena`.

Importante:

| Regla | Motivo |
|---|---|
| No modifica `default_arguments` | Evita imponer comportamiento runtime al job |
| No crea automaticamente rutas de salida | Cada job decide su logica |
| Si fuerza orden Terraform | `module.glue_jobs` depende de `module.athena` |

## Terraform main.tf

`main.tf` cumple cuatro funciones:

1. Lee `deploy.json`.
2. Filtra componentes por `enabled` y `enabled_environments`.
3. Normaliza rutas locales a rutas absolutas.
4. Invoca modulos locales de `artifact3-terraform-templates`.

Modulos usados:

| Modulo | Source |
|---|---|
| Glue Job | `../artifact3-terraform-templates/modules/glue_job` |
| Athena | `../artifact3-terraform-templates/modules/athena` |
| Lambda | `../artifact3-terraform-templates/modules/lambda` |

El workflow clona el repo de templates como carpeta hermana para que esos paths existan en CI.

## Workflow DEV

Archivo:

```text
.github/workflows/terraform-dev.yml
```

Ejecucion:

```text
workflow_dispatch
```

Inputs:

| Input | Funcion |
|---|---|
| `templates_repository` | Repo de templates a clonar |
| `apply` | Si es `false`, solo plan. Si es `true`, aplica |

Pasos principales:

| Paso | Funcion |
|---|---|
| Checkout consumer | Descarga este repo |
| Checkout templates | Descarga templates como carpeta hermana |
| Setup Terraform | Instala Terraform 1.6.6 |
| Setup Python | Instala Python 3.11 |
| Install validation tools | Instala `flake8` |
| Validate Glue Jobs | Ejecuta validaciones del modulo Glue |
| Validate Lambdas | Ejecuta validaciones del modulo Lambda |
| Configure AWS credentials | Configura access keys |
| Create dev.auto.tfvars | Genera variables para Terraform |
| Terraform init | Inicializa backend S3 |
| Terraform plan | Genera plan |
| Terraform apply | Aplica si `apply = true` |

## Validaciones Pre-Deploy

Se ejecutan antes de `terraform init`.

### Glue Job

Script:

```text
../artifact3-terraform-templates/modules/glue_job/validations/validate.sh deploy.json dev
```

Valida:

| Validacion | Objetivo |
|---|---|
| Script existe | Evitar jobs sin codigo |
| Sintaxis Python | Detectar errores antes de Terraform |
| flake8 critico | Detectar errores de lint graves |
| `GlueContext` | Forzar estructura Glue minima |
| Lectura y escritura | Evitar scripts incompletos |
| `try/except` | Forzar manejo basico de errores |

### Lambda

Script:

```text
../artifact3-terraform-templates/modules/lambda/validations/validate.sh deploy.json dev
```

Valida:

| Validacion | Objetivo |
|---|---|
| `source_path` existe | Evitar Lambda sin codigo |
| `timeout` explicito | Evitar defaults accidentales |
| `memory_size` explicito | Evitar defaults accidentales |
| Sintaxis/lint | Validar Python o Node |
| Secret scan | Detectar secretos hardcodeados |

## Backend Y State

`backend.tf` declara backend S3 parcial:

```hcl
terraform {
  backend "s3" {
    encrypt = true
  }
}
```

El workflow completa:

```text
bucket = secrets.TF_STATE_BUCKET
region = secrets.AWS_REGION
key    = state/<repo>/terraform.tfstate
```

Para este repo:

```text
state/artifact3-demo-consumer/terraform.tfstate
```

## Secrets Requeridos

Configurar en el GitHub Environment `dev`:

| Secret | Uso |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS |
| `AWS_REGION` | Region AWS |
| `TF_STATE_BUCKET` | Bucket de state Terraform |
| `ARTIFACT_BUCKET` | Bucket para scripts Glue y ZIPs Lambda |
| `TEMP_BUCKET` | Bucket temporal Glue |
| `GLUE_ROLE_ARN` | Role de ejecucion Glue |
| `LAMBDA_ROLE_ARN` | Role de ejecucion Lambda |

## Tags

Tags comunes:

```hcl
environment = var.environment
managed_by  = "terraform"
github_repo = var.github_repository
```

`github_repo` permite identificar que repo consumer creo cada recurso.

## Flujo Para Data Engineers

1. Copiar o crear un repo consumer basado en este patron.
2. Agregar scripts Glue en `src/libs`.
3. Agregar codigo Lambda en `src/lambda` si aplica.
4. Agregar SQL en `src/sql/<tabla>/create_table.sql`.
5. Declarar componentes en `deploy.json`.
6. Configurar secrets del GitHub Environment.
7. Ejecutar workflow con `apply = false`.
8. Revisar plan y validaciones.
9. Ejecutar workflow con `apply = true` despues de aprobacion.

## Pendientes Recomendados

| Prioridad | Punto |
|---|---|
| Alta | Usar tags versionados de templates para consumers productivos |
| Media | Migrar credenciales AWS a OIDC |
| Media | Agregar ejemplos de nuevos jobs/tablas/lambdas |
| Media | Homologar documentacion con otros consumers |
| Baja | Agregar validaciones Athena cuando el modulo las exponga |
