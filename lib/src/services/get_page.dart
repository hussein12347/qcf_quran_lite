import '../data/mushaf_edition.dart';
import '../models/ayah.dart';
import '../models/quran_page.dart';
import '../models/surah.dart';

/// A service class responsible for processing and structuring the raw Quranic data
/// into a format suitable for UI rendering, including pages, lines, and surahs.
class GetPage {
  /// A list containing the fully processed pages of the Quran.
  List<QuranPage> staticPages = [];

  /// A list of page numbers where Quranic stops (like Hizb or Rub) occur.
  List<int> quranStops = [];

  /// A list of page indexes where new Surahs begin.
  List<int> surahsStart = [];

  /// Metadata for all the Surahs in the Quran (e.g., name, start/end pages).
  List<Surah> surahs = [];

  /// A flat list of all the Ayahs (verses) in the Quran.
  final List<Ayah> ayahs = [];

  /// Tracks the last processed page number.
  int lastPage = 0;

  /// The edition that the currently cached data was built with.
  MushafEdition? _builtEdition;

  /// Initializes and processes the Quran data into pages.
  ///
  /// Takes [quranPagesCount] to determine the total number of pages to generate
  /// (typically 604 for the standard Hafs Mushaf).
  ///
  /// Processing is skipped only if both the page count AND the active
  /// Mushaf edition match the cached data.
  void getQuran(int quranPagesCount) {
    if (staticPages.isNotEmpty &&
        quranPagesCount == staticPages.length &&
        _builtEdition == currentMushafEdition) {
      return;
    }

    // Clear all previous state so data from different editions never mixes.
    _reset();

    final List<Ayah> result = getQuranData();

    _processQuranData(result, quranPagesCount);

    _builtEdition = currentMushafEdition;
  }

  /// Clears all cached state before a rebuild.
  void _reset() {
    staticPages = [];
    quranStops = [];
    surahsStart = [];
    surahs = [];
    ayahs.clear();
    lastPage = 0;
  }

  /// Retrieves the raw Quran data of the active edition and converts it
  /// into a list of [Ayah] objects.
  List<Ayah> getQuranData() {
    final List<Ayah> othmanQuran =
        activeQuran.map((e) => Ayah.fromJson(e)).toList();
    return othmanQuran;
  }

  /// Core logic for organizing the flat list of Ayahs into pages,
  /// tracking Surah boundaries, and identifying special markers (Hizb, Sajda).
  void _processQuranData(List<Ayah> quranAyahsList, int quranPagesCount) {
    staticPages = List.generate(
      quranPagesCount,
      (index) => QuranPage(pageNumber: index + 1, ayahs: [], lines: []),
    );

    int hizb = 1;
    int surahsIndex = 1;
    List<Ayah> thisSurahAyahs = [];

    for (var ayah in quranAyahsList) {
      // Logic for identifying Surah boundaries
      if (ayah.surahNumber != surahsIndex) {
        if (surahs.isNotEmpty) {
          surahs.last.endPage = ayahs.last.page;
          surahs.last.ayahs = List.from(thisSurahAyahs);
        }
        surahsIndex = ayah.surahNumber;
        thisSurahAyahs = [];
      }

      ayahs.add(ayah);
      thisSurahAyahs.add(ayah);
      staticPages[ayah.page - 1].ayahs.add(ayah);

      // Identify Juz/Hizb markers and Sajda markers
      if (ayah.ayah.contains('۞')) {
        staticPages[ayah.page - 1].hizb = hizb++;
        quranStops.add(ayah.page);
      }
      if (ayah.ayah.contains('۩')) {
        staticPages[ayah.page - 1].hasSajda = true;
      }

      // Handle the start of a new Surah
      if (ayah.ayahNumber == 1) {
        // Remove the Rub/Hizb marker from the first ayah if it exists
        ayah.ayah = ayah.ayah.replaceAll('۞', '');
        staticPages[ayah.page - 1].numberOfNewSurahs++;

        surahs.add(
          Surah(
            index: ayah.surahNumber,
            startPage: ayah.page,
            endPage: 0,
            nameEn: ayah.surahNameEn,
            nameAr: ayah.surahNameAr,
            ayahs: [],
          ),
        );
        surahsStart.add(ayah.page - 1);
      }
    }

    // Finalize the metadata for the very last Surah (An-Nas)
    if (surahs.isNotEmpty) {
      surahs.last.endPage = ayahs.last.page;
      surahs.last.ayahs = thisSurahAyahs;
    }

    // Process line splitting logic after pages and ayahs are assigned
    _generateLines();
  }

  /// Splits the Ayahs on each page into precise visual lines based on newline `\n` characters.
  ///
  /// This ensures the text accurately mimics the physical layout of the printed Mushaf.
  void _generateLines() {
    for (var staticPage in staticPages) {
      // Clear existing lines to prevent duplication during state rebuilds
      staticPage.lines.clear();

      List<Ayah> currentLineAyahs = [];

      for (var aya in staticPage.ayahs) {
        // If it's the start of a new Surah
        if (aya.ayahNumber == 1) {
          // Add the previous line to the page only if it contains actual text content
          if (currentLineAyahs.isNotEmpty &&
              currentLineAyahs.any((a) => a.ayah.trim().isNotEmpty)) {
            staticPage.lines.add(Line(List.from(currentLineAyahs)));
            currentLineAyahs.clear();
          }
        }

        // Split the Ayah when a newline character (\n) is encountered
        if (aya.ayah.contains('\n')) {
          final parts = aya.ayah.split('\n');

          // Split the Othmanic text similarly to keep it synchronized with the standard text
          final othmanicParts = aya.othmanicAyah.split('\n');

          for (int i = 0; i < parts.length; i++) {
            final textPart = parts[i].trim();
            if (textPart.isEmpty) continue;

            // Extract the corresponding Othmanic part (with a safety fallback)
            String othmanicPart = textPart; // Default fallback
            if (i < othmanicParts.length) {
              othmanicPart = othmanicParts[i].trim();
            }

            final subAyah = Ayah.fromAya(
              ayah: aya,
              aya: textPart,
              othmanicAyah: othmanicPart,
              ayaText: textPart,
              centered: aya.centered && i == parts.length - 2,
            );

            currentLineAyahs.add(subAyah);

            // If this is not the last part of the split, commit the current line
            if (i < parts.length - 1) {
              staticPage.lines.add(Line(List.from(currentLineAyahs)));
              currentLineAyahs.clear();
            }
          }
        } else {
          // No newline found, just add the Ayah to the current line
          currentLineAyahs.add(aya);
        }
      }

      // Add the final line of the page if it contains actual content
      if (currentLineAyahs.isNotEmpty &&
          currentLineAyahs.any((a) => a.ayah.trim().isNotEmpty)) {
        staticPage.lines.add(Line(List.from(currentLineAyahs)));
      }
    }
  }
}