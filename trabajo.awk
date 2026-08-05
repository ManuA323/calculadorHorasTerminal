BEGIN {
    total_actual=0
    total_anterior=0
}

function minutos(h) {
    split(h,a,":")
    return a[1]*60+a[2]
}

function formato(t) {
    if (t < 0) {
        t = -t
        return sprintf("-%02d:%02d", int(t/60), t%60)
    }
    return sprintf("%02d:%02d", int(t/60), t%60)
}

function sumar7hs(hora) {
    split(hora,a,":")
    m=a[1]*60+a[2]+420

    while (m>=1440)
        m-=1440

    return sprintf("%02d:%02d", int(m/60), m%60)
}

function nombre_dia(n) {
    if (n==1) return "Lunes"
    if (n==2) return "Martes"
    if (n==3) return "Miercoles"
    if (n==4) return "Jueves"
    if (n==5) return "Viernes"
}

function siguiente_fecha(fecha) {
    cmd="date -d \"" fecha " +1 day\" +%Y-%m-%d"
    cmd | getline r
    close(cmd)
    return r
}

function anterior_fecha(fecha) {
    cmd="date -d \"" fecha " -1 day\" +%Y-%m-%d"
    cmd | getline dia
    close(cmd)
    return r
}

function semana_lunes(fecha) {
    cmd="date -d \"" fecha "\" +%u"
    cmd | getline dia
    close(cmd)

    r=fecha

    while (dia != 1) {
        r=anterior_fecha(r)
        cmd="date -d \"" r "\" +%u"
        cmd | getline dia
        close(cmd)
    }

    return r
}

function imprimir_semana(titulo, lunes, cual) {

    print ""
    print titulo
    print ""

    fecha=lunes
    total=0
    deuda_semanal=0

    for (i=1;i<=5;i++) {

        dia=nombre_dia(i)

        if (fecha > hoy) {
            # Días futuros: no se contabilizan ni tienen deuda
            printf "%-9s %s: Sin registro Total Diario: 00:00\n",
                dia,
                fecha
        }
        else if (fecha == hoy && (fecha in inicio)) {
            # Día actual en curso: muestra progreso pero NO acumula deuda semanal
            tiempo = minutos(hora_actual) - minutos(inicio[fecha])
            if (tiempo < 0) tiempo = 0

            total += tiempo

            printf "%-9s %s: Inicio: %s  Fin esperado: %s  Total Diario: %s\n",
                dia,
                fecha,
                inicio[fecha],
                sumar7hs(inicio[fecha]),
                formato(tiempo)
        }
        else if ((fecha in inicio) && (fecha in fin)) {
            # Día pasado finalizado
            tiempo = minutos(fin[fecha]) - minutos(inicio[fecha])
            if (tiempo < 0) tiempo = 0

            total += tiempo
            
            cadena_deuda = ""
            if (fecha < hoy) {
                deuda_dia = 420 - tiempo
                if (deuda_dia > 0) {
                    deuda_semanal += deuda_dia
                    cadena_deuda = sprintf("  Deuda diaria: %s", formato(deuda_dia))
                }
            }

            printf "%-9s %s: Inicio: %s  Fin: %s  Total Diario: %s%s\n",
                dia,
                fecha,
                inicio[fecha],
                fin[fecha],
                formato(tiempo),
                cadena_deuda
        }
        else {
            # Día pasado sin registro
            cadena_deuda = ""
            if (fecha < hoy) {
                deuda_semanal += 420
                cadena_deuda = sprintf("  Deuda diaria: %s", formato(420))
            }

            printf "%-9s %s: Sin registro Total Diario: 00:00%s\n",
                dia,
                fecha,
                cadena_deuda
        }

        fecha=siguiente_fecha(fecha)
    }

    if (cual==1)
        total_actual=total

    if (cual==2)
        total_anterior=total

    printf "\nTOTAL SEMANAL: %s / 35:00 hs\n", formato(total)
    printf "DEUDA DE HORAS SEMANAL: %s\n", formato(deuda_semanal)
}


{
    fecha=substr($1,1,10)
    hora=substr($1,12,5)
    linea=$0


    activo=0

    if (linea ~ /New session [0-9]+ of user/)
        activo=1

    if (linea ~ /Waking up from system sleep/)
        activo=1

    if (linea ~ /System returned from sleep operation/)
        activo=1

    if (linea ~ /PM: suspend exit/)
        activo=1


    if (activo==1) {

        if (!(fecha in inicio))
            inicio[fecha]=hora
    }


    desactivo=0

    if (linea ~ /System is powering down/)
        desactivo=1

    if (linea ~ /The system will suspend now/)
        desactivo=1

    if (linea ~ /PM: suspend entry/)
        desactivo=1

    if (linea ~ /Performing sleep operation/)
        desactivo=1

    if (linea ~ /Powering off/)
        desactivo=1

    if (linea ~ /hibernate/)
        desactivo=1


    if (desactivo==1)
        fin[fecha]=hora
}


END {

    cmd="date +%Y-%m-%d"
    cmd | getline hoy
    close(cmd)

    cmd="date +%H:%M"
    cmd | getline hora_actual
    close(cmd)


    lunes_actual=semana_lunes(hoy)

    lunes_anterior=anterior_fecha(lunes_actual)
    lunes_anterior=anterior_fecha(lunes_anterior)
    lunes_anterior=anterior_fecha(lunes_anterior)
    lunes_anterior=anterior_fecha(lunes_anterior)
    lunes_anterior=anterior_fecha(lunes_anterior)
    lunes_anterior=anterior_fecha(lunes_anterior)
    lunes_anterior=anterior_fecha(lunes_anterior)


    imprimir_semana("SEMANA ANTERIOR", lunes_anterior, 2)

    imprimir_semana("SEMANA ACTUAL", lunes_actual, 1)
}