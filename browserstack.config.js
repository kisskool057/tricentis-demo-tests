/**
 * Configuration centralisée BrowserStack
 *
 * Cette version prend en charge à la fois les navigateurs desktop et les appareils mobiles.
 * - En mode desktop (par défaut), les paramètres OS et navigateur sont définis par
 *   les variables d'environnement BS_OS, BS_OS_VERSION, BS_BROWSER et BS_BROWSER_VERSION.
 * - En mode mobile, déclenché par la présence de BS_DEVICE, les capacités sont
 *   adaptées pour lancer un vrai appareil iOS/Android sur BrowserStack.
 */

const runInOrder = process.env.BS_RUN_IN_ORDER !== 'false';
const requestedWorkers = parseInt(process.env.BS_WORKERS || '5', 10);
const now = new Date();

// Détermine si l'exécution doit cibler un appareil mobile
const isMobile = Boolean(process.env.BS_DEVICE);

// Définition des capacités pour les sessions desktop (Windows, Chrome, etc.)
const desktopCapabilities = {
  // Système d'exploitation desktop
  os: process.env.BS_OS || 'Windows',
  osVersion: process.env.BS_OS_VERSION || '11',

  // Navigateur desktop
  browser: process.env.BS_BROWSER || 'chrome',
  browserVersion: process.env.BS_BROWSER_VERSION || 'latest',

  // Options communes BrowserStack pour Playwright
  'browserstack.console': 'info',
  'browserstack.networkLogs': 'true',
  'browserstack.debug': 'true',
  'browserstack.video': 'true',
  'browserstack.timezone': 'Europe/Paris',
};

// Définition des capacités pour les sessions mobiles (iPhone, Android, etc.)
const mobileCapabilities = {
  // Nom de l'appareil et version d'OS
  deviceName: process.env.BS_DEVICE || 'iPhone 15 Pro Max',
  osVersion: process.env.BS_OS_VERSION || '18',

  // Navigateur mobile (Safari par défaut sur iOS)
  browser: process.env.BS_BROWSER || 'safari',
  // Spécifier que l'on utilise un vrai appareil mobile
  realMobile: 'true',

  // Options communes BrowserStack
  'browserstack.console': 'info',
  'browserstack.networkLogs': 'true',
  'browserstack.debug': 'true',
  'browserstack.video': 'true',
  'browserstack.timezone': 'Europe/Paris',
};

module.exports = {
  // Identifiants d'authentification BrowserStack (injectés par GitHub Actions ou .env)
  username: process.env.BROWSERSTACK_USERNAME,
  accessKey: process.env.BROWSERSTACK_ACCESS_KEY,

  // Déterminer l'exécution séquentielle vs parallèle
  runInOrder,

  // Nom du build visible dans le tableau de bord BrowserStack
  buildName:
    process.env.BROWSERSTACK_BUILD_NAME ||
    `Tricentis Demo Tests - ${now.toISOString().split('T')[0]} ${now
      .toTimeString()
      .slice(0, 5)}`,

  // Nom du projet dans BrowserStack
  projectName: 'Tricentis Demo Web Shop',

  // Choix des capacités en fonction du mode mobile/desktop
  capabilities: isMobile ? mobileCapabilities : desktopCapabilities,

  // Nombre de workers (1 en séquentiel, sinon la valeur demandée)
  workers: runInOrder ? 1 : requestedWorkers,

  // Timeout global des tests (en ms)
  timeout: 90000,

  // Pas de retry côté BrowserStack (géré par Playwright si nécessaire)
  retries: 0,
};