import 'ayah.dart';

/// Represents a single physical page of the Holy Quran (typically out of 604 pages).
///
/// This model holds both the structural data (a flat list of [Ayah]s) and the
/// visual layout data (a list of physical [Line]s) needed to accurately render
/// the page exactly as it appears in the printed Mushaf.
class QuranPage {
  /// The physical page number in the standard Mushaf (1 to 604).
  final int pageNumber;

  /// The number of new Surahs that begin on this specific page.
  /// This is used by the UI to calculate how much vertical space to allocate
  /// for Surah headers and Basmallahs.
  int numberOfNewSurahs;

  /// A flat, chronological list of all the verses (or parts of verses) on this page.
  List<Ayah> ayahs;

  /// A list of visual [Line] objects representing exactly how the text is broken
  /// down row-by-row on the physical page.
  List<Line> lines;

  /// The Hizb/Rub/Juz marker number if one starts on this page, otherwise null.
  int? hizb;

  /// Indicates whether this page contains a verse requiring a prostration (Sajdah).
  bool hasSajda;

  /// Indicates if this page ends with the absolute last line of a Surah or Section.
  bool lastLine;

  QuranPage({
    required this.pageNumber,
    required this.ayahs,
    required this.lines,
    this.hizb,
    this.hasSajda = false,
    this.lastLine = false,
    this.numberOfNewSurahs = 0,
  });
}

/// Represents a single visual, horizontal line of text on a [QuranPage].
///
/// Because a single long [Ayah] can span multiple lines, and multiple short
/// [Ayah]s can fit on a single line, this model contains a list of the specific
/// verse segments that make up this exact row of text.
class Line {
  /// The segments of verses ([Ayah]s) that are rendered consecutively to form this line.
  List<Ayah> ayahs;

  /// Indicates if the text on this line should be visually centered.
  /// This is typically true for the last short line of a Surah or special markers.
  bool centered;

  Line(this.ayahs, {this.centered = false});
}