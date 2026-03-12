import 'package:flutter/material.dart';
import '../utils/quran_text_styles.dart';

/// A responsive widget that displays the decorative header banner for a Surah.
///
/// This widget uses a [LayoutBuilder] to automatically scale both the banner
/// image and the typography dynamically based on the available screen width.
class SurahHeaderWidget extends StatelessWidget {
  /// The Surah number (from 1 to 114) to be displayed inside the header banner.
  final int suraNumber;

  const SurahHeaderWidget({super.key, required this.suraNumber});

  @override
  Widget build(BuildContext context) {
    // The path to the decorative banner image within the package assets.
    const String imagePath = "assets/surah_banner.png";

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dimensions based on available width to ensure it looks good
        // on both mobile and tablet devices.
        final double availableWidth = constraints.maxWidth;
        final double headerWidth = availableWidth * 0.9; // Banner takes up 90% of width
        final double dynamicFontSize = headerWidth * 0.085; // Font scales with banner

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The background decorative banner image.
              Image(
                image: const AssetImage(imagePath, package: 'qcf_quran_lite'),
                width: headerWidth,
                fit: BoxFit.contain,
              ),

              // The Surah number text overlaid exactly in the center of the banner.
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "$suraNumber",
                  style: QuranTextStyles.surahHeaderStyle(
                    fontSize: dynamicFontSize,
                    // Adapts color based on the current theme (light/dark mode)
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}