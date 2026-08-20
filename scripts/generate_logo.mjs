import sharp from 'sharp';
import fs from 'fs';
import path from 'path';

// High resolution SVG definition for Rexo Influencer Marketplace logo
const svgLogo = `
<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGrad" x1="0" y1="0" x2="1024" y2="1024" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#0F172A"/>
      <stop offset="50%" stop-color="#1E1B4B"/>
      <stop offset="100%" stop-color="#0284C7"/>
    </linearGradient>
    <linearGradient id="rGrad" x1="200" y1="200" x2="800" y2="800" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#38BDF8"/>
      <stop offset="50%" stop-color="#818CF8"/>
      <stop offset="100%" stop-color="#C084FC"/>
    </linearGradient>
    <linearGradient id="goldGrad" x1="300" y1="150" x2="700" y2="350" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FDE047"/>
      <stop offset="100%" stop-color="#F59E0B"/>
    </linearGradient>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="16" stdDeviation="24" flood-color="#000" flood-opacity="0.4"/>
    </filter>
  </defs>

  <!-- Background rounded box -->
  <rect width="1024" height="1024" rx="224" fill="url(#bgGrad)"/>
  <rect x="24" y="24" width="976" height="976" rx="200" stroke="white" stroke-opacity="0.12" stroke-width="8" fill="none"/>

  <!-- Crown element above R -->
  <path d="M 372 270 L 432 350 L 512 250 L 592 350 L 652 270 L 632 400 L 392 400 Z" fill="url(#goldGrad)" filter="url(#shadow)"/>
  <circle cx="372" cy="250" r="16" fill="#FDE047"/>
  <circle cx="512" cy="230" r="20" fill="#FDE047"/>
  <circle cx="652" cy="250" r="16" fill="#FDE047"/>

  <!-- Stylized R Emblem -->
  <g filter="url(#shadow)">
    <!-- Vertical Bar of R -->
    <rect x="320" y="420" width="110" height="380" rx="32" fill="url(#rGrad)"/>
    <!-- Loop of R -->
    <path d="M 410 420 H 560 C 660 420 720 480 720 560 C 720 640 660 690 560 690 H 410 V 420 Z" fill="url(#rGrad)"/>
    <path d="M 490 500 H 550 C 600 500 630 525 630 555 C 630 585 600 610 550 610 H 490 V 500 Z" fill="#1E1B4B"/>
    <!-- Leg of R -->
    <path d="M 520 660 L 680 800 H 790 L 610 640 Z" fill="url(#rGrad)"/>
  </g>

  <!-- Sparkle Accent -->
  <path d="M 780 320 Q 820 320 820 280 Q 820 320 860 320 Q 820 320 820 360 Q 820 320 780 320 Z" fill="#FDE047"/>
</svg>
`;

// Foreground SVG for Android Adaptive Icon (needs inset safe zone padding)
const svgForeground = `
<svg width="1080" height="1080" viewBox="0 0 1080 1080" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="rGradFg" x1="200" y1="200" x2="800" y2="800" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#38BDF8"/>
      <stop offset="50%" stop-color="#818CF8"/>
      <stop offset="100%" stop-color="#C084FC"/>
    </linearGradient>
    <linearGradient id="goldGradFg" x1="300" y1="150" x2="700" y2="350" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FDE047"/>
      <stop offset="100%" stop-color="#F59E0B"/>
    </linearGradient>
  </defs>

  <g transform="translate(28, 28) scale(1.0)">
    <!-- Crown element above R -->
    <path d="M 372 270 L 432 350 L 512 250 L 592 350 L 652 270 L 632 400 L 392 400 Z" fill="url(#goldGradFg)"/>
    <circle cx="372" cy="250" r="16" fill="#FDE047"/>
    <circle cx="512" cy="230" r="20" fill="#FDE047"/>
    <circle cx="652" cy="250" r="16" fill="#FDE047"/>

    <!-- Stylized R Emblem -->
    <rect x="320" y="420" width="110" height="380" rx="32" fill="url(#rGradFg)"/>
    <path d="M 410 420 H 560 C 660 420 720 480 720 560 C 720 640 660 690 560 690 H 410 V 420 Z" fill="url(#rGradFg)"/>
    <path d="M 490 500 H 550 C 600 500 630 525 630 555 C 630 585 600 610 550 610 H 490 V 500 Z" fill="#0F172A"/>
    <path d="M 520 660 L 680 800 H 790 L 610 640 Z" fill="url(#rGradFg)"/>
    <path d="M 780 320 Q 820 320 820 280 Q 820 320 860 320 Q 820 320 820 360 Q 820 320 780 320 Z" fill="#FDE047"/>
  </g>
</svg>
`;

async function generateAllAssets() {
  console.log('Generating Rexo brand logo PNGs...');
  
  // Ensure directories
  fs.mkdirSync('android/assets/Png', { recursive: true });
  fs.mkdirSync('public', { recursive: true });

  const logoBuffer = Buffer.from(svgLogo);
  const fgBuffer = Buffer.from(svgForeground);

  // 1. Single source of truth logo locations
  await sharp(logoBuffer).resize(1024, 1024).toFile('android/assets/Png/logo.png');
  await sharp(logoBuffer).resize(1024, 1024).toFile('public/logo.png');
  await sharp(logoBuffer).resize(512, 512).toFile('public/favicon.png');
  await sharp(logoBuffer).resize(64, 64).toFile('public/favicon.ico');

  console.log('Generated base logos in android/assets/Png/logo.png & public/logo.png');

  // 2. Android Mipmap densities
  const resDir = 'android/app/src/main/res';
  const mipmaps = [
    { dir: 'mipmap-mdpi', size: 48, fgSize: 108 },
    { dir: 'mipmap-hdpi', size: 72, fgSize: 162 },
    { dir: 'mipmap-xhdpi', size: 96, fgSize: 216 },
    { dir: 'mipmap-xxhdpi', size: 144, fgSize: 324 },
    { dir: 'mipmap-xxxhdpi', size: 192, fgSize: 432 },
  ];

  for (const m of mipmaps) {
    const targetDir = path.join(resDir, m.dir);
    fs.mkdirSync(targetDir, { recursive: true });

    // ic_launcher.png
    await sharp(logoBuffer).resize(m.size, m.size).toFile(path.join(targetDir, 'ic_launcher.png'));

    // ic_launcher_round.png
    const circleMask = Buffer.from(
      `<svg width="${m.size}" height="${m.size}"><circle cx="${m.size / 2}" cy="${m.size / 2}" r="${m.size / 2}" fill="#fff"/></svg>`
    );
    await sharp(logoBuffer)
      .resize(m.size, m.size)
      .composite([{ input: circleMask, blend: 'dest-in' }])
      .toFile(path.join(targetDir, 'ic_launcher_round.png'));

    // ic_launcher_foreground.png
    await sharp(fgBuffer).resize(m.fgSize, m.fgSize).toFile(path.join(targetDir, 'ic_launcher_foreground.png'));
  }

  // 3. Android Splash Screens
  const splashScreens = [
    { path: 'drawable/splash.png', w: 2732, h: 2732, logoW: 800 },
    { path: 'drawable-port-mdpi/splash.png', w: 320, h: 480, logoW: 160 },
    { path: 'drawable-port-hdpi/splash.png', w: 480, h: 800, logoW: 240 },
    { path: 'drawable-port-xhdpi/splash.png', w: 720, h: 1280, logoW: 360 },
    { path: 'drawable-port-xxhdpi/splash.png', w: 960, h: 1600, logoW: 480 },
    { path: 'drawable-port-xxxhdpi/splash.png', w: 1280, h: 1920, logoW: 640 },
    { path: 'drawable-land-mdpi/splash.png', w: 480, h: 320, logoW: 160 },
    { path: 'drawable-land-hdpi/splash.png', w: 800, h: 480, logoW: 240 },
    { path: 'drawable-land-xhdpi/splash.png', w: 1280, h: 720, logoW: 360 },
    { path: 'drawable-land-xxhdpi/splash.png', w: 1600, h: 960, logoW: 480 },
    { path: 'drawable-land-xxxhdpi/splash.png', w: 1920, h: 1280, logoW: 640 },
  ];

  for (const s of splashScreens) {
    const splashFilePath = path.join(resDir, s.path);
    fs.mkdirSync(path.dirname(splashFilePath), { recursive: true });

    const resizedLogo = await sharp(logoBuffer).resize(s.logoW, s.logoW).toBuffer();

    await sharp({
      create: {
        width: s.w,
        height: s.h,
        channels: 4,
        background: { r: 15, g: 23, b: 42, alpha: 1 } // #0F172A
      }
    })
      .composite([{ input: resizedLogo, gravity: 'center' }])
      .png()
      .toFile(splashFilePath);
  }

  console.log('All Android Launcher Icons and Splash Screens generated successfully!');
}

generateAllAssets().catch((err) => {
  console.error('Error generating assets:', err);
  process.exit(1);
});
