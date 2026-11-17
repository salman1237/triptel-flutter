import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../data/models/kyc_status.dart';

/// FR-1001's Identity verification row label/colour.
({String label, Color color}) kycStatusLabel(KycStatus status) {
  if (!status.submitted) {
    return (label: 'Not verified', color: AppColors.danger);
  }
  return switch (status.status) {
    'APPROVED' => (label: 'Verified', color: AppColors.success),
    'REJECTED' => (label: 'Rejected', color: AppColors.danger),
    'PENDING' => (label: 'Pending', color: AppColors.warning),
    _ => (label: status.status ?? 'Unknown', color: AppColors.warning),
  };
}
