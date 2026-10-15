FROM debian:trixie-slim

# Drop-in replacement for ghcr.io/ptero-eggs/steamcmd:proton (same paths, user
# and entrypoint), with every download pinned instead of "latest at build
# time". Upstream's scheduled builds were disabled for inactivity on
# 2026-06-22, which froze it on GE-Proton10-34 (no SteamUtils011, breaks
# Enshrouded since 2026-10-15). Trixie instead of bookworm: GE-Proton 11 needs
# glibc >= 2.38.
#
# GE_PROTON_* is bumped by .github/workflows/bump-proton.yml.
ARG GE_PROTON_VERSION=GE-Proton11-9
ARG GE_PROTON_SHA512=30160946a5e4ffdf1f29d6f83a3d27108f6aa71b6aa59095b2c2260fe3a003b62acf8fdcb02a3dfc602b28473f5679d8a3eaee5a8adb141c1dfa01c42888da2d
ARG WINETRICKS_VERSION=20260125
ARG PROTONTRICKS_VERSION=1.15.0
ARG RCON_VERSION=0.10.3

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wget iproute2 gnupg2 libntlm0 winbind xvfb xauth \
        libncurses5-dev:i386 libncurses6 dbus libgdiplus lib32gcc-s1 \
        alsa-tools libpulse0 pulseaudio libpulse-dev libasound2t64 libao-common gnutls-bin \
        locales numactl cabextract curl ca-certificates python3 python3-pip \
        python3-setuptools tini file pipx \
        # GE-Proton 11's launcher dlopens libvulkan.so.1 at startup
        libvulkan1 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -d /home/container -m container

# GE-Proton into /usr/local/bin (eggs call /usr/local/bin/proton)
RUN curl -fsSL -o /tmp/proton.tar.gz \
        "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${GE_PROTON_VERSION}/${GE_PROTON_VERSION}-x86_64.tar.gz" \
    && echo "${GE_PROTON_SHA512}  /tmp/proton.tar.gz" | sha512sum -c - \
    && tar -xzf /tmp/proton.tar.gz -C /usr/local/bin/ --strip-components=1 \
    && rm /tmp/proton.tar.gz \
    && echo "${GE_PROTON_VERSION}" > /usr/local/bin/ge-proton-version

# Proton machine-id fix
RUN rm -f /etc/machine-id /var/lib/dbus/machine-id \
    && dbus-uuidgen --ensure=/etc/machine-id \
    && dbus-uuidgen --ensure

RUN pipx install "protontricks==${PROTONTRICKS_VERSION}"

RUN curl -fsSL -o /usr/sbin/winetricks \
        "https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks" \
    && chmod +x /usr/sbin/winetricks

RUN curl -fsSL "https://github.com/gorcon/rcon-cli/releases/download/v${RCON_VERSION}/rcon-${RCON_VERSION}-amd64_linux.tar.gz" \
        | tar -xz -C /tmp \
    && mv "/tmp/rcon-${RCON_VERSION}-amd64_linux/rcon" /usr/local/bin/ \
    && rm -rf "/tmp/rcon-${RCON_VERSION}-amd64_linux"

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

STOPSIGNAL SIGINT

# Upstream Ptero-Eggs/yolks steamcmd/entrypoint.sh plus an Xvfb display for Proton
COPY --chown=container:container --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
