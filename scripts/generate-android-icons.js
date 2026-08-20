import sharp from 'sharp';
import fs from 'fs';
import path from 'path';

const SRC_LOGO = path.resolve('android/assets/logo.png');
const RES_DIR = path.resolve('android/app/src/main/res');

if (!fs.existsSync(SRC_LOGO)) {
  console.error(`Source logo not found at: ${SRC_LOGO}`);
  process.exit(1);
}

const DENSITIES = [
  { name: 'mipmap-mdpi', iconSize: 48, fgSize: 108, safeSize: 72 },
  { name: 'mipmap-hdpi', iconSize: 72, fgSize: 162, safeSize: 108 },
  { name: 'mipmap-xhdpi', iconSize: 96, fgSize: 216, safeSize: 144 },
  { name: 'mipmap-xxhdpi', iconSize: 144, fgSize: 324, safeSize: 216 },
  { name: 'mipmap-xxxhdpi', iconSize: 192, fgSize: 432, safeSize: 288 },
];

async function generateIcons() {
  console.log(`Generating Android icons from ${SRC_LOGO}...`);

  for (const { name, iconSize, fgSize, safeSize } of DENSITIES) {
    const targetDir = path.join(RES_DIR, name);
    fs.mkdirSync(targetDir, { recursive: true });

    // 1. Standard launcher icon & round icon (full bleed)
    await sharp(SRC_LOGO)
      .resize(iconSize, iconSize)
      .toFile(path.join(targetDir, 'ic_launcher.png'));

    await sharp(SRC_LOGO)
      .resize(iconSize, iconSize)
      .toFile(path.join(targetDir, 'ic_launcher_round.png'));

    // 2. Adaptive icon foreground layer (logo resized to safe inner zone and centered in transparent canvas)
    const resizedLogoBuffer = await sharp(SRC_LOGO)
      .resize(safeSize, safeSize, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .toBuffer();

    await sharp({
      create: {
        width: fgSize,
        height: fgSize,
        channels: 4,
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      }
    })
      .composite([{ input: resizedLogoBuffer, gravity: 'center' }])
      .toFile(path.join(targetDir, 'ic_launcher_foreground.png'));

    console.log(`Generated icons for ${name} (icon: ${iconSize}px, fg: ${fgSize}px)`);
  }

  // Ensure mipmap-anydpi-v26 xml files exist
  const v26Dir = path.join(RES_DIR, 'mipmap-anydpi-v26');
  fs.mkdirSync(v26Dir, { recursive: true });

  const adaptiveXmlContent = `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>`;

  fs.writeFileSync(path.join(v26Dir, 'ic_launcher.xml'), adaptiveXmlContent);
  fs.writeFileSync(path.join(v26Dir, 'ic_launcher_round.xml'), adaptiveXmlContent);

  // Ensure values/ic_launcher_background.xml exists
  const valuesDir = path.join(RES_DIR, 'values');
  fs.mkdirSync(valuesDir, { recursive: true });
  const bgXmlContent = `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0F172A</color>
</resources>`;
  fs.writeFileSync(path.join(valuesDir, 'ic_launcher_background.xml'), bgXmlContent);

  console.log('Android icon generation complete!');
}

generateIcons().catch((err) => {
  console.error('Failed to generate Android icons:', err);
  process.exit(1);
});
