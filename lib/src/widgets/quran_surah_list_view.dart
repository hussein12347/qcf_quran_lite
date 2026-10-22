import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../qcf_quran_lite.dart';
import '../models/highlight_index.dart';
import '../models/highlight_style.dart';
import '../services/parsed_quran_data.dart';
import '../utils/tajweed_span_builder.dart';
import 'bsmallah_widget.dart';
import 'quran_line.dart';
import 'surah_header_widget.dart';

/// A scrollable list that renders a whole surah, one verse per item.
class QuranSurahListView extends StatelessWidget {
  /// The surah number (1-114) to render.
  final int surahNumber;

  /// Verse-level highlights.
  final List<HighlightVerse> highlights;

  /// Word-level highlights.
  final List<WordHighlight> wordHighlights;

  /// Controls how highlighted **verses** are painted.
  ///
  /// Defaults to a 30% opacity background with a 10px corner radius.
  /// `padding` / `margin` fall back to the list's built-in spacing when `null`.
  final AyahHighlightStyle ayahHighlightStyle;

  /// Controls how highlighted **words** are painted.
  final WordHighlightStyle wordHighlightStyle;

  /// Called when a verse is long-pressed.
  final void Function(
      int surahNumber, int verseNumber, LongPressStartDetails details)? onLongPress;

  /// Called when a word is tapped.
  final void Function(
      int surahNumber, int verseNumber, int wordIndex, String word)? onWordTap;

  /// Called when the ayah-number marker is tapped.
  final void Function(int surahNumber, int verseNumber)? onAyahNumberTap;

  /// Optional custom builder for the ayah-number marker.
  final AyahNumberBuilder? ayahNumberBuilder;

  /// Alignment of the custom ayah-number [WidgetSpan].
  final PlaceholderAlignment ayahNumberAlignment;

  /// Baseline of the custom ayah-number [WidgetSpan].
  final TextBaseline ayahNumberBaseline;

  /// Base text style for the verse body.
  final TextStyle? ayahStyle;

  /// Optional builder for the Surah header widget.
  final Widget Function(BuildContext context, int surahNumber)?
      surahHeaderBuilder;

  /// Optional builder for the Basmallah widget.
  final Widget Function(BuildContext context, int surahNumber)?
      basmallahBuilder;

  /// Optional builder that replaces the whole verse container.
  ///
  /// When provided, [ayahHighlightStyle] is **not** applied to the verse
  /// (you receive `isHighlighted` and `highlightColor` and style it yourself).
  /// Word highlights are still applied inside [ayahWidget].
  final Widget Function(
    BuildContext context,
    int surahNumber,
    int verseNumber,
    int pageNumber,
    Widget ayahWidget,
    bool isHighlighted,
    Color highlightColor,
  )? ayahBuilder;

  /// Controller used to scroll to a specific item.
  final ItemScrollController? itemScrollController;

  /// Listener for the positions of the visible items.
  final ItemPositionsListener? itemPositionsListener;

  /// Index of the item shown first.
  final int initialScrollIndex;

  /// When `true`, renders using `aya_text` with `uthmanic_hafs` font and Tajweed colors.
  /// When `false`, renders using smart QCF glyphs (`aya_text_othmanic`) and `hafs` font.
  final bool isTajweed;

  /// Whether the list is rendered on a dark background.
  final bool isDarkMode;

  /// Font size of the verse text. Defaults to `26`.
  final double? fontSize;

  const QuranSurahListView({
    super.key,
    required this.surahNumber,
    this.highlights = const [],
    this.wordHighlights = const [],
    this.ayahHighlightStyle = const AyahHighlightStyle(
      opacity: 0.3,
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    this.wordHighlightStyle = const WordHighlightStyle(),
    this.onWordTap,
    this.onAyahNumberTap,
    this.ayahNumberBuilder,
    this.ayahNumberAlignment = PlaceholderAlignment.middle,
    this.ayahNumberBaseline = TextBaseline.alphabetic,
    this.onLongPress,
    this.ayahStyle,
    this.surahHeaderBuilder,
    this.basmallahBuilder,
    this.ayahBuilder,
    this.itemScrollController,
    this.itemPositionsListener,
    this.initialScrollIndex = 0,
    this.isTajweed = false,
    this.isDarkMode = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> surahAyahs =
        activeQuran.where((ayah) => ayah['sora'] == surahNumber).toList();

    // Build O(1) lookup indices using the existing memoized indexers.
    final WordHighlightIndex wordHighlightIndex =
        MemoizedWordHighlightIndex().refresh(wordHighlights);
    final BookmarkIndex bookmarkIndex =
        MemoizedBookmarkIndex().refresh(highlights);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        initialScrollIndex: initialScrollIndex,
        physics: const BouncingScrollPhysics(),
        itemCount: surahAyahs.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                const SizedBox(height: 16),
                surahHeaderBuilder?.call(context, surahNumber) ??
                    SurahHeaderWidget(suraNumber: surahNumber),
                if (surahNumber != 9)
                  basmallahBuilder?.call(context, surahNumber) ??
                      BasmallahWidget(surahNumber),
                const SizedBox(height: 16),
              ],
            );
          }

          final Map<dynamic, dynamic> rawAyahMap =
              surahAyahs[index - 1] as Map<dynamic, dynamic>;
          final int verseNumber = rawAyahMap['aya_no'] as int;
          final int pageNumber = rawAyahMap['page'] as int;

          // Parse the verse using the unified word parser from parsed_quran_data.dart.
          final ParsedAyahData parsedAyah = parseAyahFromMap(
            rawAyahMap,
            isTajweed: isTajweed,
          );
          if (parsedAyah.words.isEmpty) return const SizedBox.shrink();

          final Color baseTextColor = isDarkMode
              ? Colors.white
              : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black);

          // uthmanic_hafs for Tajweed, hafs (QCF) for the normal smart mode.
          final TextStyle defaultStyle = ayahStyle ??
              (isTajweed
                  ? QuranTextStyles.tajweedHafsStyle(
                      fontSize: fontSize ?? 26,
                      color: baseTextColor,
                      height: 1.8,
                    )
                  : QuranTextStyles.hafsStyle(
                      fontSize: fontSize ?? 26,
                      color: baseTextColor,
                      height: 1.8,
                    ));

          final TextStyle mainTextStyle =
              defaultStyle.copyWith(color: baseTextColor);

          // Ayah-number style:
          // - Tajweed: QCF hafs font to show the ornamented glyph.
          // - Normal: same base style as the verse text.
          final Color numberColor =
              isDarkMode ? Colors.white : Theme.of(context).primaryColor;
          final TextStyle numberTextStyle = isTajweed
              ? QuranTextStyles.hafsStyle(
                  fontSize: fontSize ?? 26,
                  color: numberColor,
                )
              : defaultStyle.copyWith(color: numberColor);

          final List<InlineSpan> wordSpans = [];

          if (isTajweed) {
            final regularWords = <ParsedWordData>[];
            final regularTexts = <String>[];
            final recognizers = <TapGestureRecognizer?>[];

            for (final wordData in parsedAyah.words) {
              if (!wordData.isGlyph) {
                regularWords.add(wordData);
                regularTexts.add(wordData.text);
                final wIdx = wordData.wordIndex!;
                recognizers.add(
                  onWordTap == null
                      ? null
                      : (TapGestureRecognizer()
                        ..onTap = () => onWordTap?.call(
                              surahNumber,
                              verseNumber,
                              wIdx,
                              wordData.text,
                            )),
                );
              }
            }

            // Analyse the whole verse in connected context for Tajweed rules.
            final List<List<TextSpan>> annotatedWords =
                TajweedSpanBuilder.buildAyahWordsWithContext(
              words: regularTexts,
              baseStyle: mainTextStyle,
              isDarkMode: isDarkMode,
              recognizers: recognizers,
            );

            int regIdx = 0;
            for (final wordData in parsedAyah.words) {
              if (wordData.isGlyph) {
                _appendGlyphSpan(
                  context: context,
                  wordSpans: wordSpans,
                  verseNumber: verseNumber,
                  glyph: wordData.text,
                  numberTextStyle: numberTextStyle,
                );
              } else {
                final spans = annotatedWords[regIdx];
                final wIdx = wordData.wordIndex!;
                final WordHighlight? h =
                    wordHighlightIndex.lookup(surahNumber, verseNumber, wIdx);

                final VoidCallback? onTapCallback = onWordTap == null
                    ? null
                    : () => onWordTap?.call(
                          surahNumber,
                          verseNumber,
                          wIdx,
                          wordData.text,
                        );

                wordSpans.addAll(
                  wordHighlightStyle.applyToWordSpans(
                    wordSpans: spans,
                    highlight: h,
                    onTap: onTapCallback,
                  ),
                );
                wordSpans.add(TextSpan(text: ' ', style: mainTextStyle));
                regIdx++;
              }
            }
          } else {
            // Normal mode (smart QCF).
            for (final wordData in parsedAyah.words) {
              if (wordData.isGlyph) {
                _appendGlyphSpan(
                  context: context,
                  wordSpans: wordSpans,
                  verseNumber: verseNumber,
                  glyph: wordData.text,
                  numberTextStyle: numberTextStyle,
                );
              } else {
                final int wIdx = wordData.wordIndex!;
                final WordHighlight? h =
                    wordHighlightIndex.lookup(surahNumber, verseNumber, wIdx);

                final VoidCallback? onTapCallback = onWordTap == null
                    ? null
                    : () => onWordTap?.call(
                          surahNumber,
                          verseNumber,
                          wIdx,
                          wordData.text,
                        );

                final baseWordSpan = TextSpan(
                  text: wordData.text,
                  style: mainTextStyle,
                  recognizer: onTapCallback == null
                      ? null
                      : (TapGestureRecognizer()..onTap = onTapCallback),
                );

                wordSpans.addAll(
                  wordHighlightStyle.applyToWordSpans(
                    wordSpans: [baseWordSpan],
                    highlight: h,
                    onTap: onTapCallback,
                  ),
                );
                wordSpans.add(TextSpan(text: ' ', style: mainTextStyle));
              }
            }
          }

          final Widget preBuiltAyahWidget = Text.rich(
            TextSpan(children: wordSpans),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          );

          // Verse-level highlight color (null when not highlighted).
          final Color? verseHighlightColor =
              bookmarkIndex.lookup(surahNumber, verseNumber)?.color;
          final bool isHighlighted = verseHighlightColor != null;

          Widget ayahContent;
          if (ayahBuilder != null) {
            ayahContent = ayahBuilder!(
              context,
              surahNumber,
              verseNumber,
              pageNumber,
              preBuiltAyahWidget,
              isHighlighted,
              verseHighlightColor ?? Colors.transparent,
            );
          } else {
            final bool useWrapper =
                isHighlighted && ayahHighlightStyle.wrapperBuilder != null;

            final Widget container = Container(
              width: double.infinity,
              padding: ayahHighlightStyle.padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: ayahHighlightStyle.margin ??
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              // When a wrapperBuilder is used it is responsible for painting.
              decoration: useWrapper
                  ? null
                  : ayahHighlightStyle.decorationFor(verseHighlightColor),
              child: preBuiltAyahWidget,
            );

            ayahContent = useWrapper
                ? ayahHighlightStyle.wrapperBuilder!(
                    context, container, verseHighlightColor)
                : container;
          }

          final Widget ayahInteractiveWidget = GestureDetector(
            onLongPressStart: (details) =>
                onLongPress?.call(surahNumber, verseNumber, details),
            child: ayahContent,
          );

          return KeyedSubtree(
            key: ValueKey('ayah_${surahNumber}_${verseNumber}_$isTajweed'),
            child: ayahInteractiveWidget,
          );
        },
      ),
    );
  }

  /// Appends the ayah-number marker (custom widget or QCF glyph) to [wordSpans].
  void _appendGlyphSpan({
    required BuildContext context,
    required List<InlineSpan> wordSpans,
    required int verseNumber,
    required String glyph,
    required TextStyle numberTextStyle,
  }) {
    if (ayahNumberBuilder != null) {
      Widget numberWidget = ayahNumberBuilder!(
        context,
        surahNumber,
        verseNumber,
        glyph,
        isDarkMode,
      );

      if (onAyahNumberTap != null) {
        numberWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onAyahNumberTap?.call(surahNumber, verseNumber),
          child: numberWidget,
        );
      }

      wordSpans.add(WidgetSpan(
        alignment: ayahNumberAlignment,
        baseline: ayahNumberBaseline,
        child: numberWidget,
      ));
    } else {
      wordSpans.add(TextSpan(
        text: glyph,
        style: numberTextStyle,
        recognizer: onAyahNumberTap == null
            ? null
            : (TapGestureRecognizer()
              ..onTap = () => onAyahNumberTap?.call(surahNumber, verseNumber)),
      ));
    }
  }
}