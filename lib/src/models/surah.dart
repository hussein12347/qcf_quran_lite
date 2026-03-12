import 'ayah.dart';

/// Represents a single chapter (Surah) of the Holy Quran.
///
/// This model contains the metadata for a Surah, including its position in the
/// Mushaf, its starting and ending pages, its names in both English and Arabic,
/// and a complete list of its verses ([Ayah]s).
class Surah {
  /// The official number of the Surah within the Quran (from 1 for Al-Fatihah to 114 for An-Nas).
  final int index;

  /// The page number in the standard Mushaf where this Surah begins.
  final int startPage;

  /// The page number in the standard Mushaf where this Surah ends.
  /// This is mutable because it is often calculated dynamically during parsing.
  int endPage;

  /// The transliterated English name of the Surah (e.g., "Al-Baqarah").
  final String nameEn;

  /// The Arabic name of the Surah (e.g., "البقرة").
  final String nameAr;

  /// The complete list of verses ([Ayah] objects) that make up this Surah.
  List<Ayah> ayahs;

  Surah({
    required this.index,
    required this.startPage,
    required this.endPage,
    required this.nameEn,
    required this.nameAr,
    required this.ayahs,
  });

  /// Creates a [Surah] instance from a JSON map structure.
  ///
  /// Automatically parses the nested list of [Ayah] objects.
  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
    index: json['index'],
    startPage: json['start_page'],
    endPage: json['end_page'],
    nameEn: json['name_en'],
    nameAr: json['name_ar'],
    // Maps the nested JSON array into a list of Ayah models
    ayahs: json['ayahs'].map<Ayah>((ayah) => Ayah.fromJson(ayah)).toList(),
  );

  /// Converts this [Surah] instance, including all its nested [Ayah]s,
  /// into a JSON map for easy serialization or storage.
  Map<String, dynamic> toJson() => {
    "index": index,
    "start_page": startPage,
    "end_page": endPage,
    "name_en": nameEn,
    "name_ar": nameAr,
    // Converts the nested list of Ayah models back into a JSON array
    "ayahs": ayahs.map((ayah) => ayah.toJson()).toList(),
  };
}