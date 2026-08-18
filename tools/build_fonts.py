#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 fontsource 包构建为自托管字体目录(fonts.css + woff2 子集)。

用法:
  python3 build_fonts.py --pkg <package-dir>:<w1,w2...> [--pkg ...] --dest <dir>

生成 <dest>/fonts.css(仅 woff2、绝对路径 /fonts/files/)与 <dest>/files/*.woff2。
浏览器按 unicode-range 只下载用到的子集。
"""
import argparse
import os
import re
import shutil


def build(pkgs, dest):
    os.makedirs(os.path.join(dest, 'files'), exist_ok=True)
    css_out, copied, total = [], set(), 0
    for pkg, weights in pkgs:
        for w in weights:
            css = open(os.path.join(pkg, f'{w}.css'), encoding='utf-8').read()
            blocks = re.findall(r'(/\* [^*]+ \*/\s*@font-face \{[^}]+\})', css)
            assert blocks, f'{pkg} {w} 无 @font-face'
            for b in blocks:
                m = re.search(r'url\(\./files/([^)]+\.woff2)\)', b)
                assert m, b[:120]
                f = m.group(1)
                if f not in copied:
                    shutil.copy(os.path.join(pkg, 'files', f),
                                os.path.join(dest, 'files', f))
                    copied.add(f)
                    total += os.path.getsize(os.path.join(pkg, 'files', f))
                b2 = re.sub(
                    r'src: url\(\./files/[^)]+\) format\([^)]+\)(, url\(\./files/[^)]+\) format\([^)]+\))?,',
                    "src: url(/fonts/files/%s) format('woff2');" % f, b)
                css_out.append(b2)
    with open(os.path.join(dest, 'fonts.css'), 'w', encoding='utf-8') as fp:
        fp.write('\n'.join(css_out))
    print(f'fonts.css: {len(css_out)} 个 @font-face,'
          f'{len(copied)} 个 woff2,共 {total / 1048576:.1f} MB')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--pkg', action='append', required=True,
                    help='fontsource 包目录:逗号分隔字重,可多次传入')
    ap.add_argument('--dest', required=True)
    args = ap.parse_args()
    build([tuple([p.split(':')[0], p.split(':')[1].split(',')]) for p in args.pkg],
          args.dest)
