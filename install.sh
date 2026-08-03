#!/bin/bash

set -e

REPO="https://raw.githubusercontent.com/ManuA323/calculadorHorasTerminal/main"

echo "Descargando calculador..."

sudo curl -fsSL "$REPO/trabajo.awk" -o /usr/local/bin/trabajo

sudo chmod +x /usr/local/bin/trabajo

echo
echo "Instalado correctamente."
echo
echo "Usá:"
echo
echo "    trabajo"