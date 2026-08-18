/* 站点 chrome:顶栏(logo + 站名)+ 底栏(备案信息)。
   由 nginx sub_filter 注入到每个 HTML 页面。
   页面是打包器运行时整体替换 document 的 SPA,因此用 MutationObserver
   观察 document 节点(它永不替换)自愈补挂。
   z-index 70/71:低于应用弹窗(80)与 toast(99999),弹窗可正常遮盖。 */
(function () {
  var HID = 'site-header', FID = 'site-icp-footer';

  function el(tag, id, cls) {
    var e = document.createElement(tag);
    if (id) e.id = id;
    if (cls) e.className = cls;
    return e;
  }

  function makeHeader() {
    var h = el('div', HID);
    var st = el('style');
    st.textContent =
      '#' + HID + '{position:fixed;top:0;left:0;right:0;z-index:70;height:54px;' +
      'display:flex;align-items:center;justify-content:space-between;gap:10px;padding:0 18px;' +
      'background:rgba(251,247,240,.94);backdrop-filter:blur(10px);' +
      '-webkit-backdrop-filter:blur(10px);' +
      'border-bottom:1px solid rgba(185,148,63,.35);' +
      'box-shadow:0 1px 14px rgba(74,18,32,.05);}' +
      '#' + HID + ' a{text-decoration:none}' +
      '#' + HID + ' .brand{display:flex;align-items:center;gap:9px;min-width:0}' +
      '#' + HID + ' img{width:30px;height:30px;border-radius:50%;display:block;flex:none}' +
      '#' + HID + ' .wm{font-family:"Noto Serif SC","Songti SC",serif;font-size:15px;' +
      'font-weight:500;letter-spacing:.18em;color:#1C1821;white-space:nowrap}' +
      '#' + HID + ' nav{display:flex;align-items:center;gap:4px;flex:none}' +
      '#' + HID + ' nav a{font-family:"Noto Sans SC","PingFang SC",sans-serif;font-size:12.5px;' +
      'letter-spacing:.1em;color:#6B6470;padding:8px 10px;border-radius:6px;' +
      'transition:color .18s,background .18s;white-space:nowrap}' +
      '#' + HID + ' nav a:hover{color:#8F2338;background:rgba(143,35,56,.06);text-decoration:none}' +
      '@media(max-width:640px){#' + HID + '{padding:0 12px}' +
      '#' + HID + ' nav a{font-size:12px;padding:8px 7px;letter-spacing:.04em}' +
      '#' + HID + ' .wm{font-size:13px;letter-spacing:.05em}}';
    var brand = document.createElement('a');
    brand.className = 'brand'; brand.href = '/';
    var img = document.createElement('img');
    img.src = '/logo.png'; img.alt = '医美博主定位评估';
    var wm = el('span', null, 'wm'); wm.textContent = '医美博主定位评估';
    brand.appendChild(img); brand.appendChild(wm);
    var nav = el('nav');
    var a1 = document.createElement('a');
    a1.href = '/principles.html'; a1.textContent = '评测原理';
    var a2 = document.createElement('a');
    a2.href = '/privacy.html'; a2.textContent = '隐私声明';
    nav.appendChild(a1); nav.appendChild(a2);
    h.appendChild(st); h.appendChild(brand); h.appendChild(nav);
    return h;
  }

  function makeFooter() {
    var f = el('div', FID);
    var st = el('style');
    st.textContent =
      '#' + FID + '{position:fixed;left:0;right:0;bottom:0;z-index:71;' +
      'box-sizing:border-box;padding:6px 12px;text-align:center;' +
      'font:12px/1.6 -apple-system,BlinkMacSystemFont,"Noto Sans SC",sans-serif;' +
      'color:#8d857c;background:rgba(250,249,245,.92);' +
      'border-top:1px solid rgba(60,53,64,.08);backdrop-filter:blur(4px);' +
      '-webkit-backdrop-filter:blur(4px);}' +
      '#' + FID + ' a{color:#8d857c;text-decoration:none;}' +
      '#' + FID + ' a:hover{color:#B9943F;text-decoration:underline;}' +
      '@media(max-width:640px){#' + FID + '{font-size:11px;line-height:1.5}}' +
      /* 给固定栏让位:顶栏 54px、底栏约 38px */
      'body{padding-top:54px !important;padding-bottom:42px !important}';
    var icp = document.createElement('a');
    icp.href = 'https://beian.miit.gov.cn/';
    icp.target = '_blank';
    icp.rel = 'noopener noreferrer';
    icp.textContent = '京ICP备20009050号-2';
    var mail = document.createElement('a');
    mail.href = 'mailto:sooogooo@139.com';
    mail.textContent = 'sooogooo@139.com';
    f.appendChild(st);
    f.appendChild(icp);
    f.appendChild(document.createTextNode(' · © 2026 美学实验室 | 美丽派 · 联系：'));
    f.appendChild(mail);
    f.appendChild(document.createTextNode(' · 微信：@sooogooo'));
    return f;
  }

  var builders = [[HID, makeHeader], [FID, makeFooter]];

  function ensure() {
    if (!document.body) return;
    builders.forEach(function (b) {
      if (!document.getElementById(b[0])) document.body.appendChild(b[1]());
    });
  }

  ensure();
  new MutationObserver(ensure).observe(document, {
    childList: true,
    subtree: true
  });
})();
