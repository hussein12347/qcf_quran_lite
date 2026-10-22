import 'package:flutter/material.dart';

/// Describes a highlight applied to a single word within a Quranic verse.
///
/// A word is identified by the tuple ([surah], [verseNumber], [wordIndex]),
/// where [wordIndex] is the zero-based index of the word within its verse
/// (matching the indices produced by the Quran line parsers).
///
/// Either [textColor] or [backgroundColor] may be `null` to leave that
/// aspect unstyled. Both may be provided to combine a foreground color with
/// a background tint.
class WordHighlight {
  /// The Surah number the word belongs to (`1..114`).
  final int surah;

  /// The verse number within [surah] that contains the word.
  final int verseNumber;

  /// Zero-based index of the word within its verse.
  final int wordIndex;

  /// Optional foreground color applied to the word's text.
  final Color? textColor;

  /// Optional background color applied behind the word.
  final Color? backgroundColor;

  const WordHighlight({
    required this.surah,
    required this.verseNumber,
    required this.wordIndex,
    this.textColor,
    this.backgroundColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordHighlight &&
          runtimeType == other.runtimeType &&
          surah == other.surah &&
          verseNumber == other.verseNumber &&
          wordIndex == other.wordIndex &&
          textColor == other.textColor &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(
        surah,
        verseNumber,
        wordIndex,
        textColor,
        backgroundColor,
      );
}