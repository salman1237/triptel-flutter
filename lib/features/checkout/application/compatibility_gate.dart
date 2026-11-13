import '../../compatibility/application/esim_verdict.dart';

/// FR-301's pure decision rule (Architecture.md: business rules in plain
/// Dart): what the pre-checkout compatibility gate should do for a given
/// verdict. Never blocks the purchase -- every outcome has a path to
/// `proceed`.
enum GateAction { proceed, showNotSupportedDialog, showUnknownNote }

GateAction decideGateAction(EsimVerdictKind kind) => switch (kind) {
      EsimVerdictKind.supported => GateAction.proceed,
      EsimVerdictKind.notSupported => GateAction.showNotSupportedDialog,
      EsimVerdictKind.unknown => GateAction.showUnknownNote,
    };
