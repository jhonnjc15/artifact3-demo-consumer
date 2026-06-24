# artifact3-demo-consumer

Repositorio consumidor para probar el Artefacto 3 con GitHub Actions.

Esta versión es simple a propósito:

- No tiene validaciones pre-deploy.
- No tiene archivo de configuración JSON del job.
- No tiene carpeta `examples`.
- El Glue Job demo solo imprime los parámetros recibidos y una tabla creada en memoria.
- El `deploy.json` solo define parámetros de despliegue del Glue Job.
- El módulo Terraform central se consume desde el repo `artifact3-terraform-templates`, clonado como carpeta hermana en el workflow.

## Estructura

```text
artifact3-demo-consumer/
├── .github/workflows/
│   ├── local-test.yml
│   └── terraform-dev.yml
├── deploy.json
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars.example
└── src/libs/
    └── demo_print_parameters.py
```

## Qué hace el job demo

El script `src/libs/demo_print_parameters.py`:

1. Lee argumentos estilo Glue/AWS CLI, por ejemplo `--demo_env dev`.
2. Imprime todos los parámetros recibidos.
3. Crea una tabla demo en memoria.
4. Imprime la tabla en formato legible.

No necesita PySpark para esta prueba inicial.

## Prueba local

```bash
python src/libs/demo_print_parameters.py \
  --JOB_NAME glue-demo-print-parameters \
  --demo_env dev \
  --demo_owner data-engineering \
  --demo_table tabla_demo_parametros \
  --TempDir s3://bucket-temporal/temporary/
```

## Prueba con GitHub Actions

### 1. Crear dos repos en GitHub

Sube cada carpeta como un repo separado:

```text
artifact3-terraform-templates
artifact3-demo-consumer
```

### 2. Ejecutar workflow local

En el repo consumidor, ejecuta el workflow:

```text
Local test - Glue demo script
```

Este workflow no usa AWS. Solo prueba que el script imprime parámetros y tabla.

### 3. Configurar variables/secrets para Terraform

En el repo consumidor, configura estos Secrets:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Y estas Variables en GitHub Environment `dev`:

```text
AWS_REGION        = us-east-1
ARTIFACT_BUCKET   = <bucket-donde-subir-script-glue>
TEMP_BUCKET       = <bucket-temporal-glue>
GLUE_ROLE_ARN     = <arn-del-role-de-glue>
LAMBDA_ROLE_ARN   = <arn-del-role-de-lambda>
```

### 4. Ejecutar workflow Terraform

Ejecuta manualmente:

```text
Terraform dev - deploy Glue Job
```

Parámetros:

```text
templates_repository = <owner>/artifact3-terraform-templates
apply = false
```

Primero usa `apply = false` para revisar el plan. Luego usa `apply = true` para crear el Glue Job.

El `deploy.json` ya no define un ambiente global. Terraform usa `var.environment`
con default `dev` para filtrar componentes mediante `enabled_environments`,
seleccionar `environment_values.dev`, separar state y etiquetar recursos. Como
cada ambiente vive en una cuenta AWS distinta, los nombres fisicos no llevan
sufijo de ambiente: `glue-demo-print-parameters`, `db_demo` y `lambda-demo`.
