/// FR-901: static content ported from the web's `/guides/esim-setup-guide`
/// (`docs/API.md` has no endpoint for this -- it's static copy, same on
/// both platforms, no backend call needed).
const iosSetupSteps = [
  'Connect your iPhone to Wi-Fi (installing an eSIM needs an internet '
      'connection).',
  'Open the QR code from your order, or open My eSIMs in this app and '
      'tap "Install eSIM".',
  'Go to Settings -> Cellular (or Mobile Service) -> Add eSIM -> Use QR '
      'Code, and scan it -- or tap the install link directly.',
  'Choose labels for your lines (e.g. keep your home line as default for '
      'calls/SMS, and use the new eSIM for data) under Settings -> '
      'Cellular.',
  "Turn on Data Roaming for the new eSIM: Settings -> Cellular -> [your "
      'eSIM] -> Network Selection / Data Roaming -> On.',
  "That's it -- your validity period starts counting once the eSIM "
      'connects to a network in your destination, not at install.',
];

const androidSetupSteps = [
  'Connect your Android phone to Wi-Fi.',
  'Open the QR code from your order, or open My eSIMs in this app and '
      'tap "Install eSIM" (on supported devices this installs directly, '
      'no scanning needed).',
  'Otherwise go to Settings -> Network & internet -> SIMs (or '
      '"Connections" -> "SIM card manager" on Samsung) -> Add eSIM / '
      'Download a SIM -> scan the QR code.',
  'Make sure the new eSIM is enabled, and that mobile data + data '
      'roaming are turned on for it under its SIM settings.',
  'Set your preferred SIM for mobile data to the new eSIM so your phone '
      'actually uses it abroad.',
];

const setupGuideTroubleshooting = [
  'Toggle Airplane Mode on and off, or restart your phone.',
  'Check the eSIM line has Data Roaming turned on -- most data-only '
      'eSIMs need this explicitly enabled.',
  'Make sure the eSIM line (not your home SIM) is selected for mobile '
      'data.',
  "Check your eSIM's usage and expiry any time from My eSIMs.",
  // Web's source links this to /support with the order number; no
  // general support-ticket screen exists yet (FR-1101/1102, not_started
  // -- only FR-410's per-eSIM "Report a problem" does), so this stays
  // plain text rather than a dead link.
  'Still stuck? Contact Support with your order number.',
];
