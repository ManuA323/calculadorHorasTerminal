#!/usr/bin/awk -f

BEGIN {
    dias["Mon"]="Lunes"
    dias["Tue"]="Martes"
    dias["Wed"]="Miércoles"
    dias["Thu"]="Jueves"
    dias["Fri"]="Viernes"
}

function minutos(hora) {
    split(hora,a,":")
    return a[1]*60+a[2]
}

function horas(min,    h,m) {
    h=int(min/60)
    m=min%60
    return sprintf("%02d:%02d",h,m)
}

function dia_semana(nombre) {
    return dias[nombre]
}

{
    if ($1 != "reboot")
        next

    kernel=$4
    dia=$5
    mes=$6
    fecha=$7
    inicio=substr($8,1,5)

    if (!(dia in dias))
        next

    # Buscar fin y duración
    if ($10=="still") {
        fin="Actual"
        duracion=0
        activo=1
    } else {
        fin=substr($11,1,5)
        match($0, /\(([0-9:]+)\)/, m)

        if (m[1] == "")
            next

        split(m[1],t,":")
        duracion=t[1]*60+t[2]
        activo=0
    }

    clave=dia"_"mes"_"fecha

    if (!(clave in inicioDia)) {
        inicioDia[clave]=inicio
        finDia[clave]=fin
        totalDia[clave]=duracion
        activoDia[clave]=activo
        orden[++n]=clave
    }
    else {
        # Si alguno está activo
        if (activo || activoDia[clave]) {
            activoDia[clave]=1
            finDia[clave]="Actual"
        }

        # Intervalos con intersección
        if (inicio <= finDia[clave] || finDia[clave]=="Actual") {

            if (inicio < inicioDia[clave])
                inicioDia[clave]=inicio

            if (fin != "Actual" && fin > finDia[clave])
                finDia[clave]=fin

        } else {
            # Sin intersección: sumar horas
            totalDia[clave]+=duracion
        }
    }
}

END {

    semana=0
    ultimaSemana=""

    for (i=1;i<=n;i++) {

        clave=orden[i]

        split(clave,d,"_")

        dia=d[1]
        mes=d[2]
        fecha=d[3]

        salidaDia=dias[dia]

        # Convertir mes a número
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

        fechaFormato=sprintf("%02d/%s",fecha,meses[mes])

        if (activoDia[clave]) {
            total="En curso"
            hasta="Actual"
        }
        else {
            hasta=finDia[clave]

            # Recalcular duración por intervalo consolidado
            totalMin=totalDia[clave]

            if (finDia[clave]!="Actual") {
                totalMin=minutos(finDia[clave])-minutos(inicioDia[clave])
            }

            total=horas(totalMin)
            semana+=totalMin
        }

        printf "%-10s %s: Desde: %s  Hasta: %s  (Total: %s)\n",
            salidaDia,
            fechaFormato,
            inicioDia[clave],
            hasta,
            total

    }

    if (semana>0)
        printf "\nTOTAL SEMANAL: %s / 35:00\n", horas(semana)
}