import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../data/quran_data.dart';
import '../models/highlight_verse.dart';
import 'bsmallah_widget.dart';
import 'surah_header_widget.dart';

/// A highly customizable widget that displays a specific Surah as a vertically scrollable list.
class QuranSurahListView extends StatelessWidget {
  /// The Surah number (1-114) to be displayed.
  final int surahNumber;

  /// A normal list of [HighlightVerse] for dynamically highlighting specific Ayahs.
  final List<HighlightVerse> highlights;

  /// Callback fired when a specific verse is long-pressed.
  /// Provides the [surahNumber], [verseNumber], and touch [details].
  final void Function(
      int surahNumber,
      int verseNumber,
      LongPressStartDetails details,
      )? onLongPress;

  /// Custom text styling for the default Quranic text rendering.
  /// Use this to adjust font size, color, or height.
  final TextStyle? ayahStyle;

  /// A custom builder to completely override the default Surah Header widget.
  final Widget Function(BuildContext context, int surahNumber)? surahHeaderBuilder;

  /// A custom builder to completely override the default Basmallah widget.
  final Widget Function(BuildContext context, int surahNumber)? basmallahBuilder;

  /// A powerful builder that grants FULL CONTROL over how each Ayah is rendered.
  final Widget Function(
      BuildContext context,
      int surahNumber,
      int verseNumber,
      String othmanicText,
      bool isHighlighted,
      Color highlightColor,
      )? ayahBuilder;

  /// Controller to programmatically jump or scroll to a specific Ayah.
  final ItemScrollController? itemScrollController;

  /// Listener to track which Ayahs are currently visible on the screen.
  final ItemPositionsListener? itemPositionsListener;

  /// The initial index to scroll to when the view is first created.
  /// Default is 0 (the top of the Surah).
  final int initialScrollIndex;

  /// Creates a [QuranSurahListView] to render a single Surah efficiently.
  const QuranSurahListView({
    super.key,
    required this.surahNumber,
    this.highlights = const [],
    this.onLongPress,
    this.ayahStyle,
    this.surahHeaderBuilder,
    this.basmallahBuilder,
    this.ayahBuilder,
    this.itemScrollController,
    this.itemPositionsListener,
    this.initialScrollIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Fetch all Ayahs belonging to the requested Surah
    final List surahAyahs = quran
        .where((ayah) => ayah['sora'] == surahNumber)
        .toList();

    // Default package styling for Othmanic text
    final defaultStyle = TextStyle(
      fontSize: 26,
      fontFamily: "hafs",
      package: 'qcf_quran_lite',
      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      height: 1.8,
    );
    final finalStyle = ayahStyle != null
        ? defaultStyle.merge(ayahStyle)
        : defaultStyle;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        initialScrollIndex: initialScrollIndex,
        physics: const BouncingScrollPhysics(),
        itemCount: surahAyahs.length + 1, // +1 to accommodate the Header/Basmallah
        itemBuilder: (context, index) {
          // Render Header and Basmallah at index 0
          if (index == 0) {
            return Column(
              children: [
                const SizedBox(height: 16),
                surahHeaderBuilder?.call(context, surahNumber) ??
                    SurahHeaderWidget(suraNumber: surahNumber),
                if (surahNumber != 9) // No Basmallah for Surah At-Tawbah
                  basmallahBuilder?.call(context, surahNumber) ??
                      BasmallahWidget(surahNumber),
                const SizedBox(height: 16),
              ],
            );
          }

          // Extract Ayah data (index - 1 because index 0 is the header)
          final ayahData = surahAyahs[index - 1];
          final int verseNumber = ayahData['aya_no'];

          // Clean the Othmanic text
          final String othmanicText = ayahData['aya_text_othmanic']
              .toString()
              .replaceAll('\n', '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // التحقق من الـ Highlights باستخدام الليست العادية
          final isHighlighted = highlights.any(
                (h) => h.surah == surahNumber && h.verseNumber == verseNumber,
          );

          final highlightColor = isHighlighted
              ? highlights.firstWhere(
                (h) => h.surah == surahNumber && h.verseNumber == verseNumber,
          ).color
              : Colors.transparent;

          return GestureDetector(
            onLongPressStart: (details) {
              if (onLongPress != null) {
                onLongPress!(surahNumber, verseNumber, details);
              }
            },
            child: ayahBuilder != null
                ? ayahBuilder!(
              context,
              surahNumber,
              verseNumber,
              othmanicText,
              isHighlighted,
              highlightColor,
            )
                : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? highlightColor.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                othmanicText,
                textAlign: TextAlign.right,
                style: finalStyle,
              ),
            ),
          );
        },
      ),
    );
  }
}