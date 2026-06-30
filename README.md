# artifact3-demo-consumer

Repositorio consumidor para probar el Artefacto 3 con GitHub Actions.

Guia funcional detallada: [`DOCUMENTO_FUNCIONAL.md`](DOCUMENTO_FUNCIONAL.md).

Esta version es simple a proposito:

- Ejecuta validaciones pre-deploy reutilizables desde `artifact3-terraform-templates`.
- No tiene archivo de configuración JSON del job.
- No tiene carpeta `examples`.
- El Glue Job demo solo imprime los parámetros recibidos y una tabla creada en memoria.
- El `deploy.json` define Glue Jobs, tablas Athena y Lambdas de ejemplo.
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
└── src/
    ├── libs/demo_print_parameters.py
    ├── lambda/main.py
    └── sql/ybwds_copa_brz/create_table.sql
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

### 3. Configurar secrets para Terraform

En el repo consumidor, configura estos Secrets en GitHub Environment `dev`:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION        = us-east-1
TF_STATE_BUCKET   = <bucket-state-terraform>
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

El workflow usa backend S3 parcial y guarda el state en:

```text
state/artifact3-demo-consumer/terraform.tfstate
```

Antes de `terraform init`, el workflow ejecuta las validaciones reutilizables del
repo de templates:

```text
../artifact3-terraform-templates/modules/glue_job/validations/validate.sh
../artifact3-terraform-templates/modules/lambda/validations/validate.sh
```

El Glue Job demo mantiene un modo local simple, pero incluye una funcion con la
estructura minima de Glue (`GlueContext`, lectura, escritura y `try/except`) para
pasar las validaciones pre-deploy.

El `deploy.json` ya no define un ambiente global. Terraform usa `var.environment`
con default `dev` para filtrar componentes mediante `enabled_environments`,
seleccionar `environment_values.dev`, separar state y etiquetar recursos. Como
cada ambiente vive en una cuenta AWS distinta, los nombres fisicos no llevan
sufijo de ambiente: `glue-demo-print-parameters`, `db_demo` y `lambda-demo`.

El bloque `databases` declara las Glue Databases una sola vez. Una tabla Athena
referencia una database mediante `database_key`; si `mode = "existing"`,
Terraform no intenta crear la database y solo crea la tabla.

## Relacion Glue Job - Athena

Un Glue Job puede declarar que produce datos para una tabla Athena usando
`athena_table_key`:

```json
{
  "databases": {
    "ventas": {
      "enabled": true,
      "enabled_environments": ["dev"],
      "name": "db_ventas",
      "mode": "existing"
    }
  },
  "glue_jobs": {
    "transform_ventas": {
      "enabled": true,
      "enabled_environments": ["dev"],
      "job_name": "glue-transform-ventas",
      "script_local_path": "./src/libs/transform_ventas.py",
      "athena_table_key": "ventas_transformadas"
    }
  },
  "athena": {
    "ventas_transformadas": {
      "enabled": true,
      "enabled_environments": ["dev"],
      "sql_path": "./src/sql/create_table_ventas.sql",
      "database_key": "ventas",
      "table_name": "ventas_transformadas",
      "environment_values": {
        "dev": {
          "s3_location": "s3://bucket/output/ventas/"
        }
      }
    }
  }
}
```

Terraform mantiene los modulos separados: `glue_job` crea el job y `athena`
crea la tabla. `athena_table_key` es una relacion logica; no modifica los
`default_arguments` del Glue Job.

## Trazabilidad

Los recursos reciben tags comunes desde Terraform:

```text
environment = dev
managed_by  = terraform
github_repo = <owner>/artifact3-demo-consumer
```

`github_repo` permite identificar que repositorio consumer creo los recursos.
