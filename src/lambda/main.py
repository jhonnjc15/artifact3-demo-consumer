import json


def handler(event: dict, context: object) -> dict:
    print("Evento recibido:", json.dumps(event, indent=2))
    print("Contexto:", context)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Lambda demo ejecutada correctamente",
            "input": event,
        }),
    }
