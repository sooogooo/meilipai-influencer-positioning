#!/bin/bash
# 刷新金版本:把当前线上状态固化为恢复基准。
# 用法:改完站点文件后执行;会自动解除维护暂停。
set -euo pipefail
GOLDEN=/opt/1panel/backup/influencer-golden
LIVE_INDEX=/opt/1panel/www/sites/influencer.meilipai.vip/index
LIVE_CONF=/opt/1panel/www/conf.d/influencer.meilipai.vip.conf

rm -rf "$GOLDEN/index"
cp -a "$LIVE_INDEX" "$GOLDEN/index"
cp "$LIVE_CONF" "$GOLDEN/influencer.conf"
cd "$GOLDEN"
find index -type f -exec sha256sum {} \; > SHA256SUMS
sha256sum influencer.conf >> SHA256SUMS
rm -f "$GOLDEN/.maintenance"
echo "[$(date '+%F %T')] 金版本已刷新: $(wc -l < SHA256SUMS) 个文件"
