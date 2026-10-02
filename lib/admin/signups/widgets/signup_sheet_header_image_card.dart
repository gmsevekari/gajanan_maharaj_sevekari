import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// Add/replace/remove controls for a sheet's header/display image, shown
/// on [AdminSignupSheetDetailScreen] right under the overview card.
class SignupSheetHeaderImageCard extends StatelessWidget {
  final String? headerImageUrl;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const SignupSheetHeaderImageCard({
    super.key,
    required this.headerImageUrl,
    required this.isUploading,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasImage = headerImageUrl != null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.signupHeaderImageLabel,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  // No fixed height: the image lays out at its own
                  // resolution (width-matched, aspect-ratio preserved) so
                  // nothing is cropped, with this minimum only as a floor
                  // for small images and a stable placeholder while loading.
                  constraints: const BoxConstraints(minHeight: 150),
                  child: Image.network(
                    headerImageUrl!,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    semanticLabel: l10n.signupHeaderImageLabel,
                    errorBuilder: (context, error, stackTrace) => Container(
                      constraints: const BoxConstraints(minHeight: 150),
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.appColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isUploading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.signupUploadingImage),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  OutlinedButton.icon(
                    key: const Key('addOrReplaceHeaderImageButton'),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      hasImage
                          ? l10n.signupReplaceImageButton
                          : l10n.signupAddImageButton,
                    ),
                    onPressed: onPickImage,
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      key: const Key('removeHeaderImageButton'),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.signupRemoveImageButton),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: onRemoveImage,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
