const base = require('@playwright/test');
const { formatTestName, markTestStart, markTestResult } = require('./utils/browserstack');

if (process.env.BROWSERSTACK_USERNAME && process.env.BROWSERSTACK_ACCESS_KEY) {
  const { chromium } = require('playwright');

  const test = base.test.extend({
    // override page fixture to create a dedicated BrowserStack browser per test
    page: async ({}, use, testInfo) => {
      const buildName = process.env.BROWSERSTACK_BUILD_NAME || `TRICENTIS-DEMO-TESTS (local ${new Date().toISOString()})`;
      const caps = {
        browser: 'chrome',
        browser_version: 'latest',
        os: 'Windows',
        os_version: '11',
        build: buildName,
        project: 'TRICENTIS-DEMO-TESTS',
        name: formatTestName(testInfo),
        'browserstack.username': process.env.BROWSERSTACK_USERNAME,
        'browserstack.accessKey': process.env.BROWSERSTACK_ACCESS_KEY,
        'browserstack.console': 'info',
        'browserstack.networkLogs': 'true',
        'client.playwrightVersion': require('@playwright/test/package.json').version,
      };

      const wsEndpoint = `wss://cdp.browserstack.com/playwright?caps=${encodeURIComponent(JSON.stringify(caps))}`;

      const browser = await chromium.connectOverCDP(wsEndpoint);
      const context = await browser.newContext();
      const page = await context.newPage();

      await markTestStart(page, testInfo);

      try {
        await use(page);
      } finally {
        await markTestResult(page, testInfo);
        try { await context.close(); } catch (e) {}
        try { await browser.close(); } catch (e) {}
      }
    }
  });

  module.exports = { test, expect: base.expect };
} else {
  module.exports = { test: base.test, expect: base.expect };
}
