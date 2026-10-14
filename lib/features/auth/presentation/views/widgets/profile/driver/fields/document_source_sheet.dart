import 'package:flutter/material.dart';

import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../shared/widgets/bottomsheets/app_option_sheet.dart';
import '../../../../../../data/models/document_source.dart';

/// Asks where a KYC document comes from: camera, gallery or a file (an image
/// or a PDF). Returns null if dismissed.
Future<DocumentSource?> showDocumentSourceSheet(BuildContext context) {
  return showAppOptionSheet<DocumentSource>(
    context: context,
    title: AppStrings.docSourceTitle,
    options: const [
      AppSheetOption(
        icon: Icons.camera_alt_rounded,
        label: AppStrings.docSourceCamera,
        subtitle: AppStrings.docSourceCameraHint,
        value: DocumentSource.camera,
      ),
      AppSheetOption(
        icon: Icons.photo_library_rounded,
        label: AppStrings.docSourceGallery,
        subtitle: AppStrings.docSourceGalleryHint,
        value: DocumentSource.gallery,
      ),
      AppSheetOption(
        icon: Icons.picture_as_pdf_rounded,
        label: AppStrings.docSourceFile,
        subtitle: AppStrings.docSourceFileHint,
        value: DocumentSource.file,
      ),
    ],
  );
}
