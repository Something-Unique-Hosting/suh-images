FROM ghcr.io/parkervcp/games:valheim

# Same image as upstream, replaced entrypoint:
#  - stop signal (SIGINT/SIGTERM) is forwarded to the game process only, so a
#    logging tee is not killed alongside it and shutdown/save output is kept
#  - optional LOG_FILE env (strftime tokens allowed) tees console output to a file
COPY --chmod=755 entrypoint.sh /entrypoint.sh
