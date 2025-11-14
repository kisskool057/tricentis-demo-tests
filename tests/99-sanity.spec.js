const { test, expect } = require('../test-fixtures');
const { markTestStart, markTestResult } = require('../utils/browserstack');

test.beforeEach(async ({ page }, testInfo) => {
  await markTestStart(page, testInfo);
});

test('sanity test', async ({ page }) => {
  // Simple test to verify Playwright detection
  await page.goto('/');
  expect(1 + 1).toBe(2);
});

test.afterEach(async ({ page }, testInfo) => {
  await markTestResult(page, testInfo);
  try { await page.context().close(); } catch (e) {}
});
