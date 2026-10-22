/// A lightweight, high-performance, and professional Flutter package to display the Holy Quran.
///
/// This library provides customizable widgets (`QuranPageView`) and comprehensive
/// data models/helpers to render Quranic pages using the official QCF font.
/// It includes built-in functions for searching, statistics, and metadata retrieval.
library;

import 'package:qcf_quran_lite/src/data/juzs.dart';
import 'package:qcf_quran_lite/src/data/quarters.dart';
import 'package:qcf_quran_lite/src/data/suwar.dart';
import 'package:qcf_quran_lite/src/data/mushaf_edition.dart';

// ---------------------------------------------------------------------------
// 1. UI Widgets Exports
// ---------------------------------------------------------------------------
export 'src/widgets/quran_page_view.dart';
export 'src/widgets/quran_surah_list_view.dart';
export 'src/utils/quran_text_styles.dart';
export 'src/data/mushaf_edition.dart';
export 'src/models/highlight_style.dart';
export 'src/data/juzs.dart';
export 'src/data/page_data.dart';
export 'src/data/quarters.dart';
export 'src/data/quran_data.dart';
export 'src/data/suwar.dart';
export 'src/models/highlight_word.dart';
export 'src/models/ayah.dart';
export 'src/tajweed/tajweed_rule.dart';
export 'src/tajweed/tajweed_annotator.dart';
export 'src/tajweed/mushaf_colors.dart';
export 'src/tajweed/tajweed_api.dart';
// ---------------------------------------------------------------------------
// 2. Models Exports
// ---------------------------------------------------------------------------
export 'src/models/highlight_verse.dart';
export 'src/models/quran_page.dart';
export 'src/models/surah.dart';

// ---------------------------------------------------------------------------
// 3. Quran Data Helper Functions
// ---------------------------------------------------------------------------

/// The most standard and common copy of Arabic-only Quran total pages count.
const int totalPagesCount = 604;

/// The constant total number of Makki surahs.
const int totalMakkiSurahs = 89;

/// The constant total number of Madani surahs.
const int totalMadaniSurahs = 25;

/// The constant total Juz count in the Holy Quran.
const int totalJuzCount = 30;

/// The constant total Surah count in the Holy Quran.
const int totalSurahCount = 114;

/// The constant total verse (Ayah) count in the Holy Quran.
const int totalVerseCount = 6236;

/// Switches the currently active Mushaf edition.
///
/// [edition] determines which layout/font mapping is used by all page-based
/// helpers (e.g. [getPageData], [getCurrentJuzNumberForPage]).
void setMushafEdition(MushafEdition edition) {
  setMushafEditionInternal(edition);
}

/// Returns the raw page data (list of verse ranges grouped by Surah)
/// for the given [pageNumber] (1-based).
///
/// Throws a [String] error if [pageNumber] is outside the valid range (1-604).
List getPageData(int pageNumber) {
  if (pageNumber < 1 || pageNumber > 604) {
    throw "Invalid page number. Page number must be between 1 and 604";
  }
  return activePageData[pageNumber - 1];
}

/// Returns the number of Surahs whose verses appear on [pageNumber].
///
/// Throws a [String] error if [pageNumber] is outside the valid range (1-604).
int getSurahCountByPage(int pageNumber) {
  if (pageNumber < 1 || pageNumber > 604) {
    throw "Invalid page number. Page number must be between 1 and 604";
  }
  return activePageData[pageNumber - 1].length;
}

/// Returns the total number of verses (Ayahs) present on [pageNumber].
///
/// Throws a [String] error if [pageNumber] is outside the valid range (1-604).
int getVerseCountByPage(int pageNumber) {
  if (pageNumber < 1 || pageNumber > 604) {
    throw "Invalid page number. Page number must be between 1 and 604";
  }
  int total = 0;
  for (final e in activePageData[pageNumber - 1]) {
    total += (e["end"] - e["start"] + 1) as int;
  }
  return total;
}

/// Converts a Western integer into its Arabic-Indic numeral representation.
///
/// Example: `123` becomes `"١٢٣"`.
String _convertToArabicNumber(int number) {
  const Map<String, String> arabicNumbers = {
    "0": "٠",
    "1": "١",
    "2": "٢",
    "3": "٣",
    "4": "٤",
    "5": "٥",
    "6": "٦",
    "7": "٧",
    "8": "٨",
    "9": "٩",
  };
  return number.toString().split('').map((e) => arabicNumbers[e] ?? e).join('');
}

/// Returns the Hizb/Quarter text **only** when a new quarter starts exactly
/// on [pageNumber]. Otherwise returns an empty string.
///
/// Set [isArabic] to `true` (default) for Arabic output, or `false` for English.
String getHizbTextByPage(int pageNumber, {bool isArabic = true}) {
  int quarterIndex = quarters.indexWhere(
    (q) => getPageNumber(q['surah']!, q['ayah']!) == pageNumber,
  );

  final bool showHizbText = quarterIndex != -1;

  if (!showHizbText) return "";

  int quarter = quarterIndex + 1;
  int hizb = ((quarter - 1) ~/ 4) + 1;
  int quarterInHizb = ((quarter - 1) % 4) + 1;

  String hizbNumber =
      isArabic ? _convertToArabicNumber(hizb) : hizb.toString();

  if (isArabic) {
    if (quarterInHizb == 1) return "الحزب $hizbNumber";
    if (quarterInHizb == 2) return "ربع الحزب $hizbNumber";
    if (quarterInHizb == 3) return "نصف الحزب $hizbNumber";
    if (quarterInHizb == 4) return "ثلاثة أرباع الحزب $hizbNumber";
  } else {
    if (quarterInHizb == 1) return "Hizb $hizbNumber";
    if (quarterInHizb == 2) return "1/4 Hizb $hizbNumber";
    if (quarterInHizb == 3) return "1/2 Hizb $hizbNumber";
    if (quarterInHizb == 4) return "3/4 Hizb $hizbNumber";
  }

  return "";
}

/// Returns the active Hizb/Quarter text that applies to the top of [pageNumber],
/// even if the quarter started on an earlier page.
String getCurrentHizbTextForPage(int pageNumber, {bool isArabic = true}) {
  int currentQuarterIndex = 0;

  for (int i = 0; i < quarters.length; i++) {
    int qPage = getPageNumber(quarters[i]['surah']!, quarters[i]['ayah']!);
    if (pageNumber >= qPage) {
      currentQuarterIndex = i;
    } else {
      break;
    }
  }

  int quarter = currentQuarterIndex + 1;
  int hizb = ((quarter - 1) ~/ 4) + 1;
  int quarterInHizb = ((quarter - 1) % 4) + 1;

  String hizbNumber =
      isArabic ? _convertToArabicNumber(hizb) : hizb.toString();

  if (isArabic) {
    if (quarterInHizb == 1) return "الحزب $hizbNumber";
    if (quarterInHizb == 2) return "ربع الحزب $hizbNumber";
    if (quarterInHizb == 3) return "نصف الحزب $hizbNumber";
    if (quarterInHizb == 4) return "ثلاثة أرباع الحزب $hizbNumber";
  } else {
    if (quarterInHizb == 1) return "Hizb $hizbNumber";
    if (quarterInHizb == 2) return "1/4 Hizb $hizbNumber";
    if (quarterInHizb == 3) return "1/2 Hizb $hizbNumber";
    if (quarterInHizb == 4) return "3/4 Hizb $hizbNumber";
  }

  return "";
}

/// Returns the Quarter (Rub' al-Hizb) number (1-240) for the given
/// [surahNumber] and [ayaNo].
int getQuarterNumber(int surahNumber, int ayaNo) {
  int currentQuarter = 1;
  for (int i = 0; i < quarters.length; i++) {
    int qSurah = quarters[i]["surah"]!;
    int qAyah = quarters[i]["ayah"]!;

    if (surahNumber > qSurah || (surahNumber == qSurah && ayaNo >= qAyah)) {
      currentQuarter = i + 1;
    } else {
      break;
    }
  }
  return currentQuarter;
}

/// Returns the Juz number (1-30) for the given [surahNumber] and [ayaNo].
///
/// Returns `-1` if the verse could not be matched to a Juz.
int getJuzNumber(int surahNumber, int ayaNo) {
  for (var juz in juz) {
    if (juz["verses"].keys.contains(surahNumber)) {
      if (ayaNo >= juz["verses"][surahNumber][0] &&
          ayaNo <= juz["verses"][surahNumber][1]) {
        return int.parse(juz["id"].toString());
      }
    }
  }
  return -1;
}

/// Returns the Juz number that the top of [pageNumber] belongs to.
///
/// Throws a [String] error if [pageNumber] is outside the valid range (1-604).
int getCurrentJuzNumberForPage(int pageNumber) {
  if (pageNumber < 1 || pageNumber > 604) {
    throw "Invalid page number. Page number must be between 1 and 604";
  }
  final firstEntryOnPage = activePageData[pageNumber - 1].first;
  final int surahNumber = firstEntryOnPage['surah']!;
  final int firstAyahOnPage = firstEntryOnPage['start']!;
  return getJuzNumber(surahNumber, firstAyahOnPage);
}

/// Returns the Mushaf page number (1-604) containing the given
/// [surahNumber] and [ayaNo].
///
/// Throws a [String] error if the Surah or verse is invalid.
int getPageNumber(int surahNumber, int ayaNo) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  final data = activePageData;
  for (int pageIndex = 0; pageIndex < data.length; pageIndex++) {
    for (final e in data[pageIndex]) {
      if (e['surah'] == surahNumber &&
          e['start'] <= ayaNo &&
          e['end'] >= ayaNo) {
        return pageIndex + 1;
      }
    }
  }
  throw "Invalid verse number.";
}

/// Returns the transliterated Surah name for [surahNumber].
String getSurahName(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['name'].toString();
}

/// Returns the English-translated Surah name for [surahNumber].
String getSurahNameEnglish(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['english'].toString();
}

/// Returns the Arabic Surah name for [surahNumber].
String getSurahNameArabic(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['arabic'].toString();
}

/// Returns the place of revelation (`"Makkah"` or `"Madinah"`) for [surahNumber].
String getPlaceOfRevelation(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No Surah found with given surahNumber";
  }
  return surah[surahNumber - 1]['place'].toString();
}

/// Returns the total number of verses within the given [surahNumber].
int getVerseCount(int surahNumber) {
  if (surahNumber > 114 || surahNumber <= 0) {
    throw "No verse found with given surahNumber";
  }
  return int.parse(surah[surahNumber - 1]['aya'].toString());
}

/// Returns the Arabic text of a specific verse identified by
/// [surahNumber] and [ayaNo].
///
/// Set [verseEndSymbol] to `true` to append the Ayah-number symbol
/// to the returned text.
String getVerse(int surahNumber, int ayaNo, {bool verseEndSymbol = false}) {
  String verse = "";
  for (var i in activeQuran) {
    if (i['sora'] == surahNumber && i['aya_no'] == ayaNo) {
      verse = i['aya_text'].toString();
      break;
    }
  }
  if (verse == "") {
    throw "No verse found with given surahNumber and aya_no.\n\n";
  }
  return verse;
}

/// Returns the ornate end-of-verse symbol (`'۝'`) enclosing [ayaNo].
///
/// Set [arabicNumeral] to `false` to use Western numerals instead of
/// Arabic-Indic numerals.
String getVerseEndSymbol(int ayaNo, {bool arabicNumeral = true}) {
  var arabicNumeric = '';
  var digits = ayaNo.toString().split("").toList();

  if (!arabicNumeral) return '\u06dd${ayaNo.toString()}';

  const Map arabicNumbers = {
    "0": "٠",
    "1": "۱",
    "2": "۲",
    "3": "۳",
    "4": "٤",
    "5": "٥",
    "6": "٦",
    "7": "۷",
    "8": "۸",
    "9": "۹",
  };

  for (var e in digits) {
    arabicNumeric += arabicNumbers[e];
  }

  return arabicNumeric;
}

/// Returns the QCF font glyph representing [ayaNo] for rendering purposes.
///
/// [surahNumber] and [ayaNo] identify the verse; [verseEndSymbol] is kept
/// for API compatibility with callers that toggle the symbol.
String getayaNoQCF(int surahNumber, int ayaNo, {bool verseEndSymbol = true}) {
  String glyph = "";
  for (var i in activeQuran) {
    if (i['sora'] == surahNumber && i['aya_no'] == ayaNo) {
      final String qcfData = i['aya_text_othmanic'].toString();

      final bool endsWithNewline = qcfData.endsWith('\n');
      glyph = endsWithNewline
          ? qcfData.substring(qcfData.length - 2, qcfData.length - 1)
          : qcfData.substring(qcfData.length - 1);
      break;
    }
  }

  if (glyph == "") {
    throw "No verse found with given surahNumber and aya_no.\n\n";
  }

  return glyph;
}

/// Lightweight Arabic text normalizer that unifies common letter variants and
/// strips basic diacritics for comparison purposes.
///
/// For a more robust search normalizer, use [normalizeArabicSearchText].
String normalizeArabicText(String text) {
  if (text.isEmpty) return text;

  text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

  text = text.replaceAll(RegExp(r'[إأآا]'), 'ا');

  text = text.replaceAll(RegExp(r'[يى]'), 'ي');

  text = text.replaceAll(RegExp(r'ة'), 'ه');

  return text;
}

// ---------------------------------------------------------------------------
// 4. Search & Normalization Engine
// ---------------------------------------------------------------------------

/// Normalizes Arabic text for accurate searching.
///
/// This function strips all Quranic symbols, diacritics (Tashkeel), and Waqf
/// marks. It also unifies different letter forms:
/// - Alef variants (أ, إ, آ, ٱ) → ا
/// - Ya/Alif-Maksura/Hamza-on-Ya (ى, ئ) → ي
/// - Hamza-on-Waw (ؤ) → و
/// - Ta-Marbuta (ة) → ه
///
/// The result is a plain, searchable form of the text.
String normalizeArabicSearchText(String text) {
  if (text.isEmpty) return text;

  // 1. Remove all Arabic diacritics and Quranic symbols (Tashkeel, Waqf marks, etc.).
  text = text.replaceAll(
      RegExp(
          r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E8\u06EA-\u06ED\u08D4-\u08E2\u08E3-\u08FF]'),
      '');

  // 2. Normalize Alef forms to bare Alef (ا).
  text = text.replaceAll(RegExp(r'[إأآٱ]'), 'ا');

  // 3. Normalize Ya and Alif Maksura to Ya (ي).
  text = text.replaceAll(RegExp(r'[ىئ]'), 'ي');

  // 4. Normalize Waw with Hamza to bare Waw (و).
  text = text.replaceAll(RegExp(r'[ؤ]'), 'و');

  // 5. Normalize Ta Marbuta to Ha (ه).
  text = text.replaceAll(RegExp(r'ة'), 'ه');

  return text;
}

/// A highly optimized, professional search engine for the Holy Quran.
///
/// - [query]: The Arabic text to search for.
/// - [limit]: Maximum number of results to return (defaults to 50).
/// - [exactMatch]: When `true`, enforces word-boundary matching so that
///   searching for `"حم"` will not match `"محمد"`.
///
/// Returns a [Map] with:
/// - `occurences`: Total number of matches found within [limit].
/// - `result`: A [List] of [Map]s, each containing `sora`, `aya_no`,
///   `text_othmanic`, and `text_emlaey`.
Map<String, dynamic> searchWords(String query,
    {int limit = 50, bool exactMatch = false}) {
  if (query.trim().isEmpty) {
    return {"occurences": 0, "result": []};
  }

  List<Map<String, dynamic>> result = [];

  // Normalize the user's input.
  String normalizedQuery = normalizeArabicSearchText(query.trim());

  // Prepare a regex for exact word-boundary matching when requested.
  RegExp? exactMatchRegex;
  if (exactMatch) {
    exactMatchRegex =
        RegExp(r'(?:^|\s)' + RegExp.escape(normalizedQuery) + r'(?:\s|$)');
  }

  for (var aya in activeQuran) {
    // Search within the Emlaey (standard Arabic) text for best accuracy.
    String emlaeyText = aya['aya_text_emlaey']?.toString() ?? "";
    String normalizedEmlaey = normalizeArabicSearchText(emlaeyText);

    bool isMatch = false;

    if (exactMatch && exactMatchRegex != null) {
      isMatch = exactMatchRegex.hasMatch(normalizedEmlaey);
    } else {
      isMatch = normalizedEmlaey.contains(normalizedQuery);
    }

    if (isMatch) {
      result.add({
        "sora": aya["sora"],
        "aya_no": aya["aya_no"],
        // Return both formats so the caller can display Uthmani text while
        // knowing the match was performed against the Emlaey text.
        "text_othmanic":
            aya['aya_text']?.toString().replaceAll('\n', '').trim(),
        "text_emlaey": emlaeyText.replaceAll('\n', '').trim(),
      });

      // Stop searching once the requested limit is reached.
      if (result.length >= limit) break;
    }
  }

  return {"occurences": result.length, "result": result};
}

/// Converts Quran text into a normalized form suitable for search or comparison.
///
/// Removes Quranic annotations, tatweel, tashkeel, and unifies certain letters
/// (e.g. Ya/Hamza forms, Alef variants). Useful before calling [searchWords].
String normalise(String input) => input
    .replaceAll('\u0610', '')
    .replaceAll('\u0611', '')
    .replaceAll('\u0612', '')
    .replaceAll('\u0613', '')
    .replaceAll('\u0614', '')
    .replaceAll('\u0615', '')
    .replaceAll('\u0616', '')
    .replaceAll('\u0617', '')
    .replaceAll('\u0618', '')
    .replaceAll('\u0619', '')
    .replaceAll('\u061A', '')
    .replaceAll('\u06D6', '')
    .replaceAll('\u06D7', '')
    .replaceAll('\u06D8', '')
    .replaceAll('\u06D9', '')
    .replaceAll('\u06DA', '')
    .replaceAll('\u06DB', '')
    .replaceAll('\u06DC', '')
    .replaceAll('\u06DD', '')
    .replaceAll('\u06DE', '')
    .replaceAll('\u06DF', '')
    .replaceAll('\u06E0', '')
    .replaceAll('\u06E1', '')
    .replaceAll('\u06E2', '')
    .replaceAll('\u06E3', '')
    .replaceAll('\u06E4', '')
    .replaceAll('\u06E5', '')
    .replaceAll('\u06E6', '')
    .replaceAll('\u06E7', '')
    .replaceAll('\u06E8', '')
    .replaceAll('\u06E9', '')
    .replaceAll('\u06EA', '')
    .replaceAll('\u06EB', '')
    .replaceAll('\u06EC', '')
    .replaceAll('\u06ED', '')
    .replaceAll('\u0640', '')
    .replaceAll('\u064B', '')
    .replaceAll('\u064C', '')
    .replaceAll('\u064D', '')
    .replaceAll('\u064E', '')
    .replaceAll('\u064F', '')
    .replaceAll('\u0650', '')
    .replaceAll('\u0651', '')
    .replaceAll('\u0652', '')
    .replaceAll('\u0653', '')
    .replaceAll('\u0654', '')
    .replaceAll('\u0655', '')
    .replaceAll('\u0656', '')
    .replaceAll('\u0657', '')
    .replaceAll('\u0658', '')
    .replaceAll('\u0659', '')
    .replaceAll('\u065A', '')
    .replaceAll('\u065B', '')
    .replaceAll('\u065C', '')
    .replaceAll('\u065D', '')
    .replaceAll('\u065E', '')
    .replaceAll('\u065F', '')
    .replaceAll('\u0670', '')
    .replaceAll('\u0624', '\u0648')
    .replaceAll('\u0629', '\u0647')
    .replaceAll('\u064A', '\u0649')
    .replaceAll('\u0626', '\u0649')
    .replaceAll('\u0622', '\u0627')
    .replaceAll('\u0623', '\u0627')
    .replaceAll('\u0625', '\u0627');

/// Removes basic Arabic diacritics (tashkeel) from [input].
///
/// Keeps base letters intact while stripping marks such as Fatha, Damma,
/// Kasra, Shadda, and tanwin. Useful for lightweight fuzzy matching.
String removeDiacritics(String input) {
  // Written as escapes so the combining marks cannot detach from the quotes:
  // fatha, damma, kasra, shadda, fathatan, dammatan, kasratan.
  Map<String, String> diacriticsMap = {
    '\u064E': '',
    '\u064F': '',
    '\u0650': '',
    '\u0651': '',
    '\u064B': '',
    '\u064C': '',
    '\u064D': '',
  };

  String diacriticsPattern =
      diacriticsMap.keys.map((e) => RegExp.escape(e)).join('|');
  RegExp exp = RegExp('[$diacriticsPattern]');

  String textWithoutDiacritics = input.replaceAll(exp, '');

  return textWithoutDiacritics;
}