import 'package:flutter/material.dart';
import '../utils/quran_text_styles.dart';

/// Decorative header banner for a Surah.
///
/// The width is always 90% of the available width (same as before).
/// When the parent gives a bounded height, the banner stretches vertically to
/// fill it; otherwise it keeps its natural height.
class SurahHeaderWidget extends StatelessWidget {
  /// The Surah number (from 1 to 114) to be displayed inside the header banner.
  final int suraNumber;

  const SurahHeaderWidget({super.key, required this.suraNumber});

  static const double _verticalPadding = 8;

  @override
  Widget build(BuildContext context) {
    const String imagePath = "assets/surah_banner.png";

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double headerWidth = availableWidth * 0.9; // width unchanged

        // Height available for the image (null = unbounded -> natural height).
        final double? imageHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - _verticalPadding * 2).clamp(0.0, double.infinity)
            : null;

        // Keep the old width-based font size, but never let it exceed
        // what the banner height can hold.
        double fontSize = headerWidth * 0.085;
        if (imageHeight != null) {
          fontSize = fontSize.clamp(0.0, imageHeight * 0.6);
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
          width: double.infinity,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image(
                image: const AssetImage(imagePath, package: 'qcf_quran_lite'),
                width: headerWidth,
                height: imageHeight,
                // fill = stretch to the given height; contain = old behavior
                fit: imageHeight != null ? BoxFit.fill : BoxFit.contain,
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "$suraNumber",
                  style: QuranTextStyles.surahHeaderStyle(
                    fontSize: fontSize,
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