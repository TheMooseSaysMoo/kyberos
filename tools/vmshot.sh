#!/usr/bin/env bash
# Grab the KyberOS-Test VM framebuffer from Unraid (dev helper; virtio-gpu gives PNG).
# usage: tools/vmshot.sh out.png
set -euo pipefail
out=${1:-vmshot.png}
ssh unraid 'virsh screenshot KyberOS-Test /tmp/kyberos-shot.png >/dev/null && cat /tmp/kyberos-shot.png && rm -f /tmp/kyberos-shot.png' > "$out"
echo "$out"
