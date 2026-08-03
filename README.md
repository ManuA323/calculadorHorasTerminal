# Calculador de horas terminal

Calcula horas trabajadas usando eventos reales del sistema Linux.

Utiliza:

- journalctl
- systemd-sleep
- systemd-logind

Detecta:

- inicio del sistema
- suspensiones
- reanudaciones
- apagados

## Instalacion

Ejecutar:
```console
curl -fsSL https://raw.githubusercontent.com/ManuA323/calculadorHorasTerminal/main/install.sh | bash
```

## Uso

Luego:
```console
horas
```

## Desinstalar
Ejecutar:
```console
./uninstall.sh
```

