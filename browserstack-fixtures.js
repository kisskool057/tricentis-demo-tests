/**
 * Fixtures Playwright pour BrowserStack
 * - Mode local si pas de credentials BS
 * - Une session BrowserStack dédiée par test, avec nom unique et statut remonté
 */

const base = require('@playwright/test');
const { chromium } = require('playwright');
const bsConfig = require('./browserstack.config');
const cp = require('child_process');

// Compteur global pour rendre chaque session unique
let sessionCounter = 0;

// Vérifie si on doit exécuter sur BrowserStack
const isBrowserStackRun = () =>
  Boolean(bsConfig.username && bsConfig.accessKey);

// Formatte le nom complet du test avec un ID unique
const formatTestName = (testInfo, sessionId) => {
  const titlePath = Array.isArray(testInfo.titlePath)
    ? testInfo.titlePath
    : typeof testInfo.titlePath === 'function'
    ? testInfo.titlePath()
    : [testInfo.title || 'Unknown Test'];

  // Enlève le nom du fichier (premier élément) et ajoute un ID unique
  const testName = titlePath.slice(1).join(' › ');
  return `[${sessionId}] ${testName}`;
};

// Envoie une commande à l'executor BrowserStack
const sendBrowserStackCommand = async (page, action, args) => {
  const payload = `browserstack_executor: ${JSON.stringify({
    action,
    arguments: args,
  })}`;

  try {
    // Pattern recommandé par BrowserStack pour setSessionStatus :contentReference[oaicite:4]{index=4}
    await page.evaluate(() => {}, payload);
    console.log(`[BrowserStack] ${action} executed successfully`);
  } catch (error) {
    console.warn(`[BrowserStack] ${action} failed: ${error.message}`);
  }
};

// Étend les fixtures de base Playwright
const test = base.test.extend({
  // Override du contexte pour créer une session BrowserStack par test
  context: async ({}, use, testInfo) => {
    // 🔹 Mode LOCAL : pas de credentials BS → on lance Chromium local
    if (!isBrowserStackRun()) {
      const isCI = `${process.env.CI}` === 'true';
      console.log('[BrowserStack] No credentials detected → running locally');
      const browser = await chromium.launch({ headless: isCI });
      const context = await browser.newContext();
      await use(context);
      await context.close();
      await browser.close();
      return;
    }

    // 🔹 Mode BrowserStack
    const clientPlaywrightVersion = cp
      .execSync('npx playwright --version')
      .toString()
      .trim()
      .split(' ')[1];

    if (!bsConfig.username || !bsConfig.accessKey) {
      console.error(
        '❌ BROWSERSTACK_USERNAME ou BROWSERSTACK_ACCESS_KEY manquant dans bsConfig'
      );
      throw new Error('Missing BrowserStack credentials');
    }

    const sessionId = `S${++sessionCounter}`;
    const testName = formatTestName(testInfo, sessionId);

    // Capabilities conformes à la doc BS Playwright :contentReference[oaicite:5]{index=5}
    const caps = {
      // OS / Browser
      os: bsConfig.capabilities.os,
      os_version: bsConfig.capabilities.osVersion,
      browser: bsConfig.capabilities.browser,
      browser_version: bsConfig.capabilities.browserVersion,

      // Organisation
      project: bsConfig.projectName,
      build: bsConfig.buildName,
      name: testName,

      // Auth
      'browserstack.username': bsConfig.username,
      'browserstack.accessKey': bsConfig.accessKey,

      // Options BrowserStack
      'browserstack.console': bsConfig.capabilities['browserstack.console'],
      'browserstack.networkLogs':
        bsConfig.capabilities['browserstack.networkLogs'],
      'browserstack.debug': bsConfig.capabilities['browserstack.debug'],
      'browserstack.video': bsConfig.capabilities['browserstack.video'],
      'browserstack.timezone': bsConfig.capabilities['browserstack.timezone'],

      // Versions Playwright (client + côté BS)
      'browserstack.playwrightVersion': '1.latest',
      'client.playwrightVersion': clientPlaywrightVersion,
    };

    const wsEndpoint = `wss://cdp.browserstack.com/playwright?caps=${encodeURIComponent(
      JSON.stringify(caps)
    )}`;

    let browser;
    let context;

    try {
      console.log(
        `[BrowserStack] Connecting session ${sessionId} for test: ${testInfo.title}`
      );

      // ⬅️ Changement clé : on utilise chromium.connect (Playwright protocol),
      // pas connectOverCDP qui parle CDP brut.
      browser = await chromium.connect({ wsEndpoint });

      // Récupérer ou créer le contexte
      const contexts = browser.contexts();
      context =
        contexts.length > 0 ? contexts[0] : await browser.newContext();

      // Utiliser le contexte dans le test
      await use(context);

      // Après le test: mettre à jour le statut dans le dashboard BS
      console.log(
        `[BrowserStack] Test ${sessionId} finished with status: ${testInfo.status}`
      );

      const pages = context.pages();
      if (pages.length > 0 && !pages[0].isClosed()) {
        const page = pages[0];
        const isExpected =
          testInfo.status === 'passed' ||
          testInfo.status === testInfo.expectedStatus;
        const status = isExpected ? 'passed' : 'failed';
        const reason =
          testInfo.error?.message?.slice(0, 250) ||
          (status === 'passed'
            ? 'Test passed successfully'
            : `Test ${testInfo.status}`);

        console.log(`[BrowserStack] Setting status to: ${status}`);
        await sendBrowserStackCommand(page, 'setSessionStatus', {
          status,
          reason,
        });

        // Petite pause pour s'assurer que le statut est envoyé
        await page.waitForTimeout(500);
      }
    } catch (error) {
      console.error(
        `[BrowserStack] Error in session ${sessionId}: ${error.message}`
      );
      console.error(
        '[BrowserStack] Connection failed. Vérifie les credentials et la version Playwright.'
      );

      throw new Error(`BrowserStack connection failed: ${error.message}`);
    } finally {
      // Nettoyage
      if (context) {
        try {
          await context.close();
          console.log(`[BrowserStack] Context closed for ${sessionId}`);
        } catch (e) {
          console.warn(
            `[BrowserStack] Error closing context: ${e.message}`
          );
        }
      }
      if (browser) {
        try {
          await browser.close();
          console.log(`[BrowserStack] Browser closed for ${sessionId}`);
        } catch (e) {
          console.warn(
            `[BrowserStack] Error closing browser: ${e.message}`
          );
        }
      }
    }
  },

  // Override de page pour utiliser le contexte personnalisé
  page: async ({ context }, use) => {
    const pages = context.pages();
    const page = pages.length > 0 ? pages[0] : await context.newPage();
    await use(page);
  },
});

module.exports = { test, expect: base.expect };
