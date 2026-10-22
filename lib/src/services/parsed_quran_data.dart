import 'package:qcf_quran_lite/qcf_quran_lite.dart';

/// Represents a single parsed token (either a regular word or an ayah-number glyph).
class ParsedWordData {
  /// The rendered text or QCF glyph string.
  final String text;

  /// Zero-based index of the word within its parent verse (`null` when [isGlyph] is `true`).
  final int? wordIndex;

  /// Whether this token represents the trailing ayah-number ornament glyph.
  final bool isGlyph;

  const ParsedWordData({
    required this.text,
    this.wordIndex,
    this.isGlyph = false,
  });
}

/// Represents a parsed verse (or a verse fragment on a single Mus'haf line).
class ParsedAyahData {
  /// The Surah number (`1..114`).
  final int surahNumber;

  /// The verse number within [surahNumber].
  final int ayahNumber;

  /// Ordered list of words (and optional trailing glyph) belonging to this verse segment.
  final List<ParsedWordData> words;

  const ParsedAyahData({
    required this.surahNumber,
    required this.ayahNumber,
    required this.words,
  });
}

/// Parses a single [Line] of a Quranic page into structured verse data.
///
/// When [isTajweed] is `true`, uses standard Uthmanic text (`ayah.ayah`) instead
/// of smart QCF glyphs (`ayah.othmanicAyah`), while preserving the QCF glyph
/// for the ayah-number marker.
List<ParsedAyahData> parseLine(
  Line line,
  Map<String, int>? startingWordIndices, {
  bool isTajweed = false,
}) {
  final result = <ParsedAyahData>[];

  // Iterate in reverse because each ayah fragment is placed inside a WidgetSpan
  // in a RichText line.
  for (final ayah in line.ayahs.toList().reversed) {
    final rawOthmanic = ayah.othmanicAyah.replaceAll('\n', ' ').trim();
    final rawStandard = ayah.ayah
        .replaceAll('\n', ' ')
        .replaceAll('\u00a0', ' ')
        .trim();

    final sourceText = isTajweed ? rawStandard : rawOthmanic;
    if (sourceText.isEmpty) continue;

    final chunks = sourceText
        .split(RegExp(r'\s+'))
        .where((c) => c.isNotEmpty)
        .toList();
    if (chunks.isEmpty) continue;

    // Detect whether this line fragment ends with the ayah-number marker.
    final String qcfGlyph = getayaNoQCF(ayah.surahNumber, ayah.ayahNumber);
    final bool hasGlyph = isTajweed
        ? RegExp(r'^[\u0660-\u0669\u06F0-\u06F90-9\u06DD]+$')
            .hasMatch(chunks.last)
        : (chunks.last == qcfGlyph || rawOthmanic.endsWith(qcfGlyph));

    final ayahKey = '${ayah.surahNumber}-${ayah.ayahNumber}';
    int currentWordIndex = startingWordIndices?[ayahKey] ?? 0;

    final wordsData = <ParsedWordData>[];
    final int wordChunksCount = hasGlyph ? chunks.length - 1 : chunks.length;

    for (int i = 0; i < wordChunksCount; i++) {
      wordsData.add(ParsedWordData(
        text: chunks[i],
        wordIndex: currentWordIndex,
        isGlyph: false,
      ));
      currentWordIndex++;
    }

    if (hasGlyph) {
      wordsData.add(ParsedWordData(
        // Always pass the QCF ornament glyph for the ayah number in Tajweed mode,
        // or the original last chunk in normal QCF mode.
        text: isTajweed ? qcfGlyph : chunks.last,
        wordIndex: null,
        isGlyph: true,
      ));
    }

    result.add(ParsedAyahData(
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      words: wordsData,
    ));

    if (startingWordIndices != null) {
      startingWordIndices[ayahKey] = currentWordIndex;
    }
  }
  return result;
}

/// Parses a full verse entry from `activeQuran` (used by [QuranSurahListView])
/// using the exact same word-indexing rules as [parseLine].
ParsedAyahData parseAyahFromMap(
  Map<dynamic, dynamic> ayahMap, {
  bool isTajweed = false,
}) {
  final int surahNumber = ayahMap['sora'] as int;
  final int verseNumber = ayahMap['aya_no'] as int;

  final String rawOthmanic =
      ayahMap['aya_text_othmanic'].toString().replaceAll('\n', ' ').trim();
  final List<String> othmanicChunks =
      rawOthmanic.split(RegExp(r'\s+')).where((c) => c.isNotEmpty).toList();

  if (othmanicChunks.isEmpty) {
    return ParsedAyahData(
      surahNumber: surahNumber,
      ayahNumber: verseNumber,
      words: const [],
    );
  }

  final String glyph = othmanicChunks.last;

  List<String> wordChunks;
  if (isTajweed) {
    final String rawStandard = ayahMap['aya_text']
        .toString()
        .replaceAll('\n', ' ')
        .replaceAll('\u00a0', ' ')
        .trim();
    final List<String> stdChunks =
        rawStandard.split(RegExp(r'\s+')).where((c) => c.isNotEmpty).toList();

    if (stdChunks.isEmpty) {
      wordChunks = const [];
    } else {
      final bool endsWithNumber =
          RegExp(r'^[\u0660-\u0669\u06F0-\u06F90-9\u06DD]+$')
              .hasMatch(stdChunks.last);
      wordChunks = endsWithNumber
          ? stdChunks.sublist(0, stdChunks.length - 1)
          : stdChunks;
    }
  } else {
    wordChunks = othmanicChunks.sublist(0, othmanicChunks.length - 1);
  }

  final wordsData = <ParsedWordData>[
    for (int i = 0; i < wordChunks.length; i++)
      ParsedWordData(
        text: wordChunks[i],
        wordIndex: i,
        isGlyph: false,
      ),
    ParsedWordData(
      text: glyph,
      wordIndex: null,
      isGlyph: true,
    ),
  ];

  return ParsedAyahData(
    surahNumber: surahNumber,
    ayahNumber: verseNumber,
    words: wordsData,
  );
}

/// Caches parsed lines to avoid re-splitting strings during rebuilds while
/// keeping running word indices across multi-line verses accurate.
class ParsedLineCache {
  ParsedLineCache._();

  /// Singleton instance of [ParsedLineCache].
  static final ParsedLineCache instance = ParsedLineCache._();

  final Map<String, List<ParsedAyahData>> _cache = {};

  /// Retrieves the parsed line from cache or parses and stores it.
  ///
  /// Always advances [startingWordIndices] even on a cache hit so subsequent
  /// lines on the same page receive the correct continuation word indices.
  List<ParsedAyahData> getOrParse(
    int pageIndex,
    int lineIndex,
    Line line,
    Map<String, int>? startingWordIndices, {
    bool isTajweed = false,
  }) {
    final indicesHash = startingWordIndices?.entries
            .map((e) => '${e.key}=${e.value}')
            .join(',') ??
        'null';

    final key = '$pageIndex:$lineIndex:$indicesHash:$isTajweed';

    final cached = _cache[key];
    if (cached != null) {
      // Advance running word counts on cache hit so multi-line verses stay in sync.
      if (startingWordIndices != null) {
        for (final ayahData in cached) {
          final ayahKey = '${ayahData.surahNumber}-${ayahData.ayahNumber}';
          for (final w in ayahData.words) {
            if (!w.isGlyph && w.wordIndex != null) {
              startingWordIndices[ayahKey] = w.wordIndex! + 1;
            }
          }
        }
      }
      return cached;
    }

    final parsed = parseLine(line, startingWordIndices, isTajweed: isTajweed);
    _cache[key] = parsed;
    return parsed;
  }

  /// Clears all cached line data.
  void clear() => _cache.clear();
}