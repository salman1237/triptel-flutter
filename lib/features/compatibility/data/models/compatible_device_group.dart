/// FR-952: curated eSIM-compatible device list, ported from the web
/// storefront's `guides/compatible-phones` page (frontend/src/app/guides/
/// compatible-phones/page.tsx) — not pulled from a device database, kept
/// short and grouped by brand; new models are added by editing this file.
class CompatibleDeviceGroup {
  const CompatibleDeviceGroup({required this.brand, required this.models});

  final String brand;
  final List<String> models;
}

const compatibleDeviceGroups = [
  CompatibleDeviceGroup(
    brand: 'Apple',
    models: [
      'iPhone 17, 17 Pro, 17 Pro Max, Air',
      'iPhone 16 series (including 16e)',
      'iPhone 15 series',
      'iPhone 14 series',
      'iPhone 13 series',
      'iPhone 12 series',
      'iPhone 11 series',
      'iPhone XS, XS Max, XR',
      'iPhone SE (2020 and later)',
    ],
  ),
  CompatibleDeviceGroup(
    brand: 'Samsung',
    models: [
      'Galaxy S25 / S24 / S23 / S22 / S21 / S20 series',
      'Galaxy Z Fold 3 and later, Z Flip 3 and later',
      'Galaxy Note 20 series',
    ],
  ),
  CompatibleDeviceGroup(
    brand: 'Google',
    models: [
      'Pixel 9 series',
      'Pixel 8 series',
      'Pixel 7 series',
      'Pixel 6 series',
      'Pixel 5',
      'Pixel 4 / 4a',
      'Pixel 3 / 3a',
    ],
  ),
  CompatibleDeviceGroup(
    brand: 'Other',
    models: [
      'Huawei P40, Mate 40 series and later',
      'Oppo Find X3, X5, X7 series',
      'Sony Xperia 10 IV and later, Xperia 1 IV and later',
      'Motorola Razr (2019 and later), Edge 40/50 series',
      'Honor Magic series, Honor 90 and later',
    ],
  ),
];
