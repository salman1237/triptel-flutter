/// FR-L910: a USB CCID (0x0B) smart-card reader currently attached to
/// the phone, as reported by `UsbCcidReaders.kt`'s unprivileged
/// `UsbManager` enumeration. Never carries card contents -- just the
/// reader's own USB identity and whether this app has been granted
/// permission to open it (FR-L911).
class CcidReader {
  const CcidReader({
    required this.id,
    required this.name,
    required this.vendorId,
    required this.productId,
    required this.hasPermission,
  });

  /// Stable only while attached (`UsbDevice.deviceId`); a reader
  /// unplugged and replugged gets a new id.
  final int id;

  /// A human-readable product name (falls back to the device node path
  /// natively if the device doesn't report one).
  final String name;
  final int vendorId;
  final int productId;

  /// Whether this app already holds the per-device USB permission
  /// (FR-L911 requests it; this is just the current, observed state).
  final bool hasPermission;

  factory CcidReader.fromRaw(Map<String, dynamic> raw) => CcidReader(
        id: raw['id'] as int,
        name: raw['name'] as String? ?? 'Unknown reader',
        vendorId: raw['vendorId'] as int? ?? 0,
        productId: raw['productId'] as int? ?? 0,
        hasPermission: raw['hasPermission'] as bool? ?? false,
      );

  static List<CcidReader> fromRawList(List<Map<String, dynamic>> raw) =>
      raw.map(CcidReader.fromRaw).toList();
}
