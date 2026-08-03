#!/usr/bin/awk -f

BEGIN {
    dias["Mon"]="Lunes"
    dias["Tue"]="Martes"
    dias["Wed"]="Miercoles"
    dias["Thu"]="Jueves"
    dias["Fri"]="Viernes"
}

function minutos(h, a) {
    split(h,a,":")
    return a[1]*60+a[2]
}

function formato(m) {
    return sprintf("%02d:%02d", int(m/60), m%60)
}

{
    fecha=substr($1,1,10)
    hora=substr($1,12,5)

    if ($0 ~ /New session 2 of user/) {
        if (!(fecha in inicio) || hora < inicio[fecha])
            inicio[fecha]=hora
    }

    if ($0 ~ /System is powering down/) {
        fin[fecha]=hora
    }
}

END {
    n=0

    for (d in inicio) {
        split(d,f,"-")

        cmd="date -d '" d "' +%u"
        cmd | getline diaNum
        close(cmd)

        # solo lunes a viernes
        if (diaNum>=6)
            continue

        orden[++n]=d
    }

    # ordenar fechas descendente
    for (i=1;i<=n;i++) {
        for (j=i+1;j<=n;j++) {
            if (orden[i] < orden[j]) {
                tmp=orden[i]
                orden[i]=orden[j]
                orden[j]=tmp
            }
        }
    }

    semanaActual=""
    totalSemana=0

    for (i=1;i<=n;i++) {

        d=orden[i]

        cmd="date -d '" d "' +%V"
        cmd | getline semana
        close(cmd)

        if (semanaActual=="")
            semanaActual=semana

        if (semana != semanaActual) {
            printf "\nTOTAL SEMANAL: %s / 35:00 hs\n\n", formato(totalSemana)
            totalSemana=0
            semanaActual=semana
        }

        cmd="date -d '" d "' +%a"
        cmd | getline dia
        close(cmd)

        diaTexto=dias[dia]

        if (d in fin) {
            finTexto=fin[d]

            totalMin=minutos(fin[d])-minutos(inicio[d])

            if (totalMin<0)
                totalMin=0
        }
        else {
            finTexto="Actual"

            ahora=strftime("%H:%M")
            totalMin=minutos(ahora)-minutos(inicio[d])

            if (totalMin<0)
                totalMin=0
        }

        total=formato(totalMin)
        totalSemana+=totalMin

        printf "%-10s %s: Inicio: %s  Fin: %s  Total Diario: %s\n",
            diaTexto,
            d,
            inicio[d],
            finTexto,
            total
    }

    if (totalSemana>0)
        printf "\nTOTAL SEMANAL: %s / 35:00 hs\n", formato(totalSemana)
}