#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/ManuA323/calculadorHorasTerminal/main"

echo "Instalando calculador..."

# Crear directorio de librerías del sistema
sudo mkdir -p /usr/local/lib

# Descargar script AWK
sudo curl -fsSL "$REPO/trabajo.awk" \
    -o /usr/local/lib/trabajo.awk

sudo chmod +x /usr/local/lib/trabajo.awk

# Descargar ejecutable bash
sudo curl -fsSL "$REPO/horas" \
    -o /usr/local/bin/horas

sudo chmod +x /usr/local/bin/horas

# Crear directorio global para los datos y asignar permisos de lectura/escritura a todos los usuarios
sudo mkdir -p /var/lib/horas
sudo chmod 777 /var/lib/horas

echo
echo "Instalación completa."
echo
echo "Ejecuta el comando \"horas\" para calcular tus horas de trabajo."