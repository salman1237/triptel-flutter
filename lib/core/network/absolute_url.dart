import '../config/env.dart';

/// Resolves a server-relative asset path (e.g. `/api/v1/uploads/branding/
/// bangla_qr_image-....png`, as `/settings/public` returns for images) to a
/// full URL, using only [Env.apiBaseUrl]'s scheme+host -- never a hardcoded
/// one (Rules.md: beta API only). The path itself is already absolute from
/// the API root, not relative to `/api/v1`, so only scheme+authority are
/// taken from the base URL.
String resolveApiUrl(String path) =>
    Uri.parse(Env.apiBaseUrl).replace(path: path).toString();
