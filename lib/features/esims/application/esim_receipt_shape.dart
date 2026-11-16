import '../data/models/esim_status.dart';

/// FR-409 receipt's data-amount line -- same trimmed "{X} GB"/"{X} MB"/
/// "Unlimited" shape as FR-402's `esimDataLabel`, duplicated rather than
/// shared since it reads off [EsimStatusProduct] (status endpoint), not
/// [MyEsim] (list endpoint) -- different models, same small formatting
/// rule, same precedent as `esim_card_shape.dart` already not sharing with
/// `plan_shape.dart`.
String receiptDataLabel(EsimStatusProduct product) {
  if (product.isUnlimited) return 'Unlimited';
  final gb = product.dataAmountGb;
  if (gb < 1) return '${(gb * 1000).round()} MB';
  final rounded = (gb * 100).round() / 100;
  var text = rounded.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return '$text GB';
}
