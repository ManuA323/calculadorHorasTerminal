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

function minutos(hora,    a) {
    split(hora,a,":")
    return a[1]*60+a[2]
}

function formato_horas(min,    h,m) {
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

    if (!(dia in dias))
        next

    inicio=substr($8,1,5)

    if ($10=="still") {
        fin="Actual"
        duracion=0
        activo=1
    } else {
        fin=substr($11,1,5)

        # Extraer duración sin usar match con array
        duracionTexto=$(NF-0)
        gsub(/[()]/,"",duracionTexto)

        split(duracionTexto,t,":")
        if (length(t)!=2)
            next

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
    }
    else {

        # Si uno de los intervalos sigue activo
        if (activo || activoDia[clave]) {
            activoDia[clave]=1
            finDia[clave]="Actual"
        }

        # Unificar intervalos si se pisan
        if (finDia[clave]=="Actual" || minutos(inicio)<=minutos(finDia[clave])) {

            if (minutos(inicio)<minutos(inicioDia[clave]))
                inicioDia[clave]=inicio

            if (fin!="Actual" && (finDia[clave]=="Actual" || minutos(fin)>minutos(finDia[clave])))
                finDia[clave]=fin

        }
        else {
            # Intervalos separados: sumar horas
            totalDia[clave]+=duracion
        }
    }
}

END {

    totalSemana=0
    ultimaSemana=""

    for (i=1;i<=cantidad;i++) {

        clave=orden[i]

        split(clave,d,"_")

        dia=d[1]
        mes=d[2]
        fecha=d[3]

        fechaFormato=sprintf("%02d/%s",fecha,meses[mes])

        if (activoDia[clave]) {
            hasta="Actual"
            total="En curso"
        }
        else {
            hasta=finDia[clave]

            totalMin=minutos(finDia[clave])-minutos(inicioDia[clave])

            if (totalMin<0)
                totalMin=totalDia[clave]

            total=formato_horas(totalMin)
            totalSemana+=totalMin
        }

        printf "%-10s %s: Desde: %s  Hasta: %s  (Total: %s)\n",
            dias[dia],
            fechaFormato,
            inicioDia[clave],
            hasta,
            total
    }

    if (totalSemana>0)
        printf "\nTOTAL SEMANAL: %s / 35:00\n", formato_horas(totalSemana)
}