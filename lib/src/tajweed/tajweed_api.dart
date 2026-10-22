import '../../qcf_quran_lite.dart' show getVerse;
import 'tajweed_annotator.dart';
import 'tajweed_rule.dart';

/// Tajweed rules per word and per ayah, each one with the letter that carries it.
///
/// Exported from `qcf_quran_lite.dart`, so users get these functions with the
/// usual single import:
/// ```dart
/// import 'package:qcf_quran_lite/qcf_quran_lite.dart';
/// ```

/// One tajweed rule together with the letter it falls on.
///
/// A word with two rules gives two of these; a rule that falls on two letters
/// (for example two heavy letters in a row) gives one per letter.
class TajweedLetterRule {
  const TajweedLetterRule({
    required this.rule,
    required this.letter,
    required this.baseLetter,
    required this.wordIndex,
    required this.letterIndex,
    required this.start,
    required this.end,
  });

  /// The rule (name, colour, definition, source...).
  final TajweedRule rule;

  /// The letter **with its marks** (harakat, shadda, sukun, tanween...), exactly
  /// as written in the text. Example: `نْ`, `مّ`, `ـَٔ`.
  final String letter;

  /// The bare letter without any mark. Example: `ن`, `م`.
  final String baseLetter;

  /// Zero-based index of the word in its ayah — the same index `onWordTap`
  /// reports.
  final int wordIndex;

  /// Zero-based position of the letter inside its word, counting letters
  /// only — marks (harakat, shadda...) are not counted.
  ///
  /// Example in «بِسْمِ»: ب → 0, س → 1, م → 2.
  final int letterIndex;

  /// Where [letter] starts inside the word, in UTF-16 code units. Use it with
  /// [end] to cut the letter out of the word text: `word.substring(start, end)`.
  final int start;

  /// Where [letter] ends inside the word (exclusive), in UTF-16 code units.
  final int end;

  @override
  bool operator ==(Object other) =>
      other is TajweedLetterRule &&
      other.rule == rule &&
      other.wordIndex == wordIndex &&
      other.letterIndex == letterIndex &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(rule, wordIndex, letterIndex, start, end);

  @override
  String toString() =>
      'TajweedLetterRule(word $wordIndex, letter $letterIndex "$letter" → ${rule.name})';
}

/// Same marks the annotator treats as part of a letter's cluster.
bool _isMarkUnit(int c) =>
    (c >= 0x064B && c <= 0x065F) ||
    c == 0x0670 ||
    (c >= 0x06D6 && c <= 0x06ED) ||
    c == 0x0640;

/// Splits the text of an ayah into the same words the readers use.
///
/// This mirrors the parsing done by `QuranSurahListView` and `QuranPageView`
/// in Tajweed mode, so index `i` here is the same `wordIndex` that
/// `onWordTap` reports: the text comes from `aya_text` and the trailing
/// ayah number, if any, is dropped.
List<String> _splitAyahWordsForTajweed(String rawVerse) {
  final chunks = rawVerse
      .replaceAll('\n', ' ')
      .replaceAll('\u00a0', ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((c) => c.isNotEmpty)
      .toList();

  if (chunks.isNotEmpty &&
      RegExp(r'^[\u0660-\u0669\u06F0-\u06F90-9\u06DD]+$')
          .hasMatch(chunks.last)) {
    chunks.removeLast();
  }
  return chunks;
}

/// Returns the Tajweed rules of **every word** in the verse identified by
/// [surahNumber] and [ayaNo], each with the letter it falls on.
///
/// The result has one entry per word, in reading order: entry `i` holds the
/// rules found in the word whose `wordIndex` is `i` (zero-based, the same
/// index passed to `onWordTap`). A word with no rule gets an empty list.
///
/// Inside a word the entries come in reading order, one per letter. Use
/// [TajweedLetterRule.letter] for the letter, [TajweedLetterRule.letterIndex]
/// for its position in the word, and [TajweedLetterRule.rule] for the ruling
/// (`label`, `englishName`, `definition`, `amount`, `color`, ...).
///
/// The whole ayah is analysed at once, because many rulings depend on the
/// next word (idgham, ikhfa, iqlab, madd munfasil) and the end of the ayah is
/// a stop (madd arid, qalqalah at the stop).
///
/// - [includeNaturalMadd]: also report the natural madd. Off by default
///   because it is by far the most frequent rule.
/// - [includeTafkhim]: also report tafkhim / tarqiq of the ra, the isti'la
///   letters and the lam of the divine name. On by default, like the colours
///   shown on the page; pass `false` to keep only the other rules.
///
/// Throws a [String] error if the verse does not exist.
///
/// Example:
/// ```dart
/// final words = getAyahTajweedRules(1, 2);
/// for (final word in words) {
///   for (final r in word) {
///     print('${r.letterIndex}: ${r.letter}  →  ${r.rule.label}');
///   }
/// }
/// ```
List<List<TajweedLetterRule>> getAyahTajweedRules(
  int surahNumber,
  int ayaNo, {
  bool includeNaturalMadd = false,
  bool includeTafkhim = true,
}) {
  final words = _splitAyahWordsForTajweed(getVerse(surahNumber, ayaNo));
  if (words.isEmpty) return const [];

  // Words are joined by a single space; spans come back in UTF-16 offsets of
  // this exact string.
  final text = words.join(' ');
  final spans = TajweedAnnotator.annotate(
    text,
    includeNaturalMadd: includeNaturalMadd,
  );

  final result = List<List<TajweedLetterRule>>.generate(
    words.length,
    (_) => <TajweedLetterRule>[],
  );

  var offset = 0;
  for (var w = 0; w < words.length; w++) {
    final wordStart = offset;
    final wordEnd = wordStart + words[w].length;

    // Spans are sorted and never overlap.
    for (final span in spans) {
      if (span.end <= wordStart) continue;
      if (span.start >= wordEnd) break;
      if (!includeTafkhim && span.rule.family == TajweedFamily.tafkhim) {
        continue;
      }

      // A span can cover several neighbouring letters of the same rule:
      // split it so that every entry is one letter with its marks.
      final from = span.start < wordStart ? wordStart : span.start;
      final to = span.end > wordEnd ? wordEnd : span.end;

      var i = from;
      while (i < to) {
        var j = i + 1;
        while (j < to && _isMarkUnit(text.codeUnitAt(j))) {
          j++;
        }

        final letter = text.substring(i, j);

        // Position among the letters of the word (marks are not counted).
        var lettersBefore = 0;
        for (var k = wordStart; k < i; k++) {
          if (!_isMarkUnit(text.codeUnitAt(k))) lettersBefore++;
        }
        // A span that starts on a stray mark belongs to the letter before it.
        final letterIndex = _isMarkUnit(text.codeUnitAt(i))
            ? (lettersBefore > 0 ? lettersBefore - 1 : 0)
            : lettersBefore;

        var base = '';
        for (var k = 0; k < letter.length; k++) {
          if (!_isMarkUnit(letter.codeUnitAt(k))) {
            base = letter[k];
            break;
          }
        }

        result[w].add(TajweedLetterRule(
          rule: span.rule,
          letter: letter,
          baseLetter: base,
          wordIndex: w,
          letterIndex: letterIndex,
          start: i - wordStart,
          end: j - wordStart,
        ));
        i = j;
      }
    }

    offset = wordEnd + 1; // the space between two words
  }

  return result;
}

/// Returns the Tajweed rules of a **single word**, each with the letter it
/// falls on: the word at [wordIndex] (zero-based) of the verse identified by
/// [surahNumber] and [ayaNo].
///
/// It takes the position rather than the bare text because the ruling of a
/// word depends on its neighbours and on whether it ends the ayah. Call it
/// straight from `onWordTap`, which already gives you the same three values:
///
/// ```dart
/// onWordTap: (surah, verse, wordIndex, word) {
///   for (final r in getWordTajweedRules(surah, verse, wordIndex)) {
///     print('${r.letterIndex}: ${r.letter}  →  ${r.rule.label}');
///   }
/// },
/// ```
///
/// See [getAyahTajweedRules] for the meaning of [includeNaturalMadd] and
/// [includeTafkhim]. Calling it for many words of the same ayah is wasteful;
/// use [getAyahTajweedRules] once instead.
///
/// Throws a [String] error if the verse does not exist or [wordIndex] is out
/// of range.
List<TajweedLetterRule> getWordTajweedRules(
  int surahNumber,
  int ayaNo,
  int wordIndex, {
  bool includeNaturalMadd = false,
  bool includeTafkhim = true,
}) {
  final all = getAyahTajweedRules(
    surahNumber,
    ayaNo,
    includeNaturalMadd: includeNaturalMadd,
    includeTafkhim: includeTafkhim,
  );
  if (wordIndex < 0 || wordIndex >= all.length) {
    throw "Invalid word index. This verse has ${all.length} words "
        "(0 to ${all.length - 1}).";
  }
  return all[wordIndex];
}