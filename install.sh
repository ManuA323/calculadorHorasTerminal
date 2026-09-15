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
sudo curl --retry 5 --retry-delay 2 --retry-max-time 30 --retry-all-errors \
    -fsSL "$REPO/trabajo.awk" \
    -o /usr/local/lib/trabajo.awk

sudo chmod +x /usr/local/lib/trabajo.awk

# 3. Descargar ejecutable bash
sudo curl --retry 5 --retry-delay 2 --retry-max-time 30 --retry-all-errors \
    -fsSL "$REPO/horas" \
    -o /usr/local/bin/horas

sudo chmod +x /usr/local/bin/horas

# 4. Descargar desinstalador global
sudo curl --retry 5 --retry-delay 2 --retry-max-time 30 --retry-all-errors \
    -fsSL "$REPO/uninstall.sh" \
    -o /usr/local/bin/desinstalar-horas

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

# Configurar ejecución automática de "horas" al iniciar sesión
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
AUTOSTART_DIR="$REAL_HOME/.config/autostart"

mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/horas.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Horas
Comment=Calculador de horas de trabajo
Exec=gnome-terminal -- bash -c "horas; exec bash"
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chown "$REAL_USER:$REAL_USER" "$AUTOSTART_DIR/horas.desktop"

#mensajes de ayuda

echo "Instalación completa."
echo "IMPORTANTE: Para activar los permisos sin reiniciar la PC,"
echo "ejecutá este comando una sola vez en tu terminal:"
echo "   newgrp systemd-journal"
echo
echo "ejecutá horas -help para ver los comandos disponibles."