#!/usr/bin/awk -f

BEGIN {
    dias["Mon"]="Lunes"
    dias["Tue"]="Martes"
    dias["Wed"]="Miércoles"
    dias["Thu"]="Jueves"
    dias["Fri"]="Viernes"
    dias["Sat"]="Sábado"
    dias["Sun"]="Domingo"

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
    if (min < 0)
        min=0

    h=int(min/60)
    m=min%60

    return sprintf("%02d:%02d",h,m)
}

function obtenerSemana(fecha, mes, año, comando, semana) {
    comando="date -d '" fecha " " mes " " año "' +%V"
    comando | getline semana
    close(comando)
    return semana
}

{
    if ($1!="reboot")
        next

    diaSemana=$5
    mes=$6
    fecha=$7
    año=$8

    if (!(diaSemana in dias))
        next

    inicio=substr($9,1,5)

    if ($11=="still") {
        fin="Actual"
        activo=1
        duracion=0
    }
    else {
        fin=substr($12,1,5)

        duracionTexto=$NF
        gsub(/[()]/,"",duracionTexto)

        split(duracionTexto,t,":")

        if (t[1]=="" || t[2]=="")
            next

        duracion=t[1]*60+t[2]
        activo=0
    }

    clave=año"_"mes"_"fecha

    if (!(clave in inicioDia)) {
        inicioDia[clave]=inicio
        finDia[clave]=fin
        totalDia[clave]=duracion
        activoDia[clave]=activo

        añoDia[clave]=año
        mesDia[clave]=mes
        fechaDia[clave]=fecha
        diaSemanaDia[clave]=diaSemana

        cantidad++
        orden[cantidad]=clave
    }
    else {

        if (activoDia[clave] || activo) {
            activoDia[clave]=1
            finDia[clave]="Actual"
        }

        if (inicio < inicioDia[clave])
            inicioDia[clave]=inicio

        if (fin!="Actual" && finDia[clave]!="Actual" && fin > finDia[clave])
            finDia[clave]=fin

    }
}

END {

    # ordenar cronológicamente
    for (i=1;i<=cantidad;i++) {

        for (j=i+1;j<=cantidad;j++) {

            f1=añoDia[orden[i]] mesDia[orden[i]] sprintf("%02d",fechaDia[orden[i]])
            f2=añoDia[orden[j]] mesDia[orden[j]] sprintf("%02d",fechaDia[orden[j]])

            if (f1 > f2) {
                tmp=orden[i]
                orden[i]=orden[j]
                orden[j]=tmp
            }
        }
    }


    semanaActual=""
    totalSemana=0


    for (i=1;i<=cantidad;i++) {

        clave=orden[i]

        semana=obtenerSemana(
            fechaDia[clave],
            mesDia[clave],
            añoDia[clave]
        )


        if (semanaActual!="" && semana!=semanaActual) {

            printf "\nTOTAL SEMANAL: %s / 35:00\n\n", formato(totalSemana)

            totalSemana=0
        }


        semanaActual=semana


        salida=dias[diaSemanaDia[clave]]

        fechaFormato=sprintf(
            "%02d/%s",
            fechaDia[clave],
            meses[mesDia[clave]]
        )


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


    if (cantidad>0)
        printf "\nTOTAL SEMANAL: %s / 35:00\n", formato(totalSemana)
}