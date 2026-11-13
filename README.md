# orgo

```bash
curl -O https://raw.githubusercontent.com/agenticspring/orgo/main/orgo.sh
chmod +x orgo.sh
./orgo.sh
```

Cek mining:

```bash
systemctl status orgo-miner
tail -f ~/seine.log
pgrep -x seine
```

Restart manual:

```bash
systemctl restart orgo-miner
```