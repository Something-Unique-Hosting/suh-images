# suh-images

Game server Docker images for the SUH Calagopus panel. Each image is a thin layer
over the matching `ghcr.io/parkervcp/games:*` image with a replaced entrypoint.

Images are published to `ghcr.io/something-unique-hosting/games:<game>` on every
push to `main` and rebuilt weekly to pick up upstream changes.

## games/valheim

`ghcr.io/something-unique-hosting/games:valheim`

Entrypoint changes compared to upstream:

- The stop signal is forwarded to the game process only. Upstream uses `tini -g`,
  which signals the whole process group, so any `| tee` in the startup command
  dies together with the game and the shutdown/save output is lost.
- Optional `LOG_FILE` environment variable. When set, console output is also
  appended to that file. `strftime` tokens are allowed, e.g.
  `logs/valheim-%Y-%m-%d_%H%M%S.log`. Empty or unset means console only, and the
  game is `exec`ed directly as before.
- Optional `LOG_KEEP` environment variable (default `10`, `0` = keep everything).
  Number of log files kept, including the one being written. With a timestamped
  `LOG_FILE` the oldest matching files are deleted at boot. With a static
  `LOG_FILE` the file is shifted to `.1`, `.2`, ... at boot. Rotation happens on
  start only, not while the server runs.

The egg startup command stays the stock one. Do not add `-logfile`; it makes the
game write to the file instead of the console.
