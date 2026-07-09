# -*- coding: utf-8 -*-
"""

Equativ API Reporting Script

Este script SOLO CONSULTA datos. No modifica ni borra nada en Equativ.
Usa POST únicamente para enviar filtros de reporting como fechas, métricas
y dimensiones, y devuelve los datos en un archivo CSV.

Instalación:
    pip install requests

Ejecución:
    python reporte.py

IMPORTANTE:
    No subir credenciales reales a GitHub.
    Reemplazar CLIENT_ID y CLIENT_SECRET por variables de entorno
    o mantenerlos ocultos.
"""

# ------------------------------------------------------------------
# 1) IMPORTAMOS LAS HERRAMIENTAS
# ------------------------------------------------------------------
import csv
import requests
from datetime import datetime, timedelta, timezone


# ------------------------------------------------------------------
# 2) CONFIGURACION
# ------------------------------------------------------------------

# IMPORTANTE: No subir credenciales reales a GitHub.
CLIENT_ID = "*****"
CLIENT_SECRET = "*****"

TOKEN_URL = "https://login.eqtv.io/oauth2/token"
REPORT_URL = "https://demand-api.eqtv.io/report"

# Métricas que queremos consultar:
METRICAS = [
    "buyerSpendEuro",
    "clickRate",
    "clicks",
    "impressions",
    "ecpc",
    "smartGrossECpmEuro",
    "videoComplete",
    "completionRate",
    "viewabilityRate",
    "viewableImpressions"
]

# Dimensiones para agrupar la data:
DIMENSIONES = [
    "countryName",
    "creativeSize",
    "deviceTypeId",
    "deviceTypeName",
    "DspId",
    "DspName",
    "environmentTypeId",
    "environmentTypeName"
]

# Rango dinámico: últimos 30 días.
DIAS_ATRAS = 30

# Archivo de salida.
ARCHIVO_CSV = "reporte_equativ.csv"


# ------------------------------------------------------------------
# 3) FUNCION PARA PEDIR EL TOKEN
# ------------------------------------------------------------------
def obtener_token():
    print("Pidiendo el token de acceso a Equativ...")

    datos = {
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
    }

    respuesta = requests.post(TOKEN_URL, data=datos, timeout=30)
    respuesta.raise_for_status()

    token = respuesta.json()["access_token"]

    print("Token recibido correctamente.")
    return token


# ------------------------------------------------------------------
# 4) FUNCION PARA PEDIR EL REPORTE
# ------------------------------------------------------------------
def obtener_reporte(token):
    # Rango de fechas: desde hace DIAS_ATRAS hasta hoy.
    hoy = datetime.now(timezone.utc).date()
    fecha_inicio = hoy - timedelta(days=DIAS_ATRAS)

    print(f"Pidiendo reporte del {fecha_inicio} al {hoy}...")

    filtros = {
        "startDate": fecha_inicio.strftime("%Y-%m-%d"),
        "endDate": hoy.strftime("%Y-%m-%d"),
        "metrics": METRICAS,
        "dimensions": DIMENSIONES,
    }

    cabeceras = {
        "Authorization": "Bearer " + token,
        "Accept": "application/json",
    }

    respuesta = requests.post(
        REPORT_URL,
        headers=cabeceras,
        json=filtros,
        timeout=90
    )

    respuesta.raise_for_status()

    filas = respuesta.json()

    print("Se recibieron", len(filas), "filas de datos.")
    return filas


# ------------------------------------------------------------------
# 5) FUNCION AUXILIAR: CONVERTIR TIMESTAMP "day" A FECHA LEGIBLE
# ------------------------------------------------------------------
def timestamp_a_fecha(valor):
    try:
        milisegundos = int(valor)
    except (ValueError, TypeError):
        return valor

    fecha = datetime.fromtimestamp(milisegundos / 1000, tz=timezone.utc)
    return fecha.strftime("%Y-%m-%d")


# ------------------------------------------------------------------
# 6) FUNCION PARA GUARDAR EL REPORTE EN CSV
# ------------------------------------------------------------------
def guardar_en_csv(filas, nombre_archivo):
    if not filas:
        print("No hay datos para guardar.")
        return

    def leer(fila, clave):
        if clave in fila:
            return fila[clave]

        clave_baja = clave[0].lower() + clave[1:]
        return fila.get(clave_baja, "")

    columnas = DIMENSIONES + METRICAS

    with open(nombre_archivo, "w", newline="", encoding="utf-8-sig") as f:
        escritor = csv.writer(f)
        escritor.writerow(columnas)

        for fila in filas:
            valores = []

            for columna in columnas:
                dato = leer(fila, columna)

                if columna == "day":
                    dato = timestamp_a_fecha(dato)

                valores.append(dato)

            escritor.writerow(valores)

    print("Datos guardados en el archivo:", nombre_archivo)


# ------------------------------------------------------------------
# 7) PROGRAMA PRINCIPAL
# ------------------------------------------------------------------
if __name__ == "__main__":
    try:
        token = obtener_token()
        filas = obtener_reporte(token)
        guardar_en_csv(filas, ARCHIVO_CSV)

        print("Listo! Reporte descargado con exito.")

    except requests.exceptions.RequestException as error:
        print("Ocurrio un problema al conectar con la API:")
        print(error)

        if error.response is not None:
            print("Detalle:", error.response.text)
