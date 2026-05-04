import 'dart:ui';

/// Represents a specific Quranic verse that has been highlighted by the user.
///
/// This model stores the location of the verse (Surah, verse number, and page)
/// along with the specific [Color] used for the highlight.
class HighlightVerse {
  /// The verse (Ayah) number within the Surah.
  final int verseNumber;

  /// The number of the Surah (chapter) containing this verse (1-114).
  final int surah;

  /// The page number in the standard Mushaf where this verse is located.
  final int page;

  /// The visual color applied to this highlighted verse.
  final Color color;

  const HighlightVerse({
    required this.verseNumber,
    required this.page,
    required this.surah,
    required this.color,
  });

  /// Creates a copy of this [HighlightVerse] but with the given fields
  /// replaced with the new values.
  HighlightVerse copyWith({
    int? verseNumber,
    int? page,
    int? surah,
    Color? color,
  }) {
    return HighlightVerse(
      surah: surah ?? this.surah,
      verseNumber: verseNumber ?? this.verseNumber,
      page: page ?? this.page,
      color: color ?? this.color,
    );
  }

  /// Converts this [HighlightVerse] instance into a map,
  /// useful for local storage or database serialization.
  Map<String, dynamic> toMap() {
    return {
      'verseNumber': verseNumber,
      'surah': surah,
      'page': page,
      // Store the color as an integer value for easy serialization
      'color': color.toARGB32(),
    };
  }

  /// Creates a [HighlightVerse] instance from a map structure.
  factory HighlightVerse.fromMap(Map<String, dynamic> map) {
    return HighlightVerse(
      verseNumber: map['verseNumber'] as int,
      page: map['page'] as int,
      surah: map['surah'] as int,
      // Reconstruct the Color object from the stored integer value
      color: Color(map['color'] as int),
    );
  }

  @override
  String toString() =>
      'HighlightVerse(surah: $surah, verseNumber: $verseNumber, page: $page, color: ${color.toARGB32()})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightVerse &&
        other.surah == surah &&
        other.verseNumber == verseNumber &&
        other.page == page &&
        other.color.toARGB32() == color.toARGB32();
  }

  @override
  int get hashCode =>
      surah.hashCode ^ verseNumber.hashCode ^ page.hashCode ^ color.toARGB32().hashCode;
}