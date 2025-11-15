/**
 * Configuration centralisée BrowserStack
 * - Lit les variables d'environnement (GitHub Actions, .env, local)
 * - Définit l'OS, le navigateur, le build, le parallélisme, etc.
 */

const runInOrder = process.env.BS_RUN_IN_ORDER !== 'false';
const requestedWorkers = parseInt(process.env.BS_WORKERS || '5', 10);
const now = new Date();

module.exports = {
  // Identifiants BrowserStack (via variables d'environnement)
  username: process.env.BROWSERSTACK_USERNAME,
  accessKey: process.env.BROWSERSTACK_ACCESS_KEY,

  // Exécution séquentielle (par défaut) ou parallèle via BS_RUN_IN_ORDER=false
  runInOrder,

  // Nom du build (unique par exécution)
  buildName:
    process.env.BROWSERSTACK_BUILD_NAME ||
    `Tricentis Demo Tests - ${now.toISOString().split('T')[0]} ${now
      .toTimeString()
      .slice(0, 5)}`,

  // Nom du projet (affiché dans le dashboard BrowserStack)
  projectName: 'Tricentis Demo Web Shop',

  // Configuration de l'environnement d'exécution
  capabilities: {
    // Système d'exploitation
    os: process.env.BS_OS || 'Windows',
    osVersion: process.env.BS_OS_VERSION || '11',

    // Navigateur
    browser: process.env.BS_BROWSER || 'chrome',
    browserVersion: process.env.BS_BROWSER_VERSION || 'latest',

    // Options BrowserStack (cf. docs Playwright capabilities)
    // https://www.browserstack.com/docs/automate/playwright/playwright-capabilities :contentReference[oaicite:1]{index=1}
    'browserstack.console': 'info',
    'browserstack.networkLogs': 'true',
    'browserstack.debug': 'true',
    'browserstack.video': 'true',
    'browserstack.timezone': 'Paris', // valeur supportée (voir liste timezones) :contentReference[oaicite:2]{index=2}
    // ❌ Ne pas mettre browserstack.selenium_version ici : inutile pour Playwright
  },

  // Nombre de tests en parallèle (forcé à 1 si runInOrder = true)
  workers: runInOrder ? 1 : requestedWorkers,

  // Timeout global Playwright par test (ms)
  timeout: 90000,

  // Options de retry (désactivé pour BrowserStack)
  retries: 0,
};
