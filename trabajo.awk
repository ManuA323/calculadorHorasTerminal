#!/usr/bin/awk -f

BEGIN {
    dias["Mon"]="Lunes"
    dias["Tue"]="Martes"
    dias["Wed"]="Miércoles"
    dias["Thu"]="Jueves"
    dias["Fri"]="Viernes"

    meses["Jan"]="01"
    meses["Feb"]="02"
    meses["Mar"]="03"
    meses["Apr"]="04"
    meses["May"]="05"
    meses["Jun"]="06"
    meses["Jul"]="07"
    meses["Aug"]="08"
    meses["Sep"]="09"
    meses["Oct"]="10"
    meses["Nov"]="11"
    meses["Dec"]="12"
}

function minutos(hora, a) {
    split(hora,a,":")
    return a[1]*60+a[2]
}

function formato(min, h,m) {
    h=int(min/60)
    m=min%60
    return sprintf("%02d:%02d",h,m)
}

function fechaClave(mes,dia) {
    return sprintf("%02d/%s", dia, meses[mes])
}

{
    if ($1!="reboot")
        next

    dia=$5
    mes=$6
    fecha=$7

    if (!(dia in dias))
        next

    inicio=substr($8,1,5)

    if ($10=="still") {
        fin="Actual"
        activo=1
        duracion=0
    }
    else {
        fin=substr($11,1,5)

        duracionTexto=$NF
        gsub(/[()]/,"",duracionTexto)

        split(duracionTexto,t,":")
        if (t[1]=="" || t[2]=="")
            next

        duracion=t[1]*60+t[2]
        activo=0
    }

    clave=fecha"_"mes"_"dia

    if (!(clave in inicioDia)) {
        inicioDia[clave]=inicio
        finDia[clave]=fin
        totalDia[clave]=duracion
        activoDia[clave]=activo
        orden[++cantidad]=clave
    }
    else {
        # unir intervalos superpuestos
        if (finDia[clave]=="Actual" || inicio<=finDia[clave]) {

            if (inicio < inicioDia[clave])
                inicioDia[clave]=inicio

            if (fin!="Actual" && (finDia[clave]=="Actual" || fin>finDia[clave]))
                finDia[clave]=fin

            if (activo)
                activoDia[clave]=1
        }
        else {
            # intervalos separados
            totalDia[clave]+=duracion
        }
    }
}

END {
    semanaActual=""
    totalSemana=0

    for (i=1;i<=cantidad;i++) {

        clave=orden[i]

        split(clave,d,"_")

        fecha=d[1]
        mes=d[2]
        diaSemana=d[3]

        # Convertir fecha a semana ISO usando date
        comando="date -d '" fecha " " mes " 2026' +%V"
        comando | getline semana
        close(comando)

        if (semanaActual=="" ) {
            semanaActual=semana
        }

        if (semana != semanaActual) {
            printf "\nTOTAL SEMANAL: %s / 35:00\n\n", formato(totalSemana)
            totalSemana=0
            semanaActual=semana
        }

        salida=dias[diaSemana]

        fechaFormato=sprintf("%02d/%s",fecha,meses[mes])

        if (activoDia[clave]) {
            total="En curso"
            hasta="Actual"
        }
        else {
            hasta=finDia[clave]

            totalMin=minutos(finDia[clave])-minutos(inicioDia[clave])

            if (totalMin<0)
                totalMin=totalDia[clave]

            total=formato(totalMin)
            totalSemana+=totalMin
        }

        printf "%-10s %s: Desde: %s  Hasta: %s  (Total: %s)\n",
            salida,
            fechaFormato,
            inicioDia[clave],
            hasta,
            total
    }

    if (totalSemana>0)
        printf "\nTOTAL SEMANAL: %s / 35:00\n", formato(totalSemana)
}