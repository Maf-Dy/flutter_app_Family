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

// Colours and fonts are the app's own: lib/core/theme/app_theme.dart and game_colors.dart.
const C = {
  primary: '#4A3FCF',
  primaryContainer: '#E3E0FF',
  tertiary: '#D9480F',
  surface: '#F2F1F8',
  ink: '#1D1A33',
  inkSoft: '#625E7A',
  slipPaper: '#FFE7A0',
  slipEdge: '#E9C868',
  slipInk: '#2A2440',
};

const fontFile = (f) => `url(data:font/ttf;base64,${fs.readFileSync(path.join(root, 'assets/fonts', f)).toString('base64')})`;
const fontFaces = `
  @font-face{font-family:'Bricolage Grotesque';font-weight:800;src:${fontFile('BricolageGrotesque-ExtraBold.ttf')}}
  @font-face{font-family:'Nunito';font-weight:700;src:${fontFile('Nunito-Bold.ttf')}}
  @font-face{font-family:'Kalam';font-weight:700;src:${fontFile('Kalam-Bold.ttf')}}
  @font-face{font-family:'Baloo Bhaijaan 2';font-weight:800;src:${fontFile('BalooBhaijaan2-ExtraBold.ttf')}}`;

// ---- Artwork, all in a 108x108 box (the Android adaptive icon grid). ----
// Everything important sits inside the 66-unit safe circle around (54,54).

const background = `
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0.3" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="${C.primaryContainer}"/>
    </linearGradient>
  </defs>
  <rect width="108" height="108" fill="url(#bg)"/>`;

// The home screen bowl (lib/core/widgets/bowl.dart), in its 200x132 box.
// x, y, width, height, tilt: the same four slips as the app.
const slips = [
  [52, 22, 44, 26, -18],
  [86, 8, 44, 26, 8],
  [112, 26, 44, 26, 22],
  [74, 34, 44, 26, -4],
];

function bowlArt({ mono = false, withQuestion = true } = {}) {
  const paper = mono ? '#FFFFFF' : C.slipPaper;
  const bowl = mono ? '#FFFFFF' : C.primary;
  // Slips are drawn mid-bob (lifted 5, as the app animates them) so more paper shows.
  const slipsSvg = slips.map(([x, y0, w, h, tilt], i) => {
    const y = y0 - 5;
    const cx = x + w / 2, cy = y + h / 2;
    const front = i === 1; // the top slip, fully above the rim
    const writing = mono ? '' : front && withQuestion
      ? `<text x="${cx}" y="${cy + 10}" text-anchor="middle" font-family="Kalam" font-weight="700" font-size="30" fill="${C.slipInk}">?</text>`
      : `<path d="M${x + 8} ${cy + 1} q6 -5 12 0 t12 0" stroke="${C.slipEdge}" stroke-width="2.4" fill="none" stroke-linecap="round"/>`;
    return `<g transform="rotate(${tilt} ${cx} ${cy})">
      <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="2" fill="${paper}" ${mono ? '' : `stroke="${C.slipEdge}" stroke-width="1"`}/>
      ${writing}
    </g>`;
  }).join('');
  const shine = mono ? '' : `
    <ellipse cx="100" cy="58" rx="80" ry="5.5" fill="#FFFFFF" opacity="0.18"/>
    <path d="M40 80 C50 98 70 110 92 112" stroke="#FFFFFF" stroke-opacity="0.2" stroke-width="4" fill="none" stroke-linecap="round"/>`;
  return `${slipsSvg}
    <path d="M14 58 L186 58 C186 96 148 126 100 126 C52 126 14 96 14 58 Z" fill="${bowl}"/>
    <ellipse cx="100" cy="58" rx="86" ry="9" fill="${bowl}"/>
    ${shine}`;
}

// mono=true draws the single-colour silhouette for Android 13 themed icons.
function foreground({ mono = false } = {}) {
  // Scale the 200x132 bowl to 70 units wide, centred on the grid.
  return `<g transform="translate(19 32) scale(0.35)">${bowlArt({ mono })}</g>`;
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
    ${fontFaces}
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

const display = `font-family:'Bricolage Grotesque';font-weight:800;`;
const body = `font-family:'Nunito';font-weight:700;`;
const arabic = `font-family:'Baloo Bhaijaan 2';font-weight:800;`;
const bowlSvg = (w) => svg('0 0 200 132', bowlArt(), `width="${w}" height="${w * 132 / 200}"`);
const wordmark = (size) => `<span style="${display}font-size:${size}px;letter-spacing:-1px;color:${C.ink}">family</span><span
  style="display:inline-block;width:${size * 0.27}px;height:${size * 0.27}px;border-radius:50%;background:${C.tertiary};margin-left:3px"></span>`;

// 1024x500 feature graphic, in the app's light home-screen look.
await renderHtml(path.join(storeDir, 'feature_graphic_1024x500.png'), 1024, 500, `
<div style="position:relative;width:1024px;height:500px;overflow:hidden;background:${C.surface}">
  <div style="position:absolute;left:-60px;top:40px;width:560px;height:560px;border-radius:50%;background:${C.primaryContainer}"></div>
  <div style="position:absolute;left:50px;top:120px">${bowlSvg(400)}</div>
  <div style="position:absolute;left:500px;top:60px;width:490px">
    <div>${wordmark(40)}</div>
    <div style="${display}font-size:86px;line-height:1;letter-spacing:-2px;color:${C.ink};margin-top:14px">Who wrote<br>what?</div>
    <div dir="rtl" style="${arabic}font-size:56px;line-height:1.3;color:${C.primary};margin-top:10px;text-align:left">مين كتب إيه؟</div>
    <div style="${body}font-size:22px;color:${C.inkSoft};margin-top:8px;line-height:1.35">Drop a name in the bowl. Guess who wrote it.</div>
  </div>
</div>`);

// Phone screenshot frame template, 1080x1920 (9:16, inside Play's 320-3840 px and 2:1 limits).
// The screen hole is transparent: put a 900x1600 app screenshot underneath, or re-run this script
// with PNGs in store/screenshots/raw/ to frame each one.
const frame = (caption, arabicCaption) => `
<div style="position:relative;width:1080px;height:1920px;overflow:hidden">
  <svg width="1080" height="1920" style="position:absolute;left:0;top:0">
    <defs>
      <mask id="hole">
        <rect width="1080" height="1920" fill="#fff"/>
        <rect x="90" y="330" width="900" height="1600" rx="44" fill="#000"/>
      </mask>
    </defs>
    <g mask="url(#hole)">
      <rect width="1080" height="1920" fill="${C.surface}"/>
      <circle cx="980" cy="120" r="260" fill="${C.primaryContainer}"/>
      <rect x="70" y="310" width="940" height="1700" rx="64" fill="${C.ink}"/>
    </g>
  </svg>
  <div style="position:absolute;top:60px;width:100%;text-align:center">
    <div style="${display}font-size:68px;letter-spacing:-1.5px;color:${C.ink}">${caption}</div>
    <div dir="rtl" style="${arabic}font-size:56px;color:${C.primary};margin-top:6px">${arabicCaption}</div>
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
        <img src="data:${mime};base64,${data}" style="position:absolute;left:90px;top:330px;width:900px;height:1600px;object-fit:cover;object-position:top">
        <div style="position:absolute;left:0;top:0">${frame(en, ar)}</div>
      </div>`);
  }
}

await browser.close();
console.log('Icon and store assets written.');
