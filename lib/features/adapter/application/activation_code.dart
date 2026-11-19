/// FR-L901: SGP.22's activation-code format, kept pure and unit-testable
/// (Architecture.md "eSIM adapter") so the parser can be proven correct
/// with no USB hardware, no QR scanner, no platform channel.
///
/// Spec shape: `LPA:1$<smdp-address>$<matching-id>[$<smdp-oid>[$<confirmation-code-required-flag>]]`
/// — `$`-delimited, version is always `1`, the matching id may be empty
/// (an SM-DS lookup), the last two fields are optional. Also accepted:
/// the lowercase `lpa:` scheme (the `lpa:` deep-link form,
/// `docs/OpenEUICC_Reference.md` section 2.4) and the string wrapped
/// inside a URL's `carddata` query parameter (API.md's own
/// `esimsetup.{apple,android}.com/esim_qrcode_provisioning?carddata=...`
/// install links, section "Install links").
library;

/// A successfully parsed activation code.
class ActivationCode {
  const ActivationCode({
    required this.smdpAddress,
    required this.matchingId,
    this.smdpOid,
    this.confirmationCodeRequired = false,
  });

  /// The SM-DP+ server hostname. Never empty — a missing one is a parse
  /// error ([ActivationCodeError.missingSmdpAddress]), not an empty string
  /// here.
  final String smdpAddress;

  /// May be empty: SGP.22 allows an empty matching id when the SM-DP+ is
  /// expected to resolve the profile via SM-DS instead.
  final String matchingId;

  /// SM-DP+ OID, rarely present. `null` when the field was absent from
  /// the source string (distinct from an explicit empty field).
  final String? smdpOid;

  /// SGP.22's confirmation-code-required flag (field 5 == `"1"`).
  final bool confirmationCodeRequired;

  /// Reconstructs the `LPA:1$...` form. Not guaranteed byte-identical to
  /// whatever was parsed (e.g. an explicit empty oid field collapses to
  /// "absent" unless a confirmation code is required), but always a valid,
  /// equivalent activation code per SGP.22's positional field rules (the
  /// confirmation-code flag needs the oid slot to exist, even empty).
  String toLpaString() {
    final fields = ['1', smdpAddress, matchingId];
    if (confirmationCodeRequired) {
      fields.add(smdpOid ?? '');
      fields.add('1');
    } else if (smdpOid != null) {
      fields.add(smdpOid!);
    }
    return 'LPA:${fields.join('\$')}';
  }

  /// A masked label safe to show before the user confirms a download,
  /// e.g. for FR-L902's preview: "smdp.io · AB12…" (matching id longer
  /// than 4 chars is truncated; shorter ids show in full — nothing to
  /// usefully hide in a 2-3 char id).
  String maskedLabel() {
    final id = matchingId.isEmpty
        ? '(no matching id)'
        : (matchingId.length > 4
            ? '${matchingId.substring(0, 4)}…'
            : matchingId);
    return '$smdpAddress · $id';
  }
}

enum ActivationCodeError {
  /// Didn't start with `LPA:`/`lpa:` (after unwrapping a URL, if any).
  wrongPrefix,

  /// The version field wasn't `1` (the only version SGP.22 defines).
  unsupportedVersion,

  /// Fewer than 2 fields after the version (need at least smdp-address
  /// and matching-id, even if the latter is an empty string).
  tooFewFields,

  /// The smdp-address field was empty.
  missingSmdpAddress,

  /// More than 4 fields after the version.
  tooManyFields,

  /// The 5th field (confirmation-code-required) was present but wasn't
  /// `0` or `1`.
  invalidConfirmationCodeFlag,
}

sealed class ActivationCodeResult {
  const ActivationCodeResult();
}

class ActivationCodeParsed extends ActivationCodeResult {
  const ActivationCodeParsed(this.code);
  final ActivationCode code;
}

class ActivationCodeInvalid extends ActivationCodeResult {
  const ActivationCodeInvalid(this.error);
  final ActivationCodeError error;
}

/// Parses [input] (raw QR/paste/manual text) into an [ActivationCode],
/// or a typed [ActivationCodeError] — never throws.
ActivationCodeResult parseActivationCode(String input) {
  final trimmed = input.trim();
  final unwrapped = _unwrapCarddataUrl(trimmed) ?? trimmed;

  if (!unwrapped.toLowerCase().startsWith('lpa:')) {
    return const ActivationCodeInvalid(ActivationCodeError.wrongPrefix);
  }
  final body = unwrapped.substring(4);
  final fields = body.split(r'$');

  if (fields.isEmpty || fields.first != '1') {
    return const ActivationCodeInvalid(ActivationCodeError.unsupportedVersion);
  }
  if (fields.length < 3) {
    return const ActivationCodeInvalid(ActivationCodeError.tooFewFields);
  }
  if (fields.length > 5) {
    return const ActivationCodeInvalid(ActivationCodeError.tooManyFields);
  }

  final smdpAddress = fields[1];
  if (smdpAddress.isEmpty) {
    return const ActivationCodeInvalid(ActivationCodeError.missingSmdpAddress);
  }
  final matchingId = fields[2];
  final smdpOid = fields.length > 3 ? fields[3] : null;

  var confirmationCodeRequired = false;
  if (fields.length > 4) {
    final flag = fields[4];
    if (flag != '0' && flag != '1') {
      return const ActivationCodeInvalid(
          ActivationCodeError.invalidConfirmationCodeFlag);
    }
    confirmationCodeRequired = flag == '1';
  }

  return ActivationCodeParsed(ActivationCode(
    smdpAddress: smdpAddress,
    matchingId: matchingId,
    smdpOid: smdpOid,
    confirmationCodeRequired: confirmationCodeRequired,
  ));
}

/// If [input] is a URL carrying the activation code in a `carddata` query
/// parameter (the install-link shape API.md documents), returns the
/// decoded value; otherwise `null`. [Uri.queryParameters] already
/// percent-decodes the value for us.
String? _unwrapCarddataUrl(String input) {
  final uri = Uri.tryParse(input);
  if (uri == null || !uri.hasScheme || !uri.hasQuery) return null;
  for (final entry in uri.queryParameters.entries) {
    if (entry.key.toLowerCase() == 'carddata') return entry.value;
  }
  return null;
}

/// FR-L901: builds an [ActivationCode] from this app's own order/eSIM
/// data (API.md section 7-8's `lpa_string`/`smdp_address`/`matching_id`)
/// rather than from scanned/pasted text — used by FR-L922's "Install to
/// USB adapter" action. Prefers the full `lpaString` (it may carry an oid
/// or confirmation-code flag the two separate fields don't); falls back
/// to building one from [smdpAddress] + [matchingId] directly.
ActivationCodeResult buildActivationCodeFromOrderData({
  String? lpaString,
  String? smdpAddress,
  String? matchingId,
}) {
  if (lpaString != null && lpaString.isNotEmpty) {
    return parseActivationCode(lpaString);
  }
  if (smdpAddress != null && smdpAddress.isNotEmpty) {
    return ActivationCodeParsed(ActivationCode(
      smdpAddress: smdpAddress,
      matchingId: matchingId ?? '',
    ));
  }
  return const ActivationCodeInvalid(ActivationCodeError.missingSmdpAddress);
}
