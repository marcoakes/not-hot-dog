# Not Hot Dog App Store Screenshots

These HTML mockups are designed to be captured as App Store screenshots.

## Screenshot Dimensions

| Device | Size | Files to Use |
|--------|------|--------------|
| iPhone 6.7" (Pro Max) | 1290 x 2796 | All files (default size) |
| iPhone 6.5" (Plus/Max) | 1284 x 2778 | Resize slightly |
| iPhone 5.5" (Plus) | 1242 x 2208 | Resize |

## How to Capture Screenshots

### Method 1: Browser Screenshot (Recommended)
1. Open each HTML file in Chrome/Safari
2. Use browser's screenshot or print-to-PDF feature
3. Or use a screenshot tool to capture at exact dimensions

### Method 2: Using Chrome DevTools
1. Open HTML file in Chrome
2. Press F12 (DevTools)
3. Click device toolbar icon (Ctrl+Shift+M)
4. Set custom dimensions: 1290 x 2796
5. Right-click → "Capture screenshot"

### Method 3: Using Puppeteer/Playwright Script
```javascript
const puppeteer = require('puppeteer');

async function captureScreenshots() {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    await page.setViewport({ width: 1290, height: 2796 });

    const files = [
        '01-hero.html',
        '02-hotdog-result.html',
        '03-not-hotdog-result.html',
        '04-party-game.html',
        '05-showcase.html',
        '06-features.html'
    ];

    for (const file of files) {
        await page.goto(`file://${__dirname}/${file}`);
        await page.screenshot({
            path: file.replace('.html', '.png'),
            type: 'png'
        });
    }

    await browser.close();
}

captureScreenshots();
```

## Screenshot Order for App Store

1. **01-hero** - "The Legendary Hot Dog Detector"
2. **02-hotdog-result** - "It's a Hot Dog!" (Green)
3. **03-not-hotdog-result** - "Not a Hot Dog" (Red)
4. **04-party-game** - "Perfect Party Game"
5. **05-silicon-valley** - "As Seen on TV"
6. **06-features** - Feature overview

## Customization

Edit the HTML/CSS to:
- Change colors/gradients
- Update text/captions
- Swap emojis for actual photos
- Adjust device frame size

## Tips for App Store

- First screenshot is most important (shown in search)
- Use vibrant colors that stand out
- Keep text large and readable
- Show the core value proposition immediately
- Include both results (Hot Dog AND Not Hot Dog)
