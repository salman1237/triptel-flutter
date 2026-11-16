import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/shared_prefs_provider.dart';
import 'pending_purchase.dart';

const _pendingPurchasePrefsKey = 'checkout.pendingPurchase';

/// FR-106: a guest's in-progress purchase, persisted the moment they're
/// sent to login/register/Google (never attempted against the real,
/// auth-gated checkout endpoints as a guest -- see FR-105b), consumed once
/// by whichever auth flow they complete.
class PendingPurchaseNotifier extends AsyncNotifier<PendingPurchase?> {
  @override
  Future<PendingPurchase?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final raw = prefs.getString(_pendingPurchasePrefsKey);
    if (raw == null) return null;
    return PendingPurchase.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(PendingPurchase purchase) async {
    state = AsyncData(purchase);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
        _pendingPurchasePrefsKey, jsonEncode(purchase.toJson()));
  }

  Future<void> clear() async {
    state = const AsyncData(null);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_pendingPurchasePrefsKey);
  }
}

final pendingPurchaseProvider =
    AsyncNotifierProvider<PendingPurchaseNotifier, PendingPurchase?>(
  PendingPurchaseNotifier.new,
);
