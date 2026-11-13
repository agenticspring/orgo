#!/usr/bin/env bash
# orgo.sh — install + jalankan BNT miner (seine) ke relay, auto-restart.
# Threads AUTO-deteksi: seine ukur sendiri dari RAM (2 GB/thread). Jalankan sekali saja.
set -euo pipefail

RELAY="stratum+tcp://13.140.137.45:8443"
ADDRESS="PLMGsifmTC9Zn5pHqcMkbayvzSG3SBX6vAwJts3KQCwfGRsznpv2qdyCFyRpnh46TwcQu8mLEu1CVdHdQzsx7Ty637GQc"
WORKER="orgo-$(hostname 2>/dev/null | tr -cd 'a-zA-Z0-9-' || echo "r$RANDOM")"

echo "[1/4] download seine v0.3.1"
mkdir -p "$HOME/bin"
if [ ! -x "$HOME/bin/seine" ]; then
  curl -fsSL --max-time 180 -o /tmp/seine.tar.gz \
    https://github.com/zpalmtree/seine/releases/download/v0.3.1/seine-linux-x86_64.tar.gz
  tar -xzf /tmp/seine.tar.gz -C "$HOME/bin"
  chmod +x "$HOME/bin/seine"
  rm -f /tmp/seine.tar.gz
fi

echo "[2/4] tulis starter (threads AUTO dari RAM)"
cat > "$HOME/orgo-start.sh" <<EOF
#!/bin/bash
exec \$HOME/bin/seine --pool-url "$RELAY" --address "$ADDRESS" --pool-worker "$WORKER" \\
  --allow-oversubscribe --ui plain --stats-secs 30
EOF
chmod +x "$HOME/orgo-start.sh"

echo "[3/4] start miner"
pkill -x seine 2>/dev/null || true
nohup "$HOME/orgo-start.sh" >> "$HOME/seine.log" 2>&1 &
sleep 8

echo "[4/4] pasang auto-restart (tiap menit + @reboot)"
( crontab -l 2>/dev/null | grep -v 'orgo-start'; \
  echo "@reboot \$HOME/orgo-start.sh >> \$HOME/seine.log 2>&1"; \
  echo "* * * * * pgrep -x seine >/dev/null || \$HOME/orgo-start.sh >> \$HOME/seine.log 2>&1" ) \
  | crontab -

echo ""
echo "DONE. proses seine: $(pgrep -x seine | wc -l) (harusnya >= 1)"
echo "--- log terakhir (~/seine.log) ---"
tail -n 10 "$HOME/seine.log"