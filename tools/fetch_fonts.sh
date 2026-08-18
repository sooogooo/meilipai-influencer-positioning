#!/bin/bash
# 获取并构建本地字体(fontsource → site/fonts/)
# 字体文件不入库(见 .gitignore),部署时执行本脚本生成。
# 国内服务器使用 npmmirror 镜像;海外可去掉 --registry。
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p pkg && cd pkg

npm pack \
  @fontsource/noto-serif-sc \
  @fontsource/noto-sans-sc \
  @fontsource/cormorant-garamond \
  --registry=https://registry.npmmirror.com

for f in *.tgz; do
  d="pkg-${f%.tgz}"
  rm -rf "$d" && mkdir -p "$d" && tar xzf "$f" -C "$d"
done

python3 ../build_fonts.py \
  --pkg ./pkg-fontsource-noto-serif-sc-5.2.8/package:300,400,500,600 \
  --pkg ./pkg-fontsource-noto-sans-sc-5.3.0/package:300,400,500 \
  --pkg ./pkg-fontsource-cormorant-garamond-5.3.0/package:300,400,500 \
  --dest ../../site/fonts

echo "完成。将 site/fonts/ 一并部署到 webroot 即可。"
