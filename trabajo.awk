#!/usr/bin/awk -f

BEGIN {
    dias["Mon"]="Lunes"
    dias["Tue"]="Martes"
    dias["Wed"]="Miércoles"
    dias["Thu"]="Jueves"
    dias["Fri"]="Viernes"

    meses["Jan"]="1"
    meses["Feb"]="2"
    meses["Mar"]="3"
    meses["Apr"]="4"
    meses["May"]="5"
    meses["Jun"]="6"
    meses["Jul"]="7"
    meses["Aug"]="8"
    meses["Sep"]="9"
    meses["Oct"]="10"
    meses["Nov"]="11"
    meses["Dec"]="12"
}

function minutos(hora, a) {
    split(hora,a,":")
    return a[1]*60+a[2]
}

function formatoHoras(min, h, m) {
    h=int(min/60)
    m=min%60
    return sprintf("%02d:%02d",h,m)
}

{
    if ($1 != "reboot")
        next

    dia=$5
    mes=$6
    fecha=$7
    inicio=substr($8,1,5)

    if (!(dia in dias))
        next

    # Sistema actualmente encendido
    if ($10=="still" || $11=="still") {
        fin="Actual"
        duracion=0
        activo=1
    }
    else {
        # En last -F:
        # $11 = día fin
        # $12 = mes fin
        # $13 = día del mes fin
        # $14 = hora fin
        fin=substr($14,1,5)

        if (match($0, /\([0-9:]+\)/)) {
            tiempo=substr($0,RSTART+1,RLENGTH-2)
        } else {
            next
        }

        split(tiempo,t,":")
        duracion=t[1]*60+t[2]
        activo=0
    }

    clave=dia"_"mes"_"fecha

    if (!(clave in inicioDia)) {

        inicioDia[clave]=inicio
        finDia[clave]=fin
        totalDia[clave]=duracion
        activoDia[clave]=activo
        orden[++cantidad]=clave

    } else {

        # Si uno de los intervalos está activo
        if (activo || activoDia[clave]) {
            activoDia[clave]=1
            finDia[clave]="Actual"
        }

        # Intervalos superpuestos: unir
        if (finDia[clave]=="Actual" || inicio <= finDia[clave]) {

            if (inicio < inicioDia[clave])
                inicioDia[clave]=inicio

            if (fin != "Actual" && fin > finDia[clave])
                finDia[clave]=fin

        }
        else {
            # Intervalos separados: sumar
            totalDia[clave]+=duracion
        }
    }
}

END {

    totalSemana=0

    for (i=1;i<=cantidad;i++) {

        clave=orden[i]

        split(clave,d,"_")

        dia=d[1]
        mes=d[2]
        fecha=d[3]

        fechaFormato=sprintf("%02d/%s",fecha,meses[mes])

        if (activoDia[clave]) {

            total="En curso"
            hasta="Actual"

        }
        else {

            hasta=finDia[clave]

            minutosDia=totalDia[clave]

            # Si quedó un único intervalo consolidado
            if (finDia[clave]!="Actual") {
                minutosDia=minutos(finDia[clave])-minutos(inicioDia[clave])
            }

            total=formatoHoras(minutosDia)
            totalSemana+=minutosDia
        }

        printf "%-10s %s: Desde: %s  Hasta: %s  (Total: %s)\n",
            dias[dia],
            fechaFormato,
            inicioDia[clave],
            hasta,
            total
    }

    if (totalSemana>0)
        printf "\nTOTAL SEMANAL: %s / 35:00\n", formatoHoras(totalSemana)
}