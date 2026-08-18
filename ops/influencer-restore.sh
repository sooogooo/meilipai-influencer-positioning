#!/bin/bash
# 从金版本恢复站点(用于发布工具覆盖/误改后的还原)。
set -euo pipefail
GOLDEN=/opt/1panel/backup/influencer-golden
LIVE_INDEX=/opt/1panel/www/sites/influencer.meilipai.vip/index
LIVE_CONF=/opt/1panel/www/conf.d/influencer.meilipai.vip.conf
LOG=/var/log/influencer-watch.log

cd "$GOLDEN"
FAIL=$(sha256sum -c SHA256SUMS 2>/dev/null | grep -v ': OK$' || true)
[ -z "$FAIL" ] || { echo "[$(date '+%F %T')] 金版本自检失败,中止恢复:\n$FAIL" >> "$LOG"; exit 1; }

# 恢复 webroot(删除多余文件,与金版本完全一致)
rm -rf "$LIVE_INDEX"
cp -a "$GOLDEN/index" "$LIVE_INDEX"
# 恢复 nginx 站点 conf(1Panel 重新生成时会丢 sub_filter/缓存/安全头)
cp "$GOLDEN/influencer.conf" "$LIVE_CONF"

if docker exec 1Panel-openresty-Y8YC nginx -t 2>/dev/null; then
  docker exec 1Panel-openresty-Y8YC nginx -s reload
  echo "[$(date '+%F %T')] 已从金版本恢复站点并 reload nginx" >> "$LOG"
else
  echo "[$(date '+%F %T')] 恢复后 nginx -t 失败!conf 保留在 $GOLDEN/influencer.conf 待人工检查" >> "$LOG"
  exit 1
fi
