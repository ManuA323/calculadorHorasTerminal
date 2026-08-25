BEGIN {
    total_actual = 0
    total_anterior = 0
    FS = ","
}

function minutos(h) {
    split(h, a, ":")
    return a[1]*60 + a[2]
}

function formato(t) {
    if (t < 0) {
        t = -t
        return sprintf("-%02d:%02d", int(t/60), t%60)
    }
    return sprintf("%02d:%02d", int(t/60), t%60)
}

function sumar7hs(hora) {
    split(hora, a, ":")
    m = a[1]*60 + a[2] + 420

    while (m >= 1440)
        m -= 1440

    return sprintf("%02d:%02d", int(m/60), m%60)
}

function sumar7hsYDeuda(hora, deuda) {
    split(hora, a, ":")
    m = a[1]*60 + a[2] + 420 + deuda

    while (m >= 1440)
        m -= 1440

    return sprintf("%02d:%02d", int(m/60), m%60)
}

function nombre_dia(n) {
    if (n==1) return "Lunes"
    if (n==2) return "Martes"
    if (n==3) return "Miercoles"
    if (n==4) return "Jueves"
    if (n==5) return "Viernes"
}

function fecha_a_timestamp(f) {
    split(f, a, "-")
    return mktime(sprintf("%04d %02d %02d 12 00 00", a[1], a[2], a[3]))
}

function timestamp_a_fecha(ts) {
    return strftime("%Y-%m-%d", ts)
}

function siguiente_fecha(fecha) {
    ts = fecha_a_timestamp(fecha)
    return timestamp_a_fecha(ts + 86400)
}

function semana_lunes(fecha) {
    ts = fecha_a_timestamp(fecha)
    dia_num = strftime("%u", ts) + 0
    
    while (dia_num != 1) {
        ts -= 86400
        dia_num = strftime("%u", ts) + 0
    }
    return strftime("%Y-%m-%d", ts)
}

function formato_fecha(f) {
    return substr(f, 9, 2) "/" substr(f, 6, 2)
}

function obtener_saldo_texto(etiqueta_deuda, etiqueta_haber, valor) {
    if (valor > 0)  return sprintf("  %s: %s", etiqueta_deuda, formato(valor))
    if (valor < 0)  return sprintf("  %s: %s", etiqueta_haber, formato(-valor))
    return ""
}

function imprimir_dia_vacio(dia, fecha) {
    printf "%-9s %s: Sin registro Total Diario: 00:00\n", dia, formato_fecha(fecha)
}

# --- PROCESAMIENTO DE ARCHIVOS ---
{
    # 1. Primer parámetro: Archivo CSV (Lo cargamos prioritariamente)
    if (FILENAME == archivo_csv) {
        if (NR == 1 && $0 ~ /^Fecha/) next;
        f = $1
        if (f != "") {
            if ($2 != "" && $2 != "-") inicio[f] = $2
            if ($3 != "" && $3 != "-") fin[f] = $3
            en_csv[f] = 1 # Marcamos que este día ya está consolidado en el CSV
        }
    }
    # 2. Segundo parámetro (STDIN): Output de Journalctl para rellenar vacíos
    else {
        fecha = substr($1, 1, 10)
        hora = substr($1, 12, 5)
        linea = $0

        # Si el día ya está guardado en el CSV con Inicio y Fin, ignoramos el log para no sobrescribir manuales
        if ((fecha in en_csv) && (fin[fecha] != "" && fin[fecha] != "-")) next;

        activo = 0
        if (linea ~ /New session [0-9]+ of user/) activo = 1
        if (linea ~ /Waking up from system sleep/) activo = 1
        if (linea ~ /System returned from sleep operation/) activo = 1
        if (linea ~ /PM: suspend exit/) activo = 1

        if (activo == 1) {
            if (!(fecha in inicio))
                inicio[fecha] = hora
        }

        desactivo = 0
        if (linea ~ /System is powering down/) desactivo = 1
        if (linea ~ /The system will suspend now/) desactivo = 1
        if (linea ~ /PM: suspend entry/) desactivo = 1
        if (linea ~ /Performing sleep operation/) desactivo = 1
        if (linea ~ /Powering off/) desactivo = 1
        if (linea ~ /hibernate/) desactivo = 1

        if (desactivo == 1)
            fin[fecha] = hora
    }
}

function imprimir_semana(titulo, lunes, cual,    i, dia, fecha, total, deuda_semanal, tiempo, deuda_dia, cadena_saldo) {
    print ""
    printf "%s \n", titulo
    
    fecha = lunes
    total = 0
    deuda_semanal = 0

    for (i = 1; i <= 5; i++) {
        dia = nombre_dia(i)

        if (fecha == hoy && (fecha in inicio)) {
            tiempo = minutos(hora_actual) - minutos(inicio[fecha])
            total += (tiempo > 0) ? tiempo : 0

            printf "%-9s %s: Inicio: %s  Fin jornada: %s  Fin jornada con deuda/haber: %s\n",
                dia, formato_fecha(fecha), inicio[fecha],
                sumar7hs(inicio[fecha]),
                sumar7hsYDeuda(inicio[fecha], deuda_semanal)
        }
        else if (fecha < hoy && (fecha in inicio) && (fecha in fin)) {
            tiempo = minutos(fin[fecha]) - minutos(inicio[fecha])
            tiempo = (tiempo > 0) ? tiempo : 0
            total += tiempo
            
            deuda_dia = 420 - tiempo
            deuda_semanal += deuda_dia
            cadena_saldo = obtener_saldo_texto("Deuda diaria", "Haber diario", deuda_dia)

            printf "%-9s %s: Inicio: %s  Fin: %s  Total Diario: %s%s\n",
                dia, formato_fecha(fecha), inicio[fecha], fin[fecha], formato(tiempo), cadena_saldo
        }
        else {
            imprimir_dia_vacio(dia, fecha)
        }

        fecha = siguiente_fecha(fecha)
    }

    if (cual == 1) total_actual = total
    if (cual == 2) total_anterior = total

    print obtener_saldo_texto("DEUDA", "HABER", deuda_semanal)
}

END {
    hoy = strftime("%Y-%m-%d")
    hora_actual = strftime("%H:%M")

    # Guardar en el CSV únicamente los días que NO estaban guardados aún (o días pasados recién completados)
    for (f in inicio) {
        if (!(f in en_csv)) {
            if (f < hoy || (f == hoy && (f in fin))) {
                h_fin = (f in fin) ? fin[f] : "-"
                print f "," inicio[f] "," h_fin >> archivo_csv
            }
        }
    }

    lunes_actual = semana_lunes(hoy)
    ts_lunes_anterior = fecha_a_timestamp(lunes_actual) - (7 * 86400)
    lunes_anterior = timestamp_a_fecha(ts_lunes_anterior)

    imprimir_semana("SEMANA ANTERIOR", lunes_anterior, 2)
    imprimir_semana("SEMANA ACTUAL", lunes_actual, 1)
    print "\nRECORDÁ ESCRIBIR \"BUEN DÍA\": https://mail.google.com/mail/u/0/#chat/home"
}