/// FR-405: lifecycle banners for the four terminal `esim_status` values
/// (API.md section 7) that mean the profile can no longer be installed or
/// topped up. `null` for every other status (ALLOCATED/RELEASED/INSTALLED/
/// ACTIVE) -- those are all normal, in-progress states.
String? lifecycleBannerMessage(String esimStatus) => switch (esimStatus) {
      'SUSPENDED' =>
        'This eSIM has been suspended -- install and top-up are unavailable.',
      'REVOKED' =>
        'This eSIM has been revoked -- install and top-up are unavailable.',
      'CANCELLED' =>
        'This order was cancelled -- install and top-up are unavailable.',
      'EXPIRED' =>
        'This eSIM has expired -- install and top-up are unavailable.',
      _ => null,
    };

/// FR-405: "disable install and top-up" for those same four statuses.
bool installAndTopupDisabled(String esimStatus) =>
    lifecycleBannerMessage(esimStatus) != null;
