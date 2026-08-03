#!/bin/bash
set -e

echo "Eliminando calculador..."

sudo rm -f /usr/local/bin/horas
sudo rm -f /usr/local/lib/trabajo.awk

echo
echo "Desinstalado correctamente."