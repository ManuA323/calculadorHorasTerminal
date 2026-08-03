#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/ManuA323/calculadorHorasTerminal/main"

echo "Descargando calculador..."

sudo mkdir -p /usr/local/lib

sudo curl -fsSL "$REPO/trabajo.awk" -o /usr/local/lib/trabajo.awk
sudo chmod +x /usr/local/lib/trabajo.awk

sudo curl -fsSL "$REPO/trabajo" -o /usr/local/bin/trabajo
sudo chmod +x /usr/local/bin/trabajo

echo
echo "Instalado correctamente."
echo
echo "Usá:"
echo
echo "    trabajo"