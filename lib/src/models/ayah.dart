/// Represents a single verse (Ayah) of the Holy Quran.
/// 
/// This model holds all the necessary metadata for a verse, including its
/// location (Surah, page, Juz), structural information (lines, centering),
/// and the actual text in multiple scripts (Standard, Emlaey, and Othmanic).
class Ayah {
  /// Unique identifier for the Ayah across the entire Quran.
  final int id;

  /// The Juz (part) number (1-30) where this Ayah is located.
  final int jozz;

  /// The number of the Surah (chapter) containing this Ayah (1-114).
  final int surahNumber;

  /// The page number in the standard Mushaf where this Ayah appears.
  final int page;

  /// The line number where this Ayah starts on the page.
  final int lineStart;

  /// The line number where this Ayah ends on the page.
  final int lineEnd;

  /// The verse number within its specific Surah.
  final int ayahNumber;

  /// The Rub el Hizb (quarter) index.
  final int quarter;

  /// The Hizb index.
  final int hizb;

  /// The English transliterated or translated name of the Surah.
  final String surahNameEn;

  /// The Arabic name of the Surah.
  final String surahNameAr;

  /// The plain/Emlaey text of the Ayah (often used for search without diacritics).
  final String ayahText;

  /// The standard display text of the Ayah with standard diacritics.
  String ayah;

  /// The text of the Ayah written in the beautiful Uthmani (Othmanic) script.
  String othmanicAyah;

  /// Indicates whether this Ayah requires a prostration (Sajdah).
  final bool sajda;

  /// Indicates if this specific text segment should be centered on the page
  /// (often true for the end of a Surah or special markers).
  bool centered;

  /// Tracks whether the user has marked this verse as a favorite/bookmark.
  bool isFavorite;

  Ayah({
    required this.id,
    required this.jozz,
    required this.surahNumber,
    required this.page,
    required this.lineStart,
    this.isFavorite = false,
    required this.lineEnd,
    required this.ayahNumber,
    required this.quarter,
    required this.hizb,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.ayah,
    required this.othmanicAyah,
    required this.ayahText,
    required this.sajda,
    required this.centered,
  });

  /// Converts the [Ayah] instance into a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'jozz': jozz,
    'sora': surahNumber,
    'page': page,
    'line_start': lineStart,
    'line_end': lineEnd,
    'aya_no': ayahNumber,
    'sora_name_en': surahNameEn,
    'sora_name_ar': surahNameAr,
    'aya_text': ayah,
    'aya_text_othmanic': othmanicAyah,
    'aya_text_emlaey': ayahText,
    'centered': centered,
  };

  @override
  String toString() =>
      "\"id\": $id, \"jozz\": $jozz,\"sora\": $surahNumber,\"page\": $page,\"line_start\": $lineStart,\"line_end\": $lineEnd,\"aya_no\": $ayahNumber,\"sora_name_en\": \"$surahNameEn\",\"sora_name_ar\": \"$surahNameAr\",\"aya_text\": \"${ayah.replaceAll("\n", "\\n")}\",\"aya_text_othmanic\": \"${othmanicAyah.replaceAll("\n", "\\n")}\",\"aya_text_emlaey\": \"${ayahText.replaceAll("\n", "\\n")}\",\"centered\": $centered";

  /// Factory constructor to create an [Ayah] instance from a JSON map.
  factory Ayah.fromJson(Map<String, dynamic> json) {
    // Process standard text (ayah) to ensure proper spacing around newlines
    String ayahTextParsed = json['aya_text'] ?? '';
    if (ayahTextParsed.isNotEmpty) {
      if (ayahTextParsed[ayahTextParsed.length - 1] == '\n') {
        ayahTextParsed = ayahTextParsed.insert(' ', ayahTextParsed.length - 1);
      } else {
        ayahTextParsed = '$ayahTextParsed ';
      }
    }

    // Process Othmanic text (othmanicAyah) to ensure proper spacing around newlines
    String ayahOthmanicText = json['aya_text_othmanic'] ?? '';
    if (ayahOthmanicText.isNotEmpty) {
      if (ayahOthmanicText[ayahOthmanicText.length - 1] == '\n') {
        ayahOthmanicText = ayahOthmanicText.insert(
          ' ',
          ayahOthmanicText.length - 1,
        );
      } else {
        ayahOthmanicText = '$ayahOthmanicText ';
      }
    }

    return Ayah(
      id: json['id'],
      jozz: json['jozz'],
      surahNumber: json['sora'] ?? 0,
      page: json['page'],
      lineStart: json['line_start'],
      lineEnd: json['line_end'],
      ayahNumber: json['aya_no'],
      quarter: -1,
      isFavorite: false,
      hizb: -1,
      surahNameEn: json['sora_name_en'],
      surahNameAr: json['sora_name_ar'],
      ayah: ayahTextParsed,
      ayahText: json['aya_text_emlaey'],
      sajda: false,
      centered: json['centered'] ?? false,
      othmanicAyah: ayahOthmanicText,
    );
  }

  /// Factory constructor used primarily when splitting an existing [Ayah] 
  /// into multiple line segments during page rendering.
  factory Ayah.fromAya({
    required Ayah ayah,
    required String aya,
    required String othmanicAyah,
    required String ayaText,
    bool centered = false,
  }) => Ayah(
    id: ayah.id,
    jozz: ayah.jozz,
    surahNumber: ayah.surahNumber,
    page: ayah.page,
    lineStart: ayah.lineStart,
    lineEnd: ayah.lineEnd,
    ayahNumber: ayah.ayahNumber,
    quarter: ayah.quarter,
    hizb: ayah.hizb,
    surahNameEn: ayah.surahNameEn,
    surahNameAr: ayah.surahNameAr,
    isFavorite: ayah.isFavorite,
    othmanicAyah: othmanicAyah,
    ayah: aya,
    ayahText: ayaText,
    sajda: false,
    centered: centered,
  );
}

const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Helpful string extensions for Quranic text manipulation.
extension StringExtensions on String {
  /// Inserts a [text] substring into the current string at the specified [index].
  String insert(String text, int index) =>
      substring(0, index) + text + substring(index);

  /// Converts standard Western/English numerals in a string to Eastern Arabic numerals.
  String toArabic() {
    String number = this;
    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }
}