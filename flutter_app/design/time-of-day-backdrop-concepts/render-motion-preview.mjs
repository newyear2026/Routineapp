import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';

const directory = new URL('.', import.meta.url).pathname;
const image = join(directory, '00-board-refined.png');
const temporary = mkdtempSync(join(tmpdir(), 'loopet-motion-'));
const intermediate = join(temporary, 'preview-lossless.mkv');
const output = join(directory, '02-motion-preview-refined.gif');
const filterFile = join(temporary, 'motion-filter.txt');
const duration = 4.8;
const fps = 12;
const filters = ['[0:v]crop=1704:440:0:0,format=rgba[b0]'];
let current = 0;

const sprites = {
  mote: {
    size: '9x9',
    boxes: [
      [3, 0, 3, 9, '0xFFF8DC@0.75'],
      [0, 3, 9, 3, '0xFFF8DC@0.75'],
      [3, 3, 3, 3, '0xFFFFFF@0.95'],
    ],
  },
  leaf: {
    size: '12x10',
    boxes: [
      [4, 0, 4, 2, '0x7B9E54@0.9'],
      [2, 2, 8, 4, '0x91A85C@0.95'],
      [4, 6, 4, 2, '0x688544@0.9'],
      [5, 8, 2, 2, '0x6F6740@0.8'],
    ],
  },
  butterfly: {
    size: '13x9',
    boxes: [
      [1, 1, 4, 4, '0xFFE8A3@0.95'],
      [8, 1, 4, 4, '0xFFE8A3@0.95'],
      [3, 5, 3, 3, '0xF5BFA1@0.95'],
      [7, 5, 3, 3, '0xF5BFA1@0.95'],
      [6, 2, 1, 6, '0x5B5547@0.95'],
    ],
  },
  bird: {
    size: '13x7',
    boxes: [
      [0, 1, 3, 2, '0x77566A@0.85'],
      [3, 3, 3, 2, '0x77566A@0.85'],
      [6, 4, 2, 2, '0x77566A@0.85'],
      [8, 3, 3, 2, '0x77566A@0.85'],
      [11, 1, 2, 2, '0x77566A@0.85'],
    ],
  },
  firefly: {
    size: '11x11',
    boxes: [
      [2, 2, 7, 7, '0xC8EC9B@0.35'],
      [4, 4, 3, 3, '0xFAF7AD@0.98'],
    ],
  },
  star: {
    size: '9x9',
    boxes: [
      [4, 0, 1, 9, '0xFFF6CE@0.9'],
      [0, 4, 9, 1, '0xFFF6CE@0.9'],
      [3, 3, 3, 3, '0xFFFFFF@0.95'],
    ],
  },
};

function particle(type, x, y, {
  driftX = 0,
  driftY = 0,
  phase = 0,
  blink = 0,
  falling = false,
} = {}) {
  const index = current++;
  const sprite = sprites[type];
  const draw = sprite.boxes.map(([bx, by, width, height, color]) =>
    `drawbox=x=${bx}:y=${by}:w=${width}:h=${height}:color=${color}:t=fill:replace=1`,
  );
  filters.push(
    `color=c=black@0:s=${sprite.size}:r=${fps}:d=${duration},format=rgba,${draw.join(',')}[p${index}]`,
  );
  const cycle = `(t+${phase})/${duration}`;
  const progress = `(${cycle}-floor(${cycle}))`;
  const positionX = `'${x}+${driftX}*sin(2*PI*${cycle})'`;
  const positionY = driftY < 0 || falling
    ? `'${y}+${driftY}*${progress}'`
    : `'${y}+${driftY}*sin(2*PI*${cycle})'`;
  const enabled = blink
    ? `:enable='gt(sin(2*PI*(t+${phase})/${blink})\\,0.1)'`
    : '';
  filters.push(
    `[b${index}][p${index}]overlay=x=${positionX}:y=${positionY}:eval=frame:shortest=1${enabled}[b${index + 1}]`,
  );
}

// Morning: upward dust motes and tiny dew glints above the text.
particle('mote', 136, 181, { driftX: 10, driftY: -39, phase: 0.2 });
particle('mote', 270, 188, { driftX: 8, driftY: -50, phase: 1.8 });
particle('mote', 342, 197, { driftX: 10, driftY: -45, phase: 3.4 });
particle('star', 357, 238, { phase: 0.2, blink: 1.8 });

// Day: leaves drift down and one butterfly circles near the treetop.
particle('leaf', 662, 130, { driftX: 30, driftY: 103, phase: 0.1, falling: true });
particle('leaf', 776, 126, { driftX: -27, driftY: 98, phase: 2.2, falling: true });
particle('butterfly', 773, 175, { driftX: 15, driftY: 12, phase: 1.1 });

// Sunset: returning birds and a few emerging fireflies.
particle('bird', 1084, 137, { driftX: 34, driftY: 6, phase: 0.2 });
particle('bird', 1110, 149, { driftX: 28, driftY: 5, phase: 1.0 });
particle('firefly', 1200, 226, { driftX: 12, driftY: 8, phase: 0.8, blink: 2.6 });
particle('firefly', 1240, 271, { driftX: -8, driftY: 11, phase: 2.1, blink: 2.4 });
particle('star', 1151, 161, { phase: 0.3, blink: 3.1 });

// Night: stars wink on and off, and fireflies float behind the card art.
particle('star', 1402, 145, { phase: 0.0, blink: 1.6 });
particle('star', 1477, 132, { phase: 0.7, blink: 2.1 });
particle('star', 1552, 175, { phase: 1.2, blink: 1.9 });
particle('star', 1612, 137, { phase: 1.7, blink: 2.3 });
particle('firefly', 1625, 226, { driftX: 10, driftY: 8, phase: 0.3, blink: 2.1 });
particle('firefly', 1502, 265, { driftX: 7, driftY: 12, phase: 1.4, blink: 2.7 });
particle('firefly', 1613, 293, { driftX: -9, driftY: 8, phase: 2.0, blink: 2.4 });

filters.push(`[b${current}]format=rgb24[vout]`);
writeFileSync(filterFile, filters.join(';\n'));

function run(args) {
  const result = spawnSync('ffmpeg', args, { stdio: 'inherit' });
  if (result.status !== 0) process.exit(result.status ?? 1);
}

run([
  '-y', '-loglevel', 'error', '-loop', '1', '-framerate', String(fps),
  '-i', image, '-filter_complex_script', filterFile, '-map', '[vout]',
  '-frames:v', String(Math.round(duration * fps)), '-c:v', 'ffv1', intermediate,
]);
run([
  '-y', '-loglevel', 'error', '-i', intermediate,
  '-filter_complex',
  `[0:v]split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5[v]`,
  '-map', '[v]', '-loop', '0', output,
]);
rmSync(temporary, { recursive: true, force: true });
console.log(output);
