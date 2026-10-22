import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../qcf_quran_lite.dart';
import '../models/highlight_index.dart';
import '../models/highlight_style.dart';
import '../services/parsed_quran_data.dart';
import '../utils/tajweed_span_builder.dart';

/// Builds a custom widget for the ayah-number marker.
///
/// [glyph] is the QCF glyph of the ayah number and [isDark] tells whether the
/// surrounding content is rendered on a dark background.
typedef AyahNumberBuilder = Widget Function(
  BuildContext context,
  int surahNumber,
  int ayahNumber,
  String glyph,
  bool isDark,
);

/// Renders a single line of a Mus'haf page.
///
/// Supports tap / long-press interaction, verse highlights (bookmarks),
/// word highlights and an optional Tajweed rendering mode.
class QuranLine extends StatefulWidget {
  /// Creates a Quran line.
  const QuranLine({
    super.key,
    required this.parsedAyahs,
    this.wordHighlightIndex = WordHighlightIndex.empty,
    this.bookmarkIndex = BookmarkIndex.empty,
    this.ayahHighlightStyle = const AyahHighlightStyle(),
    this.wordHighlightStyle = const WordHighlightStyle(),
    this.boxFit = BoxFit.fill,
    this.onLongPress,
    this.onWordTap,
    this.onAyahNumberTap,
    this.ayahNumberBuilder,
    this.ayahNumberAlignment = PlaceholderAlignment.middle,
    this.ayahNumberBaseline = TextBaseline.alphabetic,
    this.ayahStyle,
    this.isDark = false,
    this.isTajweed = false,
  });

  /// Pre-parsed verses (or verse fragments) that make up this line.
  final List<ParsedAyahData> parsedAyahs;

  /// Lookup index for word-level highlights.
  final WordHighlightIndex wordHighlightIndex;

  /// Lookup index for verse-level highlights.
  final BookmarkIndex bookmarkIndex;

  /// How verse highlights are painted (opacity, radius, decoration, wrapper).
  final AyahHighlightStyle ayahHighlightStyle;

  /// How word highlights are painted (opacity, extra text style, decoration).
  final WordHighlightStyle wordHighlightStyle;

  /// How the line is fitted inside its box.
  final BoxFit boxFit;

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

  /// Whether the line is rendered on a dark background.
  final bool isDark;

  /// Whether Tajweed rendering is enabled.
  final bool isTajweed;

  @override
  State<QuranLine> createState() => _QuranLineState();
}

class _QuranLineState extends State<QuranLine> {
  late List<List<TapGestureRecognizer?>> _recognizers;
  late TextStyle _mainTextStyle;
  late TextStyle _numberTextStyle;

  @override
  void initState() {
    super.initState();
    _buildRecognizers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildStyles();
  }

  @override
  void didUpdateWidget(covariant QuranLine oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.parsedAyahs != widget.parsedAyahs ||
        oldWidget.onWordTap != widget.onWordTap ||
        (oldWidget.onAyahNumberTap == null) !=
            (widget.onAyahNumberTap == null) ||
        (oldWidget.ayahNumberBuilder == null) !=
            (widget.ayahNumberBuilder == null)) {
      _disposeRecognizers();
      _buildRecognizers();
    }
    if (oldWidget.isDark != widget.isDark ||
        oldWidget.ayahStyle != widget.ayahStyle ||
        oldWidget.isTajweed != widget.isTajweed) {
      _buildStyles();
    }
  }

  /// Creates one tap recognizer per word / ayah-number glyph.
  void _buildRecognizers() {
    _recognizers = widget.parsedAyahs.map((ayahData) {
      final surah = ayahData.surahNumber;
      final ayah = ayahData.ayahNumber;

      return ayahData.words.map<TapGestureRecognizer?>((wordData) {
        if (wordData.isGlyph) {
          if (widget.onAyahNumberTap == null ||
              widget.ayahNumberBuilder != null) {
            return null;
          }
          return TapGestureRecognizer()
            ..onTap = () => widget.onAyahNumberTap?.call(surah, ayah);
        }

        if (widget.onWordTap == null || wordData.wordIndex == null) return null;

        final wordIndex = wordData.wordIndex!;
        final textWord = wordData.text;

        return TapGestureRecognizer()
          ..onTap =
              () => widget.onWordTap?.call(surah, ayah, wordIndex, textWord);
      }).toList();
    }).toList();
  }

  void _disposeRecognizers() {
    for (final ayahRecognizers in _recognizers) {
      for (final r in ayahRecognizers) {
        r?.dispose();
      }
    }
  }

  /// Resolves the main text style and the ayah-number style.
  void _buildStyles() {
    final textColor = widget.isDark
        ? Colors.white
        : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black);

    // Tajweed mode uses the uthmanic_hafs font; normal mode uses hafs (QCF).
    final defaultStyle = widget.ayahStyle ??
        (widget.isTajweed
            ? QuranTextStyles.tajweedHafsStyle(
                color: textColor,
                fontSize: 23.55,
              )
            : QuranTextStyles.hafsStyle(
                color: textColor,
                fontSize: 23.55,
              ));

    _mainTextStyle = defaultStyle.copyWith(height: null);

    // The ayah-number glyph always uses the QCF hafs font to keep its ornament.
    final glyphBaseStyle = QuranTextStyles.hafsStyle(
      fontSize: defaultStyle.fontSize ?? 23.55,
    );
    _numberTextStyle = glyphBaseStyle.copyWith(
      height: null,
      color: widget.isDark ? Colors.white : Theme.of(context).primaryColor,
    );
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parsedAyahs.isEmpty) return const SizedBox.shrink();

    final textWidget = RichText(
      text: TextSpan(
        style: _mainTextStyle,
        children: List.generate(widget.parsedAyahs.length, (ayahIdx) {
          final ayahData = widget.parsedAyahs[ayahIdx];
          final ayahRecognizers = _recognizers[ayahIdx];

          // Verse-level highlight color (null when the verse isn't highlighted).
          final Color? verseHighlightColor = widget.bookmarkIndex
              .lookup(ayahData.surahNumber, ayahData.ayahNumber)
              ?.color;

          final wordSpans = <InlineSpan>[];

          if (widget.isTajweed) {
            // Separate regular words from the ayah-end glyph so Tajweed rules
            // are analysed on the connected verse text only.
            final regularWordsTexts = <String>[];
            final regularRecognizers = <TapGestureRecognizer?>[];

            for (int wIdx = 0; wIdx < ayahData.words.length; wIdx++) {
              final wordData = ayahData.words[wIdx];
              if (!wordData.isGlyph) {
                regularWordsTexts.add(wordData.text);
                regularRecognizers.add(ayahRecognizers[wIdx]);
              }
            }

            final annotatedWordSpansList =
                TajweedSpanBuilder.buildAyahWordsWithContext(
              words: regularWordsTexts,
              baseStyle: _mainTextStyle,
              isDarkMode: widget.isDark,
              recognizers: regularRecognizers,
            );

            int regularCounter = 0;
            for (int wIdx = 0; wIdx < ayahData.words.length; wIdx++) {
              final wordData = ayahData.words[wIdx];
              if (wordData.isGlyph) {
                _appendGlyphSpan(
                    wordSpans, ayahData, wordData, ayahRecognizers[wIdx]);
              } else {
                final spans = annotatedWordSpansList[regularCounter];
                final WordHighlight? h = wordData.wordIndex == null
                    ? null
                    : widget.wordHighlightIndex.lookup(
                        ayahData.surahNumber,
                        ayahData.ayahNumber,
                        wordData.wordIndex!,
                      );

                final VoidCallback? onTapCallback =
                    (widget.onWordTap != null && wordData.wordIndex != null)
                        ? () => widget.onWordTap?.call(
                              ayahData.surahNumber,
                              ayahData.ayahNumber,
                              wordData.wordIndex!,
                              wordData.text,
                            )
                        : null;

                wordSpans.addAll(
                  widget.wordHighlightStyle.applyToWordSpans(
                    wordSpans: spans,
                    highlight: h,
                    onTap: onTapCallback,
                  ),
                );
                // Add the inter-word space outside the highlighted word span.
                wordSpans.add(TextSpan(text: ' ', style: _mainTextStyle));

                regularCounter++;
              }
            }
          } else {
            // Normal mode (smart QCF glyphs).
            for (int wIdx = 0; wIdx < ayahData.words.length; wIdx++) {
              final wordData = ayahData.words[wIdx];

              if (wordData.isGlyph) {
                _appendGlyphSpan(
                    wordSpans, ayahData, wordData, ayahRecognizers[wIdx]);
              } else {
                final WordHighlight? h = wordData.wordIndex == null
                    ? null
                    : widget.wordHighlightIndex.lookup(
                        ayahData.surahNumber,
                        ayahData.ayahNumber,
                        wordData.wordIndex!,
                      );

                final VoidCallback? onTapCallback =
                    (widget.onWordTap != null && wordData.wordIndex != null)
                        ? () => widget.onWordTap?.call(
                              ayahData.surahNumber,
                              ayahData.ayahNumber,
                              wordData.wordIndex!,
                              wordData.text,
                            )
                        : null;

                final baseWordSpan = TextSpan(
                  text: wordData.text,
                  style: _mainTextStyle,
                  recognizer: ayahRecognizers[wIdx],
                );

                wordSpans.addAll(
                  widget.wordHighlightStyle.applyToWordSpans(
                    wordSpans: [baseWordSpan],
                    highlight: h,
                    onTap: onTapCallback,
                  ),
                );

                // Add the inter-word space outside the highlighted word span.
                wordSpans.add(TextSpan(text: ' ', style: _mainTextStyle));
              }
            }
          }

          return WidgetSpan(
            child: GestureDetector(
              onLongPressStart: (details) => widget.onLongPress
                  ?.call(ayahData.surahNumber, ayahData.ayahNumber, details),
              child: widget.ayahHighlightStyle.apply(
                context,
                Text.rich(
                  TextSpan(children: wordSpans),
                  textDirection: TextDirection.rtl,
                ),
                verseHighlightColor,
              ),
            ),
          );
        }),
      ),
    );

    return FittedBox(fit: widget.boxFit, child: textWidget);
  }

  /// Appends the ayah-number marker (custom widget or QCF glyph) to [wordSpans].
  void _appendGlyphSpan(
    List<InlineSpan> wordSpans,
    ParsedAyahData ayahData,
    ParsedWordData wordData,
    TapGestureRecognizer? recognizer,
  ) {
    if (widget.ayahNumberBuilder != null) {
      final surah = ayahData.surahNumber;
      final ayah = ayahData.ayahNumber;

      Widget numberWidget = widget.ayahNumberBuilder!(
        context,
        surah,
        ayah,
        wordData.text,
        widget.isDark,
      );

      if (widget.onAyahNumberTap != null) {
        numberWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onAyahNumberTap?.call(surah, ayah),
          child: numberWidget,
        );
      }

      wordSpans.add(WidgetSpan(
        alignment: widget.ayahNumberAlignment,
        baseline: widget.ayahNumberBaseline,
        child: numberWidget,
      ));
    } else {
      wordSpans.add(TextSpan(
        text: wordData.text,
        style: _numberTextStyle,
        recognizer: recognizer,
      ));
    }
  }
}