#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP


## just in case someone removed the defaults.
if [ "${STEAM_USER}" == "" ]; then
    echo -e "steam user is not set.\n"
    echo -e "Using anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "user set to ${STEAM_USER}"
fi

## if auto_update is not set or to 1 update
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
    # Update Source Server
    if [ ! -z ${SRCDS_APPID} ]; then
        ./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update 1007 +app_update ${SRCDS_APPID} $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" ) $( [[ -z ${HLDS_GAME} ]] || printf %s "+app_set_config 90 mod ${HLDS_GAME}" ) $( [[ -z ${VALIDATE} ]] || printf %s "validate" ) +quit
    else
        echo -e "No appid set. Starting Server"
    fi

else
    echo -e "Not updating game server as auto update was set to 0. Starting Server"
fi


# Setup NSS Wrapper for use ($NSS_WRAPPER_PASSWD and $NSS_WRAPPER_GROUP have been set by the Dockerfile)
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /passwd.template > ${NSS_WRAPPER_PASSWD}

export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libnss_wrapper.so

# Replace Startup Variables
# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# No logfile requested: hand PID 1 straight to the game so stop signals reach it.
if [ -z "${LOG_FILE}" ]; then
    eval "exec ${MODIFIED_STARTUP}"
fi

# Logfile requested: console + file via tee, stop signal forwarded to the game.
# LOG_FILE may contain strftime tokens, e.g. logs/valheim-%Y-%m-%d_%H%M%S.log
LOG_PATH="$(date +"${LOG_FILE}")"
mkdir -p "$(dirname "${LOG_PATH}")"
FIFO="$(mktemp -u /tmp/console.XXXXXX)"
mkfifo "${FIFO}"

set -m                              # children keep default signal dispositions
tee -a "${LOG_PATH}" < "${FIFO}" &
TEE=$!

trap 'kill -INT "${SPID}" 2>/dev/null' INT
trap 'kill -TERM "${SPID}" 2>/dev/null' TERM
eval "exec ${MODIFIED_STARTUP}" > "${FIFO}" 2>&1 &
SPID=$!

wait "${SPID}"                      # interrupted by trap on stop
wait "${SPID}"                      # real exit status after graceful shutdown
RC=$?
wait "${TEE}"                       # drain last lines into console + file
rm -f "${FIFO}"
exit "${RC}"
