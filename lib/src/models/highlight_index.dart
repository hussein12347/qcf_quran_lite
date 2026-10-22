import '../models/highlight_verse.dart';
import 'highlight_word.dart';

/// Immutable lookup index for word-level highlights.
///
/// Maps `"<surah>-<verse>-<wordIndex>"` keys to [WordHighlight] instances,
/// allowing O(1) resolution of a word highlight during rendering.
///
/// The [signature] is a cheap hash of the underlying highlight list and is
/// used by [MemoizedWordHighlightIndex] to decide whether the index must be
/// rebuilt.
class WordHighlightIndex {
  final Map<String, WordHighlight> _byWord;

  /// Cheap hash summarizing the inputs used to build this index.
  ///
  /// Two indexes built from highlight lists with identical [signature]s are
  /// considered equivalent for memoization purposes.
  final int signature;

  WordHighlightIndex._(this._byWord, this.signature);

  /// Shared empty index (no word highlights).
  static const empty = _EmptyWordHighlightIndex();

  /// Builds a new index from [highlights].
  factory WordHighlightIndex.build(List<WordHighlight> highlights) {
    final map = <String, WordHighlight>{};
    for (final h in highlights) {
      map['${h.surah}-${h.verseNumber}-${h.wordIndex}'] = h;
    }
    return WordHighlightIndex._(map, _signatureOf(highlights));
  }

  /// Returns the highlight for the word at ([surah], [verse], [wordIndex]),
  /// or `null` when no highlight exists for that word.
  WordHighlight? lookup(int surah, int verse, int wordIndex) =>
      _byWord['$surah-$verse-$wordIndex'];

  /// Computes a stable hash of [list] for change detection.
  static int _signatureOf(List<WordHighlight> list) {
    int hash = list.length;
    for (final h in list) {
      hash = 0x1fffffff &
          (hash +
              Object.hash(h.surah, h.verseNumber, h.wordIndex, h.textColor,
                  h.backgroundColor));
    }
    return hash;
  }
}

/// Const-friendly empty implementation of [WordHighlightIndex].
class _EmptyWordHighlightIndex implements WordHighlightIndex {
  const _EmptyWordHighlightIndex();

  @override
  Map<String, WordHighlight> get _byWord => const {};

  @override
  int get signature => 0;

  @override
  WordHighlight? lookup(int surah, int verse, int wordIndex) => null;
}

/// Immutable lookup index for verse-level (bookmark) highlights.
///
/// Maps `"<surah>-<verse>"` keys to [HighlightVerse] instances, allowing O(1)
/// checks of whether a verse is highlighted and retrieval of its decoration.
///
/// The [signature] is a cheap hash of the underlying bookmark list and is
/// used by [MemoizedBookmarkIndex] to decide whether the index must be
/// rebuilt.
class BookmarkIndex {
  final Map<String, HighlightVerse> _byAyah;

  /// Cheap hash summarizing the inputs used to build this index.
  ///
  /// Two indexes built from bookmark lists with identical [signature]s are
  /// considered equivalent for memoization purposes.
  final int signature;

  BookmarkIndex._(this._byAyah, this.signature);

  /// Shared empty index (no bookmarks).
  static const empty = _EmptyBookmarkIndex();

  /// Builds a new index from [bookmarks].
  factory BookmarkIndex.build(List<HighlightVerse> bookmarks) {
    final map = <String, HighlightVerse>{};
    for (final b in bookmarks) {
      map['${b.surah}-${b.verseNumber}'] = b;
    }
    return BookmarkIndex._(map, _signatureOf(bookmarks));
  }

  /// Returns `true` when the verse at ([surah], [verse]) is highlighted.
  bool isHighlighted(int surah, int verse) =>
      _byAyah.containsKey('$surah-$verse');

  /// Returns the bookmark for the verse at ([surah], [verse]), or `null`.
  HighlightVerse? lookup(int surah, int verse) => _byAyah['$surah-$verse'];

  /// Computes a stable hash of [list] for change detection.
  static int _signatureOf(List<HighlightVerse> list) {
    int hash = list.length;
    for (final b in list) {
      hash = 0x1fffffff &
          (hash + Object.hash(b.surah, b.verseNumber, b.color));
    }
    return hash;
  }
}

/// Const-friendly empty implementation of [BookmarkIndex].
class _EmptyBookmarkIndex implements BookmarkIndex {
  const _EmptyBookmarkIndex();

  @override
  Map<String, HighlightVerse> get _byAyah => const {};

  @override
  int get signature => 0;

  @override
  bool isHighlighted(int surah, int verse) => false;

  @override
  HighlightVerse? lookup(int surah, int verse) => null;
}

/// Memoizing builder for [WordHighlightIndex].
///
/// [refresh] rebuilds the underlying index only when the provided list's
/// signature differs from the currently cached index's signature.
class MemoizedWordHighlightIndex {
  WordHighlightIndex _current = WordHighlightIndex.empty;

  /// Returns an up-to-date [WordHighlightIndex] for [highlights], reusing the
  /// cached index when the input list has not changed.
  WordHighlightIndex refresh(List<WordHighlight> highlights) {
    final sig = WordHighlightIndex._signatureOf(highlights);
    if (sig != _current.signature) {
      _current = WordHighlightIndex.build(highlights);
    }
    return _current;
  }
}

/// Memoizing builder for [BookmarkIndex].
///
/// [refresh] rebuilds the underlying index only when the provided list's
/// signature differs from the currently cached index's signature.
class MemoizedBookmarkIndex {
  BookmarkIndex _current = BookmarkIndex.empty;

  /// Returns an up-to-date [BookmarkIndex] for [bookmarks], reusing the
  /// cached index when the input list has not changed.
  BookmarkIndex refresh(List<HighlightVerse> bookmarks) {
    final sig = BookmarkIndex._signatureOf(bookmarks);
    if (sig != _current.signature) {
      _current = BookmarkIndex.build(bookmarks);
    }
    return _current;
  }
}