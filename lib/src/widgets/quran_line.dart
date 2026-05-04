import 'package:flutter/material.dart';

import '../../qcf_quran_lite.dart';

/// An internal widget responsible for precisely rendering a single line of Quranic text.
class QuranLine extends StatelessWidget {
  const QuranLine(
      this.line,
      this.bookmarks, {
        super.key,
        this.boxFit = BoxFit.fill,
        this.ayahStyle,
        this.highlightPadding,
        this.highlightBorderRadius,
        this.customHighlightDecoration,
        // Gestures
        this.onTap,
        this.onTapDown,
        this.onTapUp,
        this.onTapCancel,
        this.onDoubleTap,
        this.onDoubleTapDown,
        this.onDoubleTapCancel,
        this.onLongPress,
        this.onLongPressStart,
        this.onLongPressMoveUpdate,
        this.onLongPressUp,
        this.onLongPressEnd,
        this.onLongPressCancel,
      });

  final Line line;
  final List<HighlightVerse> bookmarks;
  final BoxFit boxFit;
  final TextStyle? ayahStyle;
  final EdgeInsetsGeometry? highlightPadding;
  final BorderRadiusGeometry? highlightBorderRadius;

  /// A custom builder to fully control the background decoration of the highlighted verse.
  /// If provided, this completely overrides the default BoxDecoration and [highlightBorderRadius].
  final Decoration Function(Color highlightColor)? customHighlightDecoration;

  // Gesture Callbacks
  final void Function(int, int)? onTap;
  final void Function(int, int, TapDownDetails)? onTapDown;
  final void Function(int, int, TapUpDetails)? onTapUp;
  final void Function(int, int)? onTapCancel;

  final void Function(int, int)? onDoubleTap;
  final void Function(int, int, TapDownDetails)? onDoubleTapDown;
  final void Function(int, int)? onDoubleTapCancel;

  final void Function(int, int)? onLongPress;
  final void Function(int, int, LongPressStartDetails)? onLongPressStart;
  final void Function(int, int, LongPressMoveUpdateDetails)? onLongPressMoveUpdate;
  final void Function(int, int)? onLongPressUp;
  final void Function(int, int, LongPressEndDetails)? onLongPressEnd;
  final void Function(int, int)? onLongPressCancel;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = QuranTextStyles.hafsStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      fontSize: 23.55,
    );

    final finalStyle = ayahStyle != null ? defaultStyle.merge(ayahStyle) : defaultStyle;

    return FittedBox(
      fit: boxFit,
      child: RichText(
        text: TextSpan(
          children: line.ayahs.reversed.map((ayah) {
            final highlight = bookmarks.firstWhere(
                  (h) => h.surah == ayah.surahNumber && h.verseNumber == ayah.ayahNumber,
              orElse: () => HighlightVerse(
                surah: 0,
                verseNumber: 0,
                page: 0,
                color: Colors.transparent,
              ),
            );

            bool isHighlighted = highlight.color != Colors.transparent;

            return WidgetSpan(
              child: GestureDetector(
                // ====== Taps ======
                onTap: () => onTap?.call(ayah.surahNumber, ayah.ayahNumber),
                onTapDown: (details) => onTapDown?.call(ayah.surahNumber, ayah.ayahNumber, details),
                onTapUp: (details) => onTapUp?.call(ayah.surahNumber, ayah.ayahNumber, details),
                onTapCancel: () => onTapCancel?.call(ayah.surahNumber, ayah.ayahNumber),

                // ====== Double Taps ======
                onDoubleTap: () => onDoubleTap?.call(ayah.surahNumber, ayah.ayahNumber),
                onDoubleTapDown: (details) => onDoubleTapDown?.call(ayah.surahNumber, ayah.ayahNumber, details),
                onDoubleTapCancel: () => onDoubleTapCancel?.call(ayah.surahNumber, ayah.ayahNumber),

                // ====== Long Presses ======
                onLongPress: () => onLongPress?.call(ayah.surahNumber, ayah.ayahNumber),
                onLongPressStart: (details) => onLongPressStart?.call(ayah.surahNumber, ayah.ayahNumber, details),
                onLongPressMoveUpdate: (details) => onLongPressMoveUpdate?.call(ayah.surahNumber, ayah.ayahNumber, details),
                onLongPressUp: () => onLongPressUp?.call(ayah.surahNumber, ayah.ayahNumber),
                onLongPressEnd: (details) => onLongPressEnd?.call(ayah.surahNumber, ayah.ayahNumber, details),
                onLongPressCancel: () => onLongPressCancel?.call(ayah.surahNumber, ayah.ayahNumber),

                // ====== UI Content ======
                child: Container(
                  padding: isHighlighted
                      ? (highlightPadding ?? const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0))
                      : EdgeInsets.zero,
                  decoration: isHighlighted
                      ? (customHighlightDecoration != null
                      ? customHighlightDecoration!(highlight.color)
                      : BoxDecoration(
                    borderRadius: highlightBorderRadius ?? BorderRadius.circular(4.0),
                    color: highlight.color.withValues(alpha: 0.4)
                  ))
                      : null,
                  child: Text(
                    "${ayah.othmanicAyah}\u2009",
                    style: finalStyle.copyWith(height: null),
                  ),
                ),
              ),
            );
          }).toList(),
          style: finalStyle,
        ),
      ),
    );
  }
}