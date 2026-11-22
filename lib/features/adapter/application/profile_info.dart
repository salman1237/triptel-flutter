/// FR-L916: a single profile on the card, as reported by lpac's
/// `es10c_get_profiles_info()` -- the real, observed state, never a
/// prediction. The ICCID stays on-device (`docs/Rules.md`: "EID,
/// ICCIDs and card info stay on the device"); the UI masks it by
/// default, same as the EID.
enum ProfileState { enabled, disabled, undefined }

enum ProfileClass { test, provisioning, operational, undefined }

class ProfileInfo {
  const ProfileInfo({
    required this.iccid,
    required this.serviceProviderName,
    required this.profileName,
    required this.profileNickname,
    required this.state,
    required this.profileClass,
  });

  final String? iccid;
  final String? serviceProviderName;
  final String? profileName;
  final String? profileNickname;
  final ProfileState state;
  final ProfileClass profileClass;

  /// The name to show: the user's own nickname first (FR-L920), then
  /// the card's own profile name, then the service provider, then a
  /// final honest fallback -- never a blank label.
  String get displayName => profileNickname?.trim().isNotEmpty == true
      ? profileNickname!
      : (profileName?.trim().isNotEmpty == true
          ? profileName!
          : (serviceProviderName?.trim().isNotEmpty == true
              ? serviceProviderName!
              : 'Unnamed profile'));

  factory ProfileInfo.fromRaw(Map<String, dynamic> raw) => ProfileInfo(
        iccid: raw['iccid'] as String?,
        serviceProviderName: raw['serviceProviderName'] as String?,
        profileName: raw['profileName'] as String?,
        profileNickname: raw['profileNickname'] as String?,
        state: _parseState(raw['state'] as String?),
        profileClass: _parseClass(raw['profileClass'] as String?),
      );
}

ProfileState _parseState(String? raw) => switch (raw) {
      'enabled' => ProfileState.enabled,
      'disabled' => ProfileState.disabled,
      _ => ProfileState.undefined,
    };

ProfileClass _parseClass(String? raw) => switch (raw) {
      'test' => ProfileClass.test,
      'provisioning' => ProfileClass.provisioning,
      'operational' => ProfileClass.operational,
      _ => ProfileClass.undefined,
    };

/// FR-L916: the real, observed outcome of listing profiles on the
/// card -- never a prediction.
enum CcidProfileListOutcome {
  success,
  readFailed,
  notPoweredOn,

  /// The reader was unplugged mid-read -- distinct from a generic
  /// [readFailed] (re-checked natively against the live USB device
  /// list at the moment of failure, not guessed), same as FR-L914/915.
  detached,

  /// The native side returned an `outcome` string this Dart code
  /// doesn't recognize yet -- surfaced honestly rather than silently
  /// mapped to some other outcome.
  unknown,
}

class CcidProfileListResult {
  const CcidProfileListResult(
      {required this.outcome, this.profiles = const []});

  final CcidProfileListOutcome outcome;
  final List<ProfileInfo> profiles;

  factory CcidProfileListResult.fromRaw(Map<String, dynamic> raw) =>
      CcidProfileListResult(
        outcome: _parseOutcome(raw['outcome'] as String?),
        profiles: (raw['profiles'] as List<dynamic>?)
                ?.map((p) =>
                    ProfileInfo.fromRaw((p as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}

CcidProfileListOutcome _parseOutcome(String? raw) => switch (raw) {
      'success' => CcidProfileListOutcome.success,
      'read_failed' => CcidProfileListOutcome.readFailed,
      'not_powered_on' => CcidProfileListOutcome.notPoweredOn,
      'detached' => CcidProfileListOutcome.detached,
      _ => CcidProfileListOutcome.unknown,
    };
