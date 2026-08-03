#!/usr/bin/awk -f

BEGIN {
    dias["Mon"]="Lunes"
    dias["Tue"]="Martes"
    dias["Wed"]="Miercoles"
    dias["Thu"]="Jueves"
    dias["Fri"]="Viernes"
}

function minutos(hora) {
    split(hora,a,":")
    return a[1]*60+a[2]
}

function formato(min) {
    return sprintf("%02d:%02d", int(min/60), min%60)
}

function diaSemana(fecha, cmd, resultado) {
    cmd = "date -d " fecha " +%u"
    cmd | getline resultado
    close(cmd)
    return resultado
}

function semanaISO(fecha, cmd, resultado) {
    cmd = "date -d " fecha " +%V"
    cmd | getline resultado
    close(cmd)
    return resultado
}

{
    fecha=substr($1,1,10)
    hora=substr($1,12,5)

    # Ignorar otras sesiones y quedarse con el usuario real
    if ($0 ~ "New session" && $0 ~ ("of user " usuario)) {

        if (!(fecha in inicio)) {
            inicio[fecha]=hora
        }

        next
    }


    # Apagado
    if ($0 ~ /System is powering down/) {

        fin[fecha]=hora
        next
    }


    # Entrada a suspension
    if ($0 ~ /Performing sleep operation/) {

        fin[fecha]=hora
        next
    }


    # Vuelta de suspension
    if ($0 ~ /System returned from sleep/) {

        if (!(fecha in inicio)) {
            inicio[fecha]=hora
        }

        next
    }
}

END {

    cantidad=0

    for (f in inicio) {

        if (!(f in fin))
            continue

        cantidad++
        fechas[cantidad]=f
    }


    # ordenar fechas ascendente
    for(i=1;i<=cantidad;i++) {
        for(j=i+1;j<=cantidad;j++) {

            if(fechas[i] > fechas[j]) {

                tmp=fechas[i]
                fechas[i]=fechas[j]
                fechas[j]=tmp
            }
        }
    }


    semanaActual=""

    totalSemana=0


    # mostrar semanas de la mas nueva hacia atras
    for(i=cantidad;i>=1;i--) {

        fecha=fechas[i]

        sem=semanaISO(fecha)


        if(semanaActual=="") {
            semanaActual=sem
        }


        if(sem != semanaActual) {

            printf "\nTOTAL SEMANAL: %s / 35:00 hs\n\n", formato(totalSemana)

            totalSemana=0
            semanaActual=sem
        }


        totalDia=minutos(fin[fecha])-minutos(inicio[fecha])

        if(totalDia<0)
            totalDia=0


        totalSemana+=totalDia


        d=diaSemana(fecha)

        nombre=""

        if(d=="1") nombre="Lunes"
        if(d=="2") nombre="Martes"
        if(d=="3") nombre="Miercoles"
        if(d=="4") nombre="Jueves"
        if(d=="5") nombre="Viernes"


        printf "%-10s %s: Inicio: %s  Fin: %s  Total Diario: %s\n",
            nombre,
            fecha,
            inicio[fecha],
            fin[fecha],
            formato(totalDia)
    }


    if(totalSemana>0)
        printf "\nTOTAL SEMANAL: %s / 35:00 hs\n", formato(totalSemana)
}