#!/bin/bash
set -e

echo "Desinstalando calculador de horas..."

# 1. Eliminar archivos del sistema
sudo rm -f /usr/local/bin/horas
sudo rm -f /usr/local/bin/desinstalar-horas
sudo rm -f /usr/local/lib/trabajo.awk

# 2. Eliminar datos guardados
sudo rm -rf /var/lib/horas

echo
echo "Desinstalación completa. Se han removido el comando y sus datos."