/// App-wide environment config. Only `ApiClient` reads [apiBaseUrl]; nothing
/// else in the app should hardcode a host (Rules.md: beta API only).
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://beta.triptel.co/api/v1',
  );
}
