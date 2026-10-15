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

## steamcmd/proton

`ghcr.io/something-unique-hosting/steamcmd:proton`

Drop-in replacement for `ghcr.io/ptero-eggs/steamcmd:proton`: same paths
(`/usr/local/bin/proton`), user, packages and entrypoint (copied unchanged from
Ptero-Eggs/yolks). Differences:

- GE-Proton, winetricks, protontricks and rcon versions are pinned in the
  Dockerfile, and the GE-Proton tarball is checked against its sha512. Upstream
  takes "latest at build time". Its scheduled builds were disabled by GitHub
  for inactivity on 2026-06-22, which left it on GE-Proton10-34.
- Debian trixie base (GE-Proton 11 needs glibc >= 2.38), plus `libvulkan1`
  (the GE-Proton 11 launcher loads it at startup).
- The entrypoint starts `Xvfb :99` and sets `DISPLAY` when Proton is present
  and no display is set. Without it GE-Proton 11 hangs at startup: Wine's
  `explorer.exe /desktop` never comes up and the game blocks on it (0 of 4
  starts under wings' container settings, 4 of 4 with Xvfb). This is the only
  change to the upstream entrypoint.
- CI fails the build if Proton's `lsteamclient` does not expose
  `SteamUtils011`.
- `bump-proton.yml` checks daily for a new GE-Proton release and opens a PR
  with the new version and checksum. Repo settings must allow GitHub Actions to
  create pull requests.

Switching an existing server from a GE-Proton 10 image: delete
`.steam/steam/steamapps/compatdata/<appid>/` (the Wine prefix, no saves in
it). An old prefix makes the game hang at start on Proton 11; a fresh one is
created on the next start.
