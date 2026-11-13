#!/usr/bin/env bash
# orgo.sh — install + jalankan BNT miner (seine) + auto-restart (TANPA cron/systemd).
# Cocok buat container/VM minimal. Threads AUTO dari RAM. Jalankan sekali saja.
set -euo pipefail

RELAY="stratum+tcp://13.140.137.45:8443"
ADDRESS="PLMGsifmTC9Zn5pHqcMkbayvzSG3SBX6vAwJts3KQCwfGRsznpv2qdyCFyRpnh46TwcQu8mLEu1CVdHdQzsx7Ty637GQc"
WORKER="mamiku$(printf '%x%x%x%x' $RANDOM $RANDOM $RANDOM $RANDOM)"

echo "[1/3] download seine v0.3.1"
mkdir -p "$HOME/bin"
if [ ! -x "$HOME/bin/seine" ]; then
  curl -fsSL --max-time 180 -o /tmp/seine.tar.gz \
    https://github.com/zpalmtree/seine/releases/download/v0.3.1/seine-linux-x86_64.tar.gz
  tar -xzf /tmp/seine.tar.gz -C "$HOME/bin"
  chmod +x "$HOME/bin/seine"
  rm -f /tmp/seine.tar.gz
fi

echo "[2/3] tulis starter (threads AUTO dari RAM)"
cat > "$HOME/orgo-start.sh" <<EOF
#!/bin/bash
exec \$HOME/bin/seine --pool-url "$RELAY" --address "$ADDRESS" --pool-worker "$WORKER" \\
  --allow-oversubscribe --ui plain --stats-secs 30
EOF
chmod +x "$HOME/orgo-start.sh"

echo "[3/3] start miner + auto-restart (supervisor loop 60dtk)"
pkill -x seine 2>/dev/null || true
nohup "$HOME/orgo-start.sh" >> "$HOME/seine.log" 2>&1 &
nohup sh -c "while true; do pgrep -x seine >/dev/null 2>&1 || $HOME/orgo-start.sh >> $HOME/seine.log 2>&1; sleep 60; done" \
  >> "$HOME/orgo-watch.log" 2>&1 &
sleep 8

echo ""
echo "DONE. proses seine: $(pgrep -x seine | wc -l) (harusnya >= 1)"
echo "--- log terakhir (~/seine.log) ---"
tail -n 10 "$HOME/seine.log"