// Draws the app icon and the Google Play store graphics from vector art.
//
// Run from the repo root:  node store/tool/make_assets.mjs
// Needs Playwright with Chromium (npm i -g playwright && npx playwright install chromium).
//
// Writes:
//   android/app/src/main/res/mipmap-*/ic_launcher*.png   (legacy + adaptive layers)
//   android/app/src/main/res/values/ic_launcher_background.xml
//   ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
//   store/*.png                                            (Play Store listing)

import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';

const require = createRequire(import.meta.url);
let playwright;
try {
  playwright = require('playwright');
} catch {
  const globalRoot = require('child_process').execSync('npm root -g').toString().trim();
  playwright = require(path.join(globalRoot, 'playwright'));
}

const root = process.cwd();
const res = path.join(root, 'android/app/src/main/res');
const iosDir = path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset');
const storeDir = path.join(root, 'store');

// Colours follow lib/core/theme/app_theme.dart.
const C = {
  bgTop: '#6A5CF0',
  bgBottom: '#3A2FB0',
  ink: '#1D1A33',
  bowl: '#F26B21',
  bowlDark: '#C4470C',
  bowlInside: '#8A2F06',
  paper: '#FFF8EC',
  paperEdge: '#E9DCC5',
  primary: '#4A3FCF',
  yellow: '#FFC83D',
  pink: '#FF5C8A',
  mint: '#3DDC97',
};

// ---- Artwork, all in a 108x108 box (the Android adaptive icon grid). ----
// Everything important sits inside the 66-unit safe circle around (54,54).

const background = `
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0.35" y2="1">
      <stop offset="0" stop-color="${C.bgTop}"/>
      <stop offset="1" stop-color="${C.bgBottom}"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.42" r="0.5">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="108" height="108" fill="url(#bg)"/>
  <circle cx="54" cy="50" r="40" fill="url(#glow)"/>`;

function slip(x, y, w, h, angle, content = '') {
  return `
  <g transform="rotate(${angle} ${x + w / 2} ${y + h})">
    <rect x="${x}" y="${y + 1.2}" width="${w}" height="${h}" rx="2" fill="${C.ink}" opacity="0.18"/>
    <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="2" fill="${C.paper}"/>
    <path d="M${x + w - 5} ${y} h5 v5 z" fill="${C.paperEdge}"/>
    ${content}
  </g>`;
}

// mono=true draws the single-colour silhouette for Android 13 themed icons.
function foreground({ mono = false } = {}) {
  const fill = (c) => (mono ? '#FFFFFF' : c);
  const lines = (x, y) => mono ? '' : `
    <rect x="${x}" y="${y}" width="9" height="1.6" rx="0.8" fill="${C.paperEdge}"/>
    <rect x="${x}" y="${y + 4}" width="6" height="1.6" rx="0.8" fill="${C.paperEdge}"/>`;
  const question = mono ? '' : `
    <text x="54" y="46.5" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif"
          font-weight="bold" font-size="17" fill="${C.primary}">?</text>`;
  const confetti = mono ? '' : `
    <circle cx="30" cy="36" r="2.2" fill="${C.yellow}"/>
    <rect x="76" y="31" width="4" height="4" rx="1" fill="${C.mint}" transform="rotate(25 78 33)"/>
    <circle cx="80" cy="47" r="1.8" fill="${C.pink}"/>
    <rect x="25" y="48" width="3.6" height="3.6" rx="1" fill="${C.pink}" transform="rotate(-20 27 50)"/>
    <path d="M70 24 l1.6 3.4 3.6 .5 -2.6 2.5 .6 3.6 -3.2 -1.7 -3.2 1.7 .6 -3.6 -2.6 -2.5 3.6 -.5z" fill="${C.yellow}"/>`;

  // Slips are drawn in a mono-safe way: in mono mode they are cut out of the bowl
  // with a mask so the silhouette still reads as "papers in a bowl".
  const slips = mono ? `
    <g fill="#FFFFFF">
      <rect x="33" y="36" width="15" height="24" rx="2" transform="rotate(-18 40.5 60)"/>
      <rect x="45.5" y="29" width="17" height="30" rx="2"/>
      <rect x="60" y="36" width="15" height="24" rx="2" transform="rotate(16 67.5 60)"/>
    </g>` : `
    ${slip(33, 36, 15, 24, -18, lines(35.5, 42))}
    ${slip(60, 36, 15, 24, 16, lines(62.5, 42))}
    ${slip(45.5, 29, 17, 30, 0, question)}`;

  return `
  ${confetti}
  <!-- bowl inside (behind the slips) -->
  <ellipse cx="54" cy="58" rx="27" ry="6.5" fill="${fill(C.bowlInside)}"/>
  ${slips}
  <!-- foot, then bowl body -->
  <rect x="44" y="78" width="20" height="6" rx="2.5" fill="${fill(C.bowlDark)}"/>
  <!-- bowl body -->
  <path d="M27 58 h54 c0 14 -11.5 23.5 -27 23.5 s-27 -9.5 -27 -23.5 z" fill="${fill(C.bowl)}"/>
  ${mono ? '' : `<path d="M27 58 h54 c0 3 -.6 5.8 -1.6 8.4 c-6 3.2 -15 5 -25.4 5 s-19.4 -1.8 -25.4 -5 c-1 -2.6 -1.6 -5.4 -1.6 -8.4 z" fill="#FFFFFF" opacity="0.12"/>`}
  <!-- rim -->
  <path d="M26 58 a28 7 0 0 0 56 0 a28 7 0 0 1 -56 0" fill="${fill(C.bowlDark)}"/>
  <rect x="25" y="55.8" width="58" height="4.4" rx="2.2" fill="${fill(C.bowlDark)}"/>
  ${mono ? '' : `<rect x="29" y="56.6" width="20" height="1.4" rx="0.7" fill="#FFFFFF" opacity="0.35"/>`}
  <!-- a smile on the bowl -->
  ${mono ? '' : `
  <circle cx="46" cy="67" r="1.9" fill="${C.ink}"/>
  <circle cx="62" cy="67" r="1.9" fill="${C.ink}"/>
  <path d="M48.5 71.5 q5.5 4.5 11 0" stroke="${C.ink}" stroke-width="1.8" fill="none" stroke-linecap="round"/>
  <circle cx="42" cy="71" r="2.4" fill="${C.pink}" opacity="0.55"/>
  <circle cx="66" cy="71" r="2.4" fill="${C.pink}" opacity="0.55"/>`}`;
}

const svg = (viewBox, body, extra = '') =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" ${extra}>${body}</svg>`;

// Full icon, cropped to the part of the 108 grid that launchers actually show.
const fullIcon = (crop = 14) => svg(`${crop} ${crop} ${108 - 2 * crop} ${108 - 2 * crop}`, background + foreground());

// ---- Rendering ----

const browser = await playwright.chromium.launch();
const page = await browser.newPage();

async function renderHtml(file, w, h, html, { transparent = false } = {}) {
  await page.setViewportSize({ width: w, height: h });
  await page.setContent(`<!doctype html><html><head><meta charset="utf-8"><style>
    html,body{margin:0;padding:0;background:${transparent ? 'transparent' : '#fff'}}
    body>svg{display:block;width:${w}px;height:${h}px}
  </style></head><body>${html}</body></html>`);
  await page.evaluate(() => document.fonts.ready);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  await page.screenshot({ path: file, omitBackground: transparent, clip: { x: 0, y: 0, width: w, height: h } });
}

const renderSvg = (file, size, svgText, opts) => renderHtml(file, size, size, svgText, opts);

// Android: legacy square and round icons plus adaptive layers per density.
const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [name, scale] of Object.entries(densities)) {
  const dir = path.join(res, `mipmap-${name}`);
  const legacy = Math.round(48 * scale);
  const layer = Math.round(108 * scale);
  const rounded = svg('14 14 80 80', `<defs><clipPath id="r"><rect x="16" y="16" width="76" height="76" rx="17"/></clipPath></defs>
    <g clip-path="url(#r)">${background}${foreground()}</g>`);
  const round = svg('14 14 80 80', `<defs><clipPath id="c"><circle cx="54" cy="54" r="38"/></clipPath></defs>
    <g clip-path="url(#c)">${background}${foreground()}</g>`);
  await renderSvg(path.join(dir, 'ic_launcher.png'), legacy, rounded, { transparent: true });
  await renderSvg(path.join(dir, 'ic_launcher_round.png'), legacy, round, { transparent: true });
  await renderSvg(path.join(dir, 'ic_launcher_foreground.png'), layer, svg('0 0 108 108', foreground()), { transparent: true });
  await renderSvg(path.join(dir, 'ic_launcher_monochrome.png'), layer, svg('0 0 108 108', foreground({ mono: true })), { transparent: true });
}
fs.writeFileSync(path.join(res, 'values/ic_launcher_background.xml'),
  `<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">${C.bgBottom}</color>\n</resources>\n`);
// A flat colour behind the foreground would lose the gradient, so use a bitmap layer.
for (const [name, scale] of Object.entries(densities)) {
  await renderSvg(path.join(res, `mipmap-${name}`, 'ic_launcher_background.png'),
    Math.round(108 * scale), svg('0 0 108 108', background));
}

// iOS: every size listed in Contents.json, no transparency.
if (fs.existsSync(iosDir)) {
  const contents = JSON.parse(fs.readFileSync(path.join(iosDir, 'Contents.json'), 'utf8'));
  for (const img of contents.images) {
    if (!img.filename) continue;
    const px = Math.round(parseFloat(img.size) * parseInt(img.scale));
    await renderSvg(path.join(iosDir, img.filename), px, fullIcon(14));
  }
}

// ---- Google Play listing ----

// 512x512 hi-res icon, 32-bit PNG as Play asks (it rounds the corners itself).
await renderSvg(path.join(storeDir, 'play_icon_512.png'), 512, fullIcon(14), { transparent: true });
// Chromium saves an opaque image as 24-bit; add the alpha channel with Pillow when it's there.
try {
  require('child_process').execSync(`python3 -c "from PIL import Image; p='${path.join(storeDir, 'play_icon_512.png')}'; Image.open(p).convert('RGBA').save(p)"`, { stdio: 'ignore' });
} catch {
  console.warn('Pillow not found: play_icon_512.png stays 24-bit.');
}

const fonts = `font-family: 'DejaVu Sans', 'FreeSans', Arial, sans-serif;`;
const arabicFont = `font-family: 'FreeSerif', 'DejaVu Sans', serif;`;

// 1024x500 feature graphic.
await renderHtml(path.join(storeDir, 'feature_graphic_1024x500.png'), 1024, 500, `
<div style="position:relative;width:1024px;height:500px;overflow:hidden;
  background:linear-gradient(120deg, ${C.bgTop}, ${C.bgBottom});${fonts}">
  <div style="position:absolute;left:40px;top:30px;width:440px;height:440px">
    ${svg('10 10 88 88', background.replace('<rect width="108" height="108" fill="url(#bg)"/>', '') + foreground(), 'width="440" height="440"')}
  </div>
  <div style="position:absolute;left:490px;top:70px;width:510px;color:#fff">
    <div style="font-size:30px;letter-spacing:4px;opacity:.8;font-weight:bold">FAMILY GAME</div>
    <div style="font-size:78px;font-weight:bold;line-height:1.02;margin-top:10px">Who wrote<br>what?</div>
    <div dir="rtl" style="${arabicFont}font-size:52px;font-weight:bold;margin-top:18px;color:${C.yellow};text-align:left">مين كتب إيه؟</div>
    <div style="font-size:21px;margin-top:18px;opacity:.9;line-height:1.35">Drop a name in the bowl. Guess who wrote it.</div>
  </div>
</div>`);

// Phone screenshot frame template, 1080x1920 (9:16, inside Play's 320-3840 px and 2:1 limits).
// The screen hole is transparent: put a 900x1600 app screenshot underneath, or re-run this script
// with PNGs in store/screenshots/raw/ to frame each one.
const frame = (caption, arabic) => `
<div style="position:relative;width:1080px;height:1920px;overflow:hidden;${fonts}">
  <svg width="1080" height="1920" style="position:absolute;left:0;top:0">
    <defs>
      <linearGradient id="g" x1="0" y1="0" x2="0.3" y2="1">
        <stop offset="0" stop-color="${C.bgTop}"/><stop offset="1" stop-color="${C.bgBottom}"/>
      </linearGradient>
      <mask id="hole">
        <rect width="1080" height="1920" fill="#fff"/>
        <rect x="90" y="300" width="900" height="1600" rx="44" fill="#000"/>
      </mask>
    </defs>
    <g mask="url(#hole)">
      <rect width="1080" height="1920" fill="url(#g)"/>
      <rect x="70" y="280" width="940" height="1700" rx="64" fill="${C.ink}"/>
    </g>
  </svg>
  <div style="position:absolute;top:70px;width:100%;text-align:center;color:#fff">
    <div style="font-size:64px;font-weight:bold">${caption}</div>
    <div dir="rtl" style="${arabicFont}font-size:52px;font-weight:bold;color:${C.yellow};margin-top:14px">${arabic}</div>
  </div>
</div>`;
const frameCaptions = [
  ['Drop a name in the bowl', 'ارمي اسم في الطبق'],
  ['Friends join from their phone', 'صحابك يدخلوا من موبايلاتهم'],
  ['Guess who wrote what', 'خمّن مين كتب إيه'],
  ['Win as a family', 'اكسبوا كعيلة'],
];
await renderHtml(path.join(storeDir, 'screenshot_frame_template_1080x1920.png'), 1080, 1920,
  frame(frameCaptions[0][0], frameCaptions[0][1]), { transparent: true });

// Frame any real screenshots found in store/screenshots/raw/ (sorted by name).
const rawDir = path.join(storeDir, 'screenshots/raw');
if (fs.existsSync(rawDir)) {
  const shots = fs.readdirSync(rawDir).filter((f) => /\.(png|jpe?g)$/i.test(f)).sort();
  for (const [i, f] of shots.entries()) {
    const [en, ar] = frameCaptions[i % frameCaptions.length];
    const data = fs.readFileSync(path.join(rawDir, f)).toString('base64');
    const mime = f.toLowerCase().endsWith('png') ? 'image/png' : 'image/jpeg';
    await renderHtml(path.join(storeDir, `screenshots/phone_${i + 1}.png`), 1080, 1920, `
      <div style="position:relative;width:1080px;height:1920px">
        <img src="data:${mime};base64,${data}" style="position:absolute;left:90px;top:300px;width:900px;height:1600px;object-fit:cover;object-position:top">
        <div style="position:absolute;left:0;top:0">${frame(en, ar)}</div>
      </div>`);
  }
}

await browser.close();
console.log('Icon and store assets written.');
