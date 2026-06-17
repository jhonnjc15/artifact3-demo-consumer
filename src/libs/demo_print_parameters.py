"""Glue Job demo: imprime parámetros y una tabla creada en memoria.

Este script es intencionalmente simple para probar el flujo del Artefacto 3.
No requiere PySpark ni archivos externos de configuración.
"""

from __future__ import annotations

import sys
from typing import Dict, List


def parse_glue_arguments(argv: List[str]) -> Dict[str, str]:
    """Parsea argumentos estilo Glue: --clave valor o --clave=valor."""
    parsed: Dict[str, str] = {}
    index = 0

    while index < len(argv):
        token = argv[index]

        if not token.startswith("--"):
            index += 1
            continue

        clean_token = token[2:]

        if "=" in clean_token:
            key, value = clean_token.split("=", 1)
            parsed[key] = value
            index += 1
            continue

        key = clean_token
        next_index = index + 1

        if next_index < len(argv) and not argv[next_index].startswith("--"):
            parsed[key] = argv[next_index]
            index += 2
        else:
            parsed[key] = "true"
            index += 1

    return parsed


def print_table(rows: List[Dict[str, object]]) -> None:
    """Imprime una tabla simple sin depender de librerías externas."""
    if not rows:
        print("Tabla vacía")
        return

    headers = list(rows[0].keys())
    widths = {
        header: max(len(str(header)), *(len(str(row.get(header, ""))) for row in rows))
        for header in headers
    }

    separator = "+" + "+".join("-" * (widths[header] + 2) for header in headers) + "+"
    header_line = "|" + "|".join(f" {header:<{widths[header]}} " for header in headers) + "|"

    print(separator)
    print(header_line)
    print(separator)

    for row in rows:
        print("|" + "|".join(f" {str(row.get(header, '')):<{widths[header]}} " for header in headers) + "|")

    print(separator)


def main() -> None:
    args = parse_glue_arguments(sys.argv[1:])

    job_name = args.get("JOB_NAME", "glue-demo-print-parameters-local")
    demo_env = args.get("demo_env", "local")
    demo_owner = args.get("demo_owner", "data-engineering")
    demo_table = args.get("demo_table", "tabla_demo")

    print("=" * 80)
    print(f"Iniciando Glue Job demo: {job_name}")
    print("=" * 80)

    print("\nParámetros recibidos:")
    if args:
        for key in sorted(args):
            print(f"- {key}: {args[key]}")
    else:
        print("- No se recibieron parámetros")

    rows = [
        {"id": 1, "ambiente": demo_env, "owner": demo_owner, "tabla": demo_table, "estado": "creado"},
        {"id": 2, "ambiente": demo_env, "owner": demo_owner, "tabla": demo_table, "estado": "validado"},
        {"id": 3, "ambiente": demo_env, "owner": demo_owner, "tabla": demo_table, "estado": "impreso"},
    ]

    print("\nTabla demo creada en memoria:")
    print_table(rows)

    print("\nGlue Job demo finalizado correctamente!")


if __name__ == "__main__":
    main()
