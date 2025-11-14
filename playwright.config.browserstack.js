const { defineConfig, devices } = require('@playwright/test');
const base = require('./playwright.config.js');
const cp = require('child_process');
const clientPlaywrightVersion = cp
  .execSync('npx playwright --version')
  .toString()
  .trim()
  .split(' ')[1];

/**
 * Configuration Playwright pour BrowserStack avec SDK officiel
 * Documentation: https://www.browserstack.com/docs/automate/playwright
 */
module.exports = defineConfig({
  ...base,
  
  // Désactiver le mode headed pour BrowserStack
  use: {
    ...base.use,
    headless: true,
  },

  // Reporter pour mettre à jour les statuts BrowserStack
  reporter: [
    ['list'],
    ['html'],
  ],

  // Configuration BrowserStack
  projects: [
    {
      name: 'browserstack-chrome',
      use: {
        ...devices['Desktop Chrome'],
        // Capabilities BrowserStack avec SDK
        connectOptions: {
          wsEndpoint: `wss://cdp.browserstack.com/playwright?caps=${encodeURIComponent(JSON.stringify({
            'browser': 'chrome',
            'browser_version': 'latest',
            'os': 'Windows',
            'os_version': '11',
            'name': 'Tricentis Demo Tests',
            'build': `Build ${process.env.GITHUB_RUN_NUMBER || new Date().toISOString().split('T')[0]}`,
            'project': 'tricentis-demo-tests',
            'browserstack.username': process.env.BROWSERSTACK_USERNAME,
            'browserstack.accessKey': process.env.BROWSERSTACK_ACCESS_KEY,
            'browserstack.console': 'info',
            'browserstack.networkLogs': 'true',
            // Configuration du SDK pour la gestion automatique des statuts
            'client.playwrightVersion': clientPlaywrightVersion,
          }))}`,
        },
      },
    },
  ],

  // Forcer l'exécution séquentielle
  workers: 1,
  fullyParallel: false,
});
