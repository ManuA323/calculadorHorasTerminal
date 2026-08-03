BEGIN {
    FS=" "

    meses["01"]="01"
    meses["02"]="02"
    meses["03"]="03"
    meses["04"]="04"
    meses["05"]="05"
    meses["06"]="06"
    meses["07"]="07"
    meses["08"]="08"
    meses["09"]="09"
    meses["10"]="10"
    meses["11"]="11"
    meses["12"]="12"

    semana_actual=""
}

function timestamp(line,   d,t) {
    d=substr(line,1,10)
    t=substr(line,12,5)
    return d " " t
}

function minutos(hora,   a) {
    split(hora,a,":")
    return a[1]*60+a[2]
}

function formato(min,   h,m) {
    if(min<0)
        return "00:00"

    h=int(min/60)
    m=min%60

    return sprintf("%02d:%02d",h,m)
}

function diaSemana(fecha,   cmd,res) {
    cmd="date -d " fecha " +%u"
    cmd | getline res
    close(cmd)
    return res
}

function nombreDia(fecha,   cmd,res) {
    cmd="date -d " fecha " +%A"
    cmd | getline res
    close(cmd)

    return toupper(substr(res,1,1)) substr(res,2)
}

{
    fecha=substr($0,1,10)
    hora=substr($0,12,5)

    # Solo días hábiles
    dia=diaSemana(fecha)

    if(dia>5)
        next


    # Inicio de sesión del usuario
    if($0 ~ /New session [0-9]+ of user/) {

        # ignorar gdm
        if($0 !~ /user gdm/) {

            if(inicio[fecha]=="")
                inicio[fecha]=hora
        }
    }


    # Retorno de suspensión
    if($0 ~ /System returned from sleep operation/) {

        if(inicio[fecha]=="")
            inicio[fecha]=hora
    }


    # Fin por apagado
    if($0 ~ /System is powering down/) {

        fin[fecha]=hora
    }


    # Fin por suspensión
    if($0 ~ /The system will suspend now/) {

        fin[fecha]=hora
    }
}


END {

    # Fecha actual
    cmd="date +%Y-%m-%d"
    cmd | getline hoy
    close(cmd)

    if(inicio[hoy]!="" && fin[hoy]=="") {
        fin[hoy]="EN CURSO"
    }


    # Últimos 14 días hábiles
    cmd="date -d '14 days ago' +%Y-%m-%d"
    cmd | getline desde
    close(cmd)


    totalSemana=0
    semana=""

    for(i=0;i<14;i++) {

        cmd="date -d '" i " days ago' +%Y-%m-%d"
        cmd | getline fecha
        close(cmd)


        dia=diaSemana(fecha)

        if(dia>5)
            continue


        if(inicio[fecha]=="") 
            continue


        nombre=nombreDia(fecha)


        if(fin[fecha]=="EN CURSO") {

            cmd="date +%H:%M"
            cmd | getline ahora
            close(cmd)

            total=minutos(ahora)-minutos(inicio[fecha])

        } else {

            total=minutos(fin[fecha])-minutos(inicio[fecha])
        }


        if(total<0)
            total=0


        # Cambio de semana
        cmd="date -d '" fecha "' +%G-%V"
        cmd | getline semanaFecha
        close(cmd)


        if(semana!="" && semanaFecha!=semana) {

            print ""
            print "TOTAL SEMANAL: " formato(totalSemana) " / 35:00 hs"
            print ""

            totalSemana=0
        }


        if(semanaFecha!=semana) {
            semana=semanaFecha
        }


        printf "%-10s %s: Inicio: %s  Fin: %s  Total Diario: %s\n",
            nombre,
            fecha,
            inicio[fecha],
            fin[fecha],
            formato(total)


        totalSemana+=total
    }


    if(totalSemana>0) {

        print ""
        print "TOTAL SEMANAL: " formato(totalSemana) " / 35:00 hs"
    }
}