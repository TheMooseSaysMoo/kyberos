#!/usr/bin/env bash
# Grab a libvirt test VM's framebuffer (dev helper for README screenshots).
# usage: VM_HOST=<ssh host running libvirt> tools/vmshot.sh <domain> [out.png]
set -euo pipefail
: "${VM_HOST:?set VM_HOST to the ssh host that runs libvirt}"
dom=${1:?usage: VM_HOST=host tools/vmshot.sh <domain> [out.png]}
out=${2:-vmshot.png}
ssh "$VM_HOST" "virsh screenshot '$dom' /tmp/kyberos-shot.img >/dev/null && cat /tmp/kyberos-shot.img && rm -f /tmp/kyberos-shot.img" |
    python3 -c "import io, sys; from PIL import Image; Image.open(io.BytesIO(sys.stdin.buffer.read())).save(sys.argv[1])" "$out"
echo "$out"
