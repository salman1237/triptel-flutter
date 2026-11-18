/// FR-1104: contact shortcuts, built from `GET /settings/public`'s
/// `support_whatsapp`/`support_phone`/`support_email` (API.md section 1,
/// `PublicSettings` -- any field may be null, hide that shortcut, never
/// invent one). Pure URI builders so the launch targets are testable
/// without a widget tree (Architecture.md).
Uri contactWhatsappUri(String number) {
  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  return Uri.parse('https://wa.me/$digits');
}

Uri contactPhoneUri(String number) => Uri(scheme: 'tel', path: number);

Uri contactEmailUri(String email) => Uri(scheme: 'mailto', path: email);
