#!/bin/bash
# 定时巡检:发现站点文件/关键 conf 与金版本不一致 → 自动恢复。
# 维护模式:touch /opt/1panel/backup/influencer-golden/.maintenance 暂停巡检。
set -uo pipefail
GOLDEN=/opt/1panel/backup/influencer-golden
LIVE_INDEX=/opt/1panel/www/sites/influencer.meilipai.vip/index
LIVE_CONF=/opt/1panel/www/conf.d/influencer.meilipai.vip.conf
LOG=/var/log/influencer-watch.log

[ -f "$GOLDEN/.maintenance" ] && exit 0
[ -f "$GOLDEN/SHA256SUMS" ] || exit 0

CHANGED=0
while read -r sum path; do
  case "$path" in
    influencer.conf) lp="$LIVE_CONF" ;;
    index/*) lp="$LIVE_INDEX/${path#index/}" ;;
    *) continue ;;
  esac
  [ -f "$lp" ] || { CHANGED=1; break; }
  cur=$(sha256sum "$lp" | awk '{print $1}')
  [ "$cur" = "$sum" ] || { CHANGED=1; break; }
done < <(cd "$GOLDEN" && awk '$2!="SHA256SUMS"{print $1, $2}' SHA256SUMS)

# conf 里 sub_filter 段被 1Panel 重生成丢掉也视为被篡改
if ! grep -q "sub_filter '</body>'" "$LIVE_CONF" 2>/dev/null; then CHANGED=1; fi

if [ "$CHANGED" = 1 ]; then
  echo "[$(date '+%F %T')] 检测到站点与金版本不一致,执行恢复…" >> "$LOG"
  /usr/local/bin/influencer-restore.sh >> "$LOG" 2>&1
fi
