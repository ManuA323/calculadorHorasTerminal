#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/ManuA323/calculadorHorasTerminal/main"

# Detectar el usuario real que lanzó la instalación (incluso si usó sudo)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

echo "Instalando calculador para el usuario: $REAL_USER..."

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

# Crear directorio global para los datos y dar propiedad y permisos totales
sudo mkdir -p /var/lib/horas
sudo chmod 777 /var/lib/horas

# Si ya existe un CSV previo, asegurar permisos de lectura y escritura universales
if [ -f /var/lib/horas/registro_horas.csv ]; then
    sudo chmod 666 /var/lib/horas/registro_horas.csv
fi

# Detectar la carpeta de Escritorio real del usuario y asegurar permisos de escritura
DESK_DIR=""
if [ -d "$REAL_HOME/Escritorio" ]; then
    DESK_DIR="$REAL_HOME/Escritorio"
elif [ -d "$REAL_HOME/Desktop" ]; then
    DESK_DIR="$REAL_HOME/Desktop"
fi

if [ -n "$DESK_DIR" ]; then
    sudo chown -R "$REAL_USER:$REAL_USER" "$DESK_DIR"
    sudo chmod u+rwx "$DESK_DIR"
fi

echo
echo "Instalación completa."
echo "Ejecutá el comando \"horas\" para calcular tus horas de trabajo."