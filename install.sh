#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/ManuA323/calculadorHorasTerminal/main"

# Detectar el usuario real si se usó sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

# Detectar dinámicamente si el escritorio se llama "Escritorio" o "Desktop"
if [ -d "$REAL_HOME/Escritorio" ]; then
    DESKTOP_DIR="$REAL_HOME/Escritorio"
elif [ -d "$REAL_HOME/Desktop" ]; then
    DESKTOP_DIR="$REAL_HOME/Desktop"
else
    DESKTOP_DIR="$REAL_HOME"
fi

echo "Instalando calculador para el usuario: $REAL_USER..."

# 1. Crear directorio de librerías del sistema
sudo mkdir -p /usr/local/lib

# 2. Descargar script AWK
sudo curl -fsSL "$REPO/trabajo.awk" -o /usr/local/lib/trabajo.awk
sudo chmod +x /usr/local/lib/trabajo.awk

# 3. Descargar ejecutable bash
sudo curl -fsSL "$REPO/horas" -o /usr/local/bin/horas
sudo chmod +x /usr/local/bin/horas

# 4. Descargar desinstalador global
sudo curl -fsSL "$REPO/uninstall.sh" -o /usr/local/bin/desinstalar-horas
sudo chmod +x /usr/local/bin/desinstalar-horas

# 5. Crear directorio global para los datos con acceso total
sudo mkdir -p /var/lib/horas
sudo chmod 777 /var/lib/horas

if [ -f /var/lib/horas/registro_horas.csv ]; then
    sudo chmod 666 /var/lib/horas/registro_horas.csv
fi

# 6. Dar permisos para leer journalctl sin sudo
echo "Configurando permisos de journalctl..."
sudo usermod -aG systemd-journal "$REAL_USER"
sudo systemctl restart systemd-journald

echo
echo "Instalación completa."
echo "Comandos disponibles:"
echo " - 'horas' para calcular jornada."
echo " - 'horas -e' para exportar al escritorio."
echo " - 'horas -c' para ver el contenido del CSV."
echo " - 'desinstalar-horas' para remover la herramienta del sistema."