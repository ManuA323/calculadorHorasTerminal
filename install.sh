#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/TU_USUARIO/trabajo/main"

echo "Descargando trabajo..."

sudo curl -fsSL "$REPO/trabajo.awk" -o /usr/local/bin/trabajo
sudo chmod +x /usr/local/bin/trabajo

cat << 'EOF' | sudo tee /usr/local/bin/horas >/dev/null
#!/bin/bash
last reboot -F -s "$(date -d '14 days ago' '+%Y-%m-%d')" | trabajo
EOF

sudo chmod +x /usr/local/bin/horas

echo
echo "Instalado correctamente."
echo
echo "Usá:"
echo
echo "    horas"