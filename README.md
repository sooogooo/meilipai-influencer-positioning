# 医美博主定位评估 · Meilipai Influencer Positioning

> 信任五型 × 变现五式 = 25 格定位矩阵。12 道题,看清你的信任从哪来、钱从哪来。
>
> 线上地址:<https://influencer.meilipai.vip/>

一个**零收集、纯静态**的达人/医美博主定位测评工具。无账号、无埋点、无 Cookie,答题与计分全部在浏览器本地完成;服务器只分发静态文件。隐私立场见 [`site/privacy.html`](site/privacy.html)。

## 功能特性

- **双模式测评**
  - 极简评测:固定 12 道原题,适合快速自测与纵向对比(默认)
  - 进阶评测:从 132 题分类题库按槽位随机抽题,组合千亿级,背题无效
- **25 格定位矩阵**:信任五型(执业资质/亲身体验/信息差/审美判断/产业视角)× 变现五式(C端付费/B端广告/渠道返佣/自营/暂不变现),每格有名字、判词与稳定度标记
- **信任贴现率**:0-100 经验刻度,变现方式基线 + 七个风险刻度(机构依赖/披露缺失/私信导流/收钱质疑/互动背离/转化停滞/存量缺失)加权
- **完整分享体系**
  - 移动端系统分享面板(`navigator.share`),桌面/微信内置浏览器降级复制链接
  - 分享长图:canvas 绘制,底部带二维码(ECC H + 中心 logo)
  - **动态分享卡片**:结果链接 `?r=格名-贴现率` 由 OpenResty Lua 白名单校验后动态替换 og 标签——微信里收到的是个性化卡片,零后端零存储
- **评测原理页 / 隐私声明页**:模型、矩阵、题库与评分规则全公开
- **重新发布防护**:金版本 + SHA256 巡检,发布工具覆盖站点后 5 分钟内自动恢复

## 架构

页面主体是 AI 建站工具产出的**打包器(bundle)SPA**:真实页面存放在 `index.html` 内的 `__bundler/template` JSON 里,运行时经 DOMParser + `documentElement.replaceWith()` 整体替换文档。因此本项目的大部分定制以「补丁 + 注入」方式实现:

```
浏览器
 ├─ loader HTML(head: favicon/og/JSON-LD/本地字体)
 │   └─ 打包器脚本 → 解包模板 → 整体替换 document
 │        └─ 模板内补丁:132 题槽位题库 / rollQ / makeCard 二维码 /
 │           shareLink 系统分享 / 双模式 / 深链版本号
 └─ OpenResty (nginx)
      ├─ sub_filter 注入 footer.js → 顶栏(logo+导航)+ 底栏(备案)
      │   └─ MutationObserver 观察 document 节点,DOM 替换后自愈
      ├─ set_by_lua_block + sub_filter → ?r= 动态 og 卡片(25 格名白名单)
      ├─ 缓存策略(图 7d / 字体 30d)+ 安全响应头
      └─ 金版本巡检(cron)+ 自动恢复
```

关键工程约束:`scoreOf` 的信任分与风险向量跨题**累加**,阈值按"每风险键恰好一题"标定——所以题库按 **12 个测量槽位 × 11 道同构题**组织,每槽位内选项权重模式完全一致,随机抽题不改变计分语义。详见 [`tools/bank_build.py`](tools/bank_build.py)(含权重模式校验器与 500 次随机抽样计分仿真)。

## 目录结构

```
├── site/                      # 部署即用的 webroot(原样镜像生产环境)
│   ├── index.html             # 打包器 SPA(题库/逻辑在内)
│   ├── footer.js              # 注入式顶栏+底栏 chrome(自愈)
│   ├── principles.html        # 评测原理(矩阵/公式/题库规则)
│   ├── privacy.html           # 隐私声明
│   ├── 404.html / robots.txt / sitemap.xml
│   ├── logo.png / favicon* / share-icon.png / share-qr.png
│   └── fonts/                 # 由 tools/fetch_fonts.sh 构建,不入库
├── nginx/
│   └── influencer.meilipai.vip.conf   # 完整站点配置(含 Lua 动态卡片)
├── tools/
│   ├── bank_build.py          # 题库构建 + 结构校验 + 计分仿真
│   ├── fetch_fonts.sh         # fontsource(npmmirror)→ site/fonts/
│   └── build_fonts.py         # woff2 子集 + fonts.css 生成器
├── ops/                       # 生产运维脚本(金版本防护体系)
│   ├── influencer-watch.sh        # 巡检:不一致 → 自动恢复(可 .maintenance 暂停)
│   ├── influencer-restore.sh      # 从金版本恢复站点与 conf
│   └── influencer-golden-update.sh# 改动后刷新金版本(解除维护暂停)
└── .github/workflows/validate.yml # CI:题库结构 + 线上模板一致性校验
```

## 部署

依赖:OpenResty(含 lua-nginx-module 与 http_sub_module)。

1. **字体**:`tools/fetch_fonts.sh` 生成 `site/fonts/`(国内走 npmmirror)
2. 把 `site/` 内容放到 webroot(示例 conf 中的路径为 1Panel 惯例:`/opt/1panel/www/sites/<域名>/index/` ↔ 容器内 `/www/...`)
3. 站点 conf 放入 OpenResty 的 `conf.d/`,替换证书路径后 `nginx -t && nginx -s reload`
4. **conf 中需要按环境调整**:证书路径、域名、以及 `sub_filter '</body>'` 等 注入段——1Panel 之类面板重新生成 conf 会丢掉自定义段
5. (可选,防重新发布覆盖)`ops/` 三脚本放到 `/usr/local/bin/`,金版本目录 + cron 每 5 分钟巡检:
   ```
   */5 * * * * root /usr/local/bin/influencer-watch.sh >/dev/null 2>&1
   ```
   **改动站点前先 `touch <金版本目录>/.maintenance`,改完执行 `influencer-golden-update.sh`**,否则巡检器会把编辑当篡改回滚

## 题库与评分速览

| 分类 | 槽位(测量维度) | 计分 |
|---|---|---|
| 信任从哪来 | 评论区之问 / 杀伤攻击 / 读者画像 | 单选,选项给对应信任型 2-3 分 |
| 内容与定位 | 内容高频主题 | 单选,2 分 |
| 钱从哪来 | 收入结构 / 机构依赖 | 定变现方式 / 0-3 刻度 |
| 商务边界 | 合作披露 / 私信导流 | 0-3 刻度 |
| 信任健康度 | 质疑频率 / 互动背离 | 0-3 刻度 |
| 长期筹码 | 转化周期 / 停更存量 | 0-2 / 0-1-3 刻度 |

```
贴现率 = 基线[变现方式](C2C 8 / NONE 6 / AD 22 / OWN 26 / REB 40)
       + 机构依赖×4 + 披露缺失×5 + 私信导流×4
       + 收钱质疑×5 + 互动背离×4 + 转化停滞×3 + 存量缺失×4     (上限 100)
清晰度 = 主副信任分差:≥3 清晰 / ≥1.5 偏向明显 / 否则模糊
判定   = 返佣列高危;8 个结构稳定格为稳;其余过渡态
```

结果深链 `#a=答案&q=题组id&v=版本`:跨会话还原同一题组再计分,支持"对比上次";题库演进靠版本号拒绝失效链接。

## 隐私

不搜集任何用户信息:无账号、无表单上传、无统计埋点、无 Cookie、无 localStorage 持久化。作答只存在于浏览器内存;分享(长图/链接)均由用户主动触发。服务器为纯静态分发。唯一外部依赖已消除——**字体自托管**。

## License

[MIT](LICENSE) © sooogooo · 美丽派 · 美学实验室
