#!/bin/bash
set -e

echo "Desinstalando calculador..."

sudo rm -f /usr/local/bin/trabajo
sudo rm -f /usr/local/lib/trabajo.awk

echo
echo "Desinstalado correctamente."