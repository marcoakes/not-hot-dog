const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

async function captureScreenshots() {
    console.log('Starting screenshot capture...\n');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();

    // iPhone 6.7" dimensions (Pro Max)
    await page.setViewport({
        width: 1290,
        height: 2796,
        deviceScaleFactor: 1
    });

    const screenshots = [
        { file: '01-hero.html', output: '01-hero.png' },
        { file: '02-hotdog-result.html', output: '02-hotdog-result.png' },
        { file: '03-not-hotdog-result.html', output: '03-not-hotdog-result.png' },
        { file: '04-party-game.html', output: '04-party-game.png' },
        { file: '05-showcase.html', output: '05-showcase.png' },
        { file: '06-features.html', output: '06-features.png' }
    ];

    // Create output directory
    const outputDir = path.join(__dirname, 'png');
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir);
    }

    for (const screenshot of screenshots) {
        const inputPath = path.join(__dirname, screenshot.file);
        const outputPath = path.join(outputDir, screenshot.output);

        console.log(`Capturing: ${screenshot.file}`);

        await page.goto(`file://${inputPath}`, {
            waitUntil: 'networkidle0'
        });

        // Wait a moment for any animations/fonts to load
        await new Promise(resolve => setTimeout(resolve, 500));

        await page.screenshot({
            path: outputPath,
            type: 'png',
            fullPage: false,
            clip: {
                x: 0,
                y: 0,
                width: 1290,
                height: 2796
            }
        });

        console.log(`  ✓ Saved: ${screenshot.output}`);
    }

    await browser.close();

    console.log('\n✅ All screenshots captured!');
    console.log(`📁 Output folder: ${outputDir}`);
}

captureScreenshots().catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
