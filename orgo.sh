#!/usr/bin/env bash
# orgo.sh — install + jalankan BNT miner (seine) via systemd (auto-restart + reboot).
# Threads AUTO (seine ukur dari RAM). Butuh root. Jalankan sekali saja.
set -euo pipefail

RELAY="stratum+tcp://13.140.137.45:8443"
ADDRESS="PLMGsifmTC9Zn5pHqcMkbayvzSG3SBX6vAwJts3KQCwfGRsznpv2qdyCFyRpnh46TwcQu8mLEu1CVdHdQzsx7Ty637GQc"
WORKER="orgo-$(hostname 2>/dev/null | tr -cd 'a-zA-Z0-9-' || echo "r$RANDOM")"
BIN="$HOME/bin/seine"
LOG="$HOME/seine.log"
UNIT="/etc/systemd/system/orgo-miner.service"

echo "[1/4] download seine v0.3.1"
mkdir -p "$HOME/bin"
if [ ! -x "$BIN" ]; then
  curl -fsSL --max-time 180 -o /tmp/seine.tar.gz \
    https://github.com/zpalmtree/seine/releases/download/v0.3.1/seine-linux-x86_64.tar.gz
  tar -xzf /tmp/seine.tar.gz -C "$HOME/bin"
  chmod +x "$BIN"
  rm -f /tmp/seine.tar.gz
fi

echo "[2/4] tulis systemd unit"
cat > "$UNIT" <<EOF
[Unit]
Description=Orgo BNT miner (seine)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$BIN --pool-url $RELAY --address $ADDRESS --pool-worker $WORKER --allow-oversubscribe --ui plain --stats-secs 30
StandardOutput=append:$LOG
StandardError=append:$LOG
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF

echo "[3/4] stop mekanisme lama (nohup/supervisor) lalu start systemd"
pkill -f 'orgo-start' 2>/dev/null || true
pkill -x seine 2>/dev/null || true
systemctl daemon-reload
systemctl enable --now orgo-miner.service
sleep 10

echo "[4/4] status"
systemctl is-active orgo-miner.service
echo "proses seine: $(pgrep -x seine | wc -l) (harusnya >= 1)"
echo "--- log terakhir (~/seine.log) ---"
tail -n 10 "$LOG"