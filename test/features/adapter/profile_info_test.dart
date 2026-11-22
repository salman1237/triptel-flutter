import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/adapter/application/profile_info.dart';

void main() {
  group('ProfileInfo.fromRaw', () {
    test('parses a real-shaped enabled operational profile', () {
      final profile = ProfileInfo.fromRaw({
        'iccid': '8900000000000000001',
        'serviceProviderName': 'Triptel',
        'profileName': 'Triptel Travel',
        'profileNickname': null,
        'state': 'enabled',
        'profileClass': 'operational',
      });

      expect(profile.iccid, '8900000000000000001');
      expect(profile.serviceProviderName, 'Triptel');
      expect(profile.profileName, 'Triptel Travel');
      expect(profile.profileNickname, isNull);
      expect(profile.state, ProfileState.enabled);
      expect(profile.profileClass, ProfileClass.operational);
    });

    test('parses disabled test/provisioning classes', () {
      expect(
          ProfileInfo.fromRaw({'state': 'disabled', 'profileClass': 'test'})
              .state,
          ProfileState.disabled);
      expect(
          ProfileInfo.fromRaw(
                  {'state': 'disabled', 'profileClass': 'provisioning'})
              .profileClass,
          ProfileClass.provisioning);
    });

    test('an unrecognized state/class maps to undefined, not a crash', () {
      final profile = ProfileInfo.fromRaw(
          {'state': 'something_new', 'profileClass': 'something_else'});
      expect(profile.state, ProfileState.undefined);
      expect(profile.profileClass, ProfileClass.undefined);
    });

    test('missing fields map to undefined/null, never null-crashes', () {
      final profile = ProfileInfo.fromRaw(const {});
      expect(profile.state, ProfileState.undefined);
      expect(profile.profileClass, ProfileClass.undefined);
      expect(profile.iccid, isNull);
    });

    group('displayName', () {
      test('prefers the user nickname first', () {
        final profile = ProfileInfo.fromRaw({
          'profileNickname': 'My trip',
          'profileName': 'Triptel Travel',
          'serviceProviderName': 'Triptel',
        });
        expect(profile.displayName, 'My trip');
      });

      test('falls back to the profile name when no nickname is set', () {
        final profile = ProfileInfo.fromRaw({
          'profileName': 'Triptel Travel',
          'serviceProviderName': 'Triptel',
        });
        expect(profile.displayName, 'Triptel Travel');
      });

      test('falls back to the service provider when no name is set', () {
        final profile = ProfileInfo.fromRaw({'serviceProviderName': 'Triptel'});
        expect(profile.displayName, 'Triptel');
      });

      test('falls back to an honest label when nothing is set', () {
        final profile = ProfileInfo.fromRaw(const {});
        expect(profile.displayName, 'Unnamed profile');
      });
    });
  });

  group('CcidProfileListResult.fromRaw', () {
    test('parses a successful list with one profile', () {
      final result = CcidProfileListResult.fromRaw({
        'outcome': 'success',
        'profiles': [
          {'iccid': '123', 'state': 'enabled', 'profileClass': 'operational'},
        ],
      });

      expect(result.outcome, CcidProfileListOutcome.success);
      expect(result.profiles, hasLength(1));
      expect(result.profiles.single.iccid, '123');
    });

    test('a successful list with no profiles parses as an empty list', () {
      final result =
          CcidProfileListResult.fromRaw({'outcome': 'success', 'profiles': []});
      expect(result.outcome, CcidProfileListOutcome.success);
      expect(result.profiles, isEmpty);
    });

    test('parses read_failed with no profiles field', () {
      final result = CcidProfileListResult.fromRaw({'outcome': 'read_failed'});
      expect(result.outcome, CcidProfileListOutcome.readFailed);
      expect(result.profiles, isEmpty);
    });

    test('parses not_powered_on', () {
      expect(
          CcidProfileListResult.fromRaw({'outcome': 'not_powered_on'}).outcome,
          CcidProfileListOutcome.notPoweredOn);
    });

    test('parses detached (unplugged mid-read)', () {
      expect(CcidProfileListResult.fromRaw({'outcome': 'detached'}).outcome,
          CcidProfileListOutcome.detached);
    });

    test('an unrecognized outcome maps to unknown, not a crash', () {
      expect(
          CcidProfileListResult.fromRaw({'outcome': 'something_new'}).outcome,
          CcidProfileListOutcome.unknown);
    });

    test('a missing outcome field maps to unknown, never null-crashes', () {
      expect(CcidProfileListResult.fromRaw(const {}).outcome,
          CcidProfileListOutcome.unknown);
    });
  });
}
