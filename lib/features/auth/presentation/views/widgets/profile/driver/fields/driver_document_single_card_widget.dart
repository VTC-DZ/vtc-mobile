import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../data/models/driver_document.dart';
import 'driver_document_card_face.dart';

/// Card for a one-sided document (vehicle photo, insurance, registration):
/// a single [DriverDocumentCardFace] at the shared card height.
class DriverDocumentSingleCardWidget extends StatelessWidget {
  const DriverDocumentSingleCardWidget({
    super.key,
    required this.badgeLabel,
    required this.document,
    required this.onTap,
    this.enabled = true,
  });

  /// Short rotated badge text shown in the left strip, e.g. "REG".
  final String badgeLabel;

  final DriverDocument document;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130.h,
      child: DriverDocumentCardFace(
        badgeLabel: badgeLabel,
        document: document,
        onTap: onTap,
        enabled: enabled,
      ),
    );
  }
}
