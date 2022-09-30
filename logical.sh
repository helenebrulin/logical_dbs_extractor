#! /bin/bash

#Statics
inthost="127.0.0.01"
intport=6381
serverPID=0
password=""
redisserver="redis-server"
rediscli="redis-cli"

#Colors
RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

#Kill all processes whose parent is this process upon exit
cleanup() {
    pkill -P $$
}

for sig in INT QUIT HUP TERM; do
  trap "
    cleanup
    trap - $sig EXIT
    kill -s $sig "'"$$"' "$sig"
done
trap cleanup EXIT

#Usage function
usage() {
    printf "${RED}Usage: ./logical.sh -h HOST -p PORT -v REDIS_SERVER_VERSION:6.2/6.0/5/4\nOptional : -a PASSWORD${ENDCOLOR}\n" && exit
}

#Parsing inputs
while getopts h:p:v:a: flag
do
    case "${flag}" in
        h) HOST=${OPTARG};;
        p) PORT=${OPTARG};;
        v) VERSION=${OPTARG};;
        a) password=${OPTARG};;
        \?)
            usage && exit 1
        ;;
    esac
done

if [ -z "$HOST" ] || [ -z "$PORT" ] || [ -z "$VERSION" ] 
then
   usage
   exit
fi

#Input confirmation
printf "${YELLOW}Host: $HOST ${ENDCOLOR}\n";
printf "${YELLOW}Port: $PORT ${ENDCOLOR}\n";
printf "${YELLOW}Version: $VERSION ${ENDCOLOR}\n";
printf "${YELLOW}--------${ENDCOLOR}\n";

#Intermediary instance function
launch_instance() {
    printf "${YELLOW}Launching intermediary instance on port $intport ${ENDCOLOR}\n";
    nohup $redisserver "./confs/redis$VERSION.conf" > /dev/null 2>&1 &
    serverPID=$!
    sleep 1
    if $rediscli -h $inthost -p $intport PING | grep -q 'PONG'; 
        then
            printf "${GREEN}Connected. ServerPID: $serverPID ${ENDCOLOR}\n"
            printf "${YELLOW}--------${ENDCOLOR}\n";
        else
            printf "${RED}Error - Could not connect to server. Check that port 6381 is available. Check paths of redis-server installation. Exiting. ${ENDCOLOR}\n"
            exit
    fi
}

#Connecting to Source database
printf "${YELLOW}Connecting to Source database...${ENDCOLOR}\n";
if $rediscli -u "redis://default:$password@$HOST:$PORT" PING 2>/dev/null | grep -q 'PONG';
    then
        printf "${GREEN}Connected. Creating source snapshot...\n"
        printf "${YELLOW}--------${ENDCOLOR}\n";
    else
        printf "${RED}Error - Could not connect to source database. Check your redis-cli path and your default password.${ENDCOLOR}\n"
        exit
fi

#Creating output folder
mkdir -p output

#Saving initial config
dbfilename=`"$rediscli" -u "redis://default:$password@$HOST:$PORT" CONFIG GET dbfilename 2>/dev/null`
dir=`"$rediscli" -u "redis://default:$password@$HOST:$PORT" CONFIG GET dir 2>/dev/null`

#Changing config and dumping
$rediscli -u "redis://default:$password@$HOST:$PORT" CONFIG SET dbfilename source.rdb &>/dev/null
$rediscli -u "redis://default:$password@$HOST:$PORT" CONFIG SET dir ./output &>/dev/null
$rediscli -u "redis://default:$password@$HOST:$PORT" SAVE &>/dev/null
printf "${GREEN}Source snapshot created.${ENDCOLOR}\n";
printf "${YELLOW}--------${ENDCOLOR}\n";

#Restoring initial config
$rediscli -u "redis://default:$password@$HOST:$PORT" CONFIG SET $dbfilename &>/dev/null
$rediscli -u "redis://default:$password@$HOST:$PORT" CONFIG SET $dir &>/dev/null

i=0

#Extraction loop
while [[ $i -lt 16 ]]
    do
        launch_instance
        printf "${YELLOW}Snapshotting DB $i. ${ENDCOLOR}\n"
        j=$(( ($i + 1) % 16))
        while [[ $(($j % 16)) != $i ]]
            do
                $rediscli -h $inthost -p $intport -n $j FLUSHDB >/dev/null
                j=$(( ($j + 1) % 16))
            done
        $rediscli -h $inthost -p $intport CONFIG SET dbfilename "$i.rdb" >/dev/null
        $rediscli -h $inthost -p $intport SAVE >/dev/null
        printf "${GREEN}DB $i snapshot created. ${ENDCOLOR}\n";
        printf "${YELLOW}Stopping intermediate Redis Instance... ${ENDCOLOR}\n";
        kill $serverPID
        sleep 1
        i=$(($i + 1))
        printf "${YELLOW}--------${ENDCOLOR}\n";
    done

printf "${GREEN}Finished${ENDCOLOR}\n";    

