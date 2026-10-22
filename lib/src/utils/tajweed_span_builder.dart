import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../tajweed/mushaf_colors.dart';
import '../tajweed/tajweed_annotator.dart';
import '../tajweed/tajweed_rule.dart';

class TajweedSpanBuilder {
  static const int _supAlef = 0x0670; // الألف الخنجرية (ـٰ)

  static bool _isMark(int c) =>
      (c >= 0x064B && c <= 0x065F) ||
      c == _supAlef ||
      (c >= 0x06D6 && c <= 0x06ED) ||
      c == 0x0640;

  /// يعالج حدود الـ Spans لضمان عدم شطر أي رمز مركب (Ligature / Stacked Glyph)
  /// في خط الرسم العثماني، مما يمنع قص الحروف أو اختفاء أجزاء منها تحت الـ ClipRect.
  static List<TajweedSpan> _preventGlyphClipping(
    String text,
    List<TajweedSpan> spans,
  ) {
    if (spans.isEmpty) return spans;
    final List<TajweedSpan> result = [];

    for (int idx = 0; idx < spans.length; idx++) {
      final span = spans[idx];
      int start = span.start;
      int end = span.end;

      // 1) التأكد من أن بداية الـ Span لا تبدأ في منتصف تشكيل أو ألف خنجرية
      // مفصولة عن الحرف الأساسي الذي يحملها
      while (start > 0 && _isMark(text.codeUnitAt(start))) {
        start--;
      }

      // 2) إذا كان الـ Span يبدأ بحرف يشكّل Ligature إجباري مع الحرف الذي قبله
      // (مثل أي لام متبوعة بألف في خط المصحف: لا، لآ، لأ، لإ، لى)
      // فإن شطرهما إلى 2 TextSpans يؤدي حتماً إلى قص جسم اللام في Flutter.
      if (start > 0) {
        final String firstChar = text[start];
        if (firstChar == 'ا' ||
            firstChar == 'ى' ||
            firstChar == 'أ' ||
            firstChar == 'إ' ||
            firstChar == 'آ') {
          int prevLetter = start - 1;
          while (prevLetter >= 0 && _isMark(text.codeUnitAt(prevLetter))) {
            prevLetter--;
          }
          if (prevLetter >= 0 && text[prevLetter] == 'ل') {
            start = prevLetter;
          }
        }
      }

      // 3) التأكد من أن نهاية الـ Span تضم كل التشكيلات التابعة لآخر حرف فيه
      while (end < text.length && _isMark(text.codeUnitAt(end))) {
        end++;
      }

      // 4) منع التداخل مع الـ Span السابق في القائمة بعد توسيع البداية
      if (result.isNotEmpty && start < result.last.end) {
        if (result.last.rule == span.rule) {
          // دمجهما إذا كانا بنفس الحكم
          final prev = result.removeLast();
          start = prev.start;
        } else {
          // تقليص الـ Span السابق لصالح الـ Ligature الحالي حتى لا يتداخلا
          final prev = result.removeLast();
          if (prev.start < start) {
            result.add(TajweedSpan(prev.start, start, prev.rule));
          }
        }
      }

      if (start < end) {
        result.add(TajweedSpan(start, end, span.rule));
      }
    }

    return result;
  }

  /// Builds a list of [TextSpan]s for a single word with Tajweed colors applied,
  /// preserving tap interaction and word background/foreground highlights.
  static List<TextSpan> buildWordSpans({
    required String wordWithTrailingSpace,
    required TextStyle baseStyle,
    required bool isDarkMode,
    TapGestureRecognizer? recognizer,
    Color? highlightTextColor,
    Color? highlightBackgroundColor,
  }) {
    TextStyle effectiveBase = baseStyle;
    if (highlightBackgroundColor != null) {
      effectiveBase =
          effectiveBase.copyWith(backgroundColor: highlightBackgroundColor);
    }
    if (highlightTextColor != null) {
      return [
        TextSpan(
          text: wordWithTrailingSpace,
          style: effectiveBase.copyWith(color: highlightTextColor),
          recognizer: recognizer,
        ),
      ];
    }

    final spans = _preventGlyphClipping(
      wordWithTrailingSpace,
      TajweedAnnotator.annotate(wordWithTrailingSpace),
    );

    if (spans.isEmpty) {
      return [
        TextSpan(
          text: wordWithTrailingSpace,
          style: effectiveBase,
          recognizer: recognizer,
        ),
      ];
    }

    final MushafColors palette =
        isDarkMode ? MushafColors.dark : MushafColors.light;

    final List<TextSpan> result = [];
    int cursor = 0;

    for (final span in spans) {
      if (span.start > cursor) {
        result.add(
          TextSpan(
            text: wordWithTrailingSpace.substring(cursor, span.start),
            style: effectiveBase,
            recognizer: recognizer,
          ),
        );
      }

      final Color ruleColor = palette.tajweedColor(span.rule);
      result.add(
        TextSpan(
          text: wordWithTrailingSpace.substring(span.start, span.end),
          style: effectiveBase.copyWith(color: ruleColor),
          recognizer: recognizer,
        ),
      );
      cursor = span.end;
    }

    if (cursor < wordWithTrailingSpace.length) {
      result.add(
        TextSpan(
          text: wordWithTrailingSpace.substring(cursor),
          style: effectiveBase,
          recognizer: recognizer,
        ),
      );
    }

    return result;
  }

  /// Analyzes the full verse or line text in context and maps the resulting
  /// Tajweed color annotations back onto each individual word (excluding the
  /// trailing space so word highlights do not bleed into the space between words).
  static List<List<TextSpan>> buildAyahWordsWithContext({
    required List<String> words,
    required TextStyle baseStyle,
    required bool isDarkMode,
    required List<TapGestureRecognizer?> recognizers,
    Color? Function(int wordIndex)? getHighlightTextColor,
    Color? Function(int wordIndex)? getHighlightBgColor,
  }) {
    if (words.isEmpty) return [];

    // Join words with a single space so cross-word Tajweed rules (e.g. Idgham,
    // Ikhfaa) are evaluated in full connected context.
    final String fullText = '${words.join(' ')} ';
    final List<TajweedSpan> allAnnotations = _preventGlyphClipping(
      fullText,
      TajweedAnnotator.annotate(fullText),
    );

    final MushafColors palette =
        isDarkMode ? MushafColors.dark : MushafColors.light;

    final List<List<TextSpan>> wordsSpans = [];
    int globalOffset = 0;

    for (int w = 0; w < words.length; w++) {
      final String rawWord = words[w];
      final int wordStart = globalOffset;
      final int wordEnd = wordStart + rawWord.length;
      // Advance past the word and its single trailing space.
      globalOffset = wordEnd + 1;

      final TapGestureRecognizer? recognizer =
          w < recognizers.length ? recognizers[w] : null;
      final Color? hlText = getHighlightTextColor?.call(w);
      final Color? hlBg = getHighlightBgColor?.call(w);

      TextStyle wordBaseStyle = baseStyle;
      if (hlBg != null) {
        wordBaseStyle = wordBaseStyle.copyWith(backgroundColor: hlBg);
      }

      // If an explicit highlight text color is set, it overrides Tajweed colors
      // for this word.
      if (hlText != null) {
        wordsSpans.add([
          TextSpan(
            text: rawWord,
            style: wordBaseStyle.copyWith(color: hlText),
            recognizer: recognizer,
          ),
        ]);
        continue;
      }

      final List<TextSpan> currentWordSpans = [];
      int localCursor = wordStart;

      for (final span in allAnnotations) {
        if (span.end <= wordStart) continue;
        if (span.start >= wordEnd) break;

        final int segStart = span.start < wordStart ? wordStart : span.start;
        final int segEnd = span.end > wordEnd ? wordEnd : span.end;

        if (segStart > localCursor) {
          currentWordSpans.add(
            TextSpan(
              text: fullText.substring(localCursor, segStart),
              style: wordBaseStyle,
              recognizer: recognizer,
            ),
          );
        }

        final Color ruleColor = palette.tajweedColor(span.rule);
        currentWordSpans.add(
          TextSpan(
            text: fullText.substring(segStart, segEnd),
            style: wordBaseStyle.copyWith(color: ruleColor),
            recognizer: recognizer,
          ),
        );

        localCursor = segEnd;
      }

      if (localCursor < wordEnd) {
        currentWordSpans.add(
          TextSpan(
            text: fullText.substring(localCursor, wordEnd),
            style: wordBaseStyle,
            recognizer: recognizer,
          ),
        );
      }

      wordsSpans.add(currentWordSpans);
    }

    return wordsSpans;
  }
}