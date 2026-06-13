# Tools-only Zephyr build environment for the SiFive HiFive1 Rev B.
#
# This image bakes only the TOOLS: west, Zephyr's Python build deps, and the
# RISC-V Zephyr SDK. It deliberately contains NO Zephyr workspace -- the source
# checkout (zephyr/, modules/, ...) lives on the host alongside your project and
# is fetched with `./dev.sh make update`. That keeps source on the host (owned
# by you) and only programs in the image. west.yml pins the Zephyr revision;
# this file pins the OS + SDK. Rebuild the image to change tool/SDK versions.
#
# Debian 13 (trixie), the latest stable release: system python3 is 3.13, well
# above Zephyr's minimum. The -slim variant stays small; build deps are added
# explicitly below.
FROM debian:trixie-slim
ENV DEBIAN_FRONTEND=noninteractive

# Host build deps (Zephyr getting-started, Debian/Ubuntu list) + git (west clones over
# git) + ca-certificates (TLS for clones and the SDK download).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget \
        python3-dev python3-pip python3-setuptools python3-wheel \
        xz-utils file make gcc libsdl2-dev libmagic1 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# No venv: a disposable container owns its whole Python environment, so install
# west system-wide. --break-system-packages overrides Debian's PEP 668
# "externally managed" guard, which only exists to protect a real host's python.
RUN pip install --break-system-packages --no-cache-dir west

# --- Harvest the pinned tools, then throw the source away ------------------
# We need Zephyr's revision-matched Python deps and the SDK, but NOT a baked
# workspace. So materialize a throwaway workspace from the pinned manifest,
# install the deps + SDK (which land in system site-packages and /opt, outside
# the temp dir), then delete the source. Copy ONLY west.yml first so this whole
# layer stays cached unless the manifest changes. --ignore-venv-check because
# there is no venv; the pip args after `--` reach pip itself.
COPY west.yml /tmp/west.yml
RUN mkdir -p /tmp/ws/.manifest \
 && cp /tmp/west.yml /tmp/ws/.manifest/west.yml \
 && git -C /tmp/ws/.manifest init -q \
 && git -C /tmp/ws/.manifest add west.yml \
 && git -C /tmp/ws/.manifest -c user.email=build@local -c user.name=build commit -qm pin \
 && cd /tmp/ws \
 && west init -l .manifest \
 && west update --narrow -o=--depth=1 \
 && west packages pip --install --ignore-venv-check -- --break-system-packages \
 && west sdk install --install-dir /opt/zephyr-sdk --toolchains riscv64-zephyr-elf \
 && cd / \
 && rm -rf /tmp/ws /tmp/west.yml /root/.cache
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
