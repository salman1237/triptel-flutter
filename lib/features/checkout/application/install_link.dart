/// FR-310/404, API.md "Install links (client-side, from `lpa_string`)":
/// only when [lpaString] starts with `LPA:` does a 1-tap install link exist
/// at all -- otherwise the user falls back to manual SM-DP+/activation-code
/// entry. [isIOS] picks the OS-specific universal link that triggers the
/// native eSIM-install sheet.
String? buildInstallUrl(String lpaString, {required bool isIOS}) {
  if (!lpaString.startsWith('LPA:')) return null;
  final host = isIOS ? 'esimsetup.apple.com' : 'esimsetup.android.com';
  final encoded = Uri.encodeComponent(lpaString);
  return 'https://$host/esim_qrcode_provisioning?carddata=$encoded';
}
