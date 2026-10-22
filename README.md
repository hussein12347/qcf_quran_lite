# 🕌 qcf_quran_lite

[![Pub Version](https://img.shields.io/pub/v/qcf_quran_lite?color=blue&style=flat-square)](https://pub.dev/packages/qcf_quran_lite)
[![Flutter](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter&style=flat-square)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

A **lightweight, high-performance Flutter Quran package** using the official **QCF (Hafs) font**.

Designed for professional Islamic applications, this package provides a fully offline, 60fps optimized Quran rendering engine.

It adds only ~10MB to your app size while providing full Mushaf rendering (single and two-page layouts), Tajweed coloring and rules API, word-level interaction, smart search, and a comprehensive metadata API.

---

## 📸 Screenshots

<p align="center">
  <img width="250" alt="Screenshot_20260304_165118" src="https://github.com/user-attachments/assets/54df12fb-be44-4389-b091-82ce5917e45f" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/372c8b5f-3aff-40bc-a6d0-a1515407608f" />

  <img width="250" alt="Screenshot_20260304_165147" src="https://github.com/user-attachments/assets/99a8e173-c12c-4914-9afd-038b1e688a08" />
</p>

<p align="center">
   <img width="250" alt="Screenshot_20260304_165800" src="https://github.com/user-attachments/assets/f650db8b-a7a2-4b4f-addb-e2367384dd61" />
   <img width="250" alt="Screenshot_20260304_165812" src="https://github.com/user-attachments/assets/72d2aaaf-cfd1-44ad-af6d-64ba8f9767dd" />
</p>

---

## 🌟 Why `qcf_quran_lite`?

Most Quran packages are either too heavy or require network downloads. This package is:

- **100% Offline Ready**
- **Minimal Size Impact**: Approx. 10MB for the complete 604-page Quran data and fonts
- **Highly Performant**: Built for 60fps smooth scrolling with optimized JSON structures and efficient line rendering
- **Production Ready**: Designed for real-world Islamic apps

---

## 🧭 Features at a Glance

| Area | What you get |
|------|--------------|
| 📜 Mushaf pages | 604-page Madinah layout, single or **two-page** layout, horizontal or **vertical** scroll |
| 📚 Mushaf editions | Switch between the **1985** and **2003** editions at runtime |
| 📖 Surah list reader | Scrollable per-Surah list with custom ayah cards and scroll-position tracking |
| 🎯 Ayah highlighting | Multiple built-in looks (soft, outlined, side bar, underline) or fully custom styles |
| 🔤 Word highlighting | Tap any word, highlight it with background / border / shadow / underline / wavy styles |
| 🎨 Tajweed | Colored Tajweed rendering (light & dark) plus a **rules API** per word or per ayah |
| 🔍 Smart search | Diacritic-insensitive, optional exact-word match, normalization helper |
| 📊 Metadata API | Surah info, Juz, Hizb quarters, page data, counts and constants |
| 🧩 Customization | Override ayah numbers, Surah header, Basmallah, top/bottom bars, page background |
| 👆 Gestures | Tap ayah number, tap word, long-press ayah (with position) |

---

## 🚀 Getting Started

### 1. Add Dependencies

```yaml
dependencies:
  qcf_quran_lite: ^latest_version
  scrollable_positioned_list: ^0.3.8
```

### 2. Import

```dart
import 'package:qcf_quran_lite/qcf_quran_lite.dart';
```

---

## ✨ Features & Usage Examples

### 📜 1. Authentic Mushaf Page Mode (604 Pages)

Displays the Quran in the real Madinah Mushaf layout (page by page), driven by a standard `PageController`.

```dart
final PageController _controller = PageController(initialPage: 0);
List<HighlightVerse> _activeHighlights = [];

QuranPageView(
  pageController: _controller,
  highlights: _activeHighlights,
  isDarkMode: false,
  onPageChanged: (pageNumber) {
    print("User navigated to page: $pageNumber");
    print(getCurrentHizbTextForPage(pageNumber));
  },
  onLongPressStart: (surahNumber, verseNumber, details) {
    print("Long-pressed Surah: $surahNumber, Verse: $verseNumber");
    print("At: ${details.globalPosition}"); // great for showing a context menu
  },
);
```

#### Layout & scrolling options

```dart
QuranPageView(
  pageController: _controller,

  // Two-page (book spread) layout on wide screens
  enableTwoPageLayout: true,
  twoPageMinWidth: 750, // minimum width in px to switch to two pages

  // Scrolling behavior
  scrollDirection: Axis.vertical,            // or Axis.horizontal
  pageSnapping: true,
  physics: const BouncingScrollPhysics(),    // or ClampingScrollPhysics()

  // Look & spacing
  pageBackgroundColor: Colors.brown.withValues(alpha: 0.05),
  pagePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  twoPagePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
);
```

> 💡 Vertical scrolling disables the two-page layout.

---

### 📚 2. Mushaf Editions (1985 / 2003)

Switch between two Mushaf print editions at runtime.

```dart
// Read the current edition
print(currentMushafEdition);

// Change it
setMushafEdition(MushafEdition.edition1985);
setMushafEdition(MushafEdition.edition2003);
```

> ⚠️ Page breaks differ between editions. After switching, rebuild `QuranPageView` (e.g. with `key: ValueKey(edition)`) and recompute the page number of the ayah the user was reading using `getPageNumber(surah, ayah)`.

```dart
final int newPage = getPageNumber(anchorSurah, anchorAyah);
_pageController = PageController(initialPage: newPage - 1);
```

---

### 📖 3. Vertical Reading Mode (Surah List)

A scrollable list view for a specific Surah. Ideal for Tafsir apps, translation views, or audio-synced Quran players.

```dart
final ItemScrollController _itemScrollController = ItemScrollController();
final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
List<HighlightVerse> _activeHighlights = [];

QuranSurahListView(
  surahNumber: 1,
  itemScrollController: _itemScrollController,
  itemPositionsListener: _itemPositionsListener,
  initialScrollIndex: 0,
  highlights: _activeHighlights,
  isDarkMode: false,
  isTajweed: true,
  fontSize: 26,
  onAyahNumberTap: (surah, verse) => print('Ayah number tapped: $surah:$verse'),
  onLongPress: (surah, verse, details) => print('Long press: $surah:$verse'),
  ayahBuilder: (context, surahNumber, verseNumber, pageNumber, ayahWidget,
      isHighlighted, highlightColor) {
    return Container(
      color: isHighlighted
          ? highlightColor.withValues(alpha: 0.2)
          : Colors.transparent,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ayah $verseNumber • Page $pageNumber',
              style: const TextStyle(color: Colors.grey)),
          ayahWidget,
        ],
      ),
    );
  },
);
```

#### Scroll to an ayah programmatically

```dart
_itemScrollController.scrollTo(
  index: ayahNumber,
  duration: const Duration(milliseconds: 800),
  curve: Curves.easeInOutCubic,
  alignment: 0.25,
);
```

#### Track the visible ayah (progress bar)

```dart
_itemPositionsListener.itemPositions.addListener(() {
  final positions = _itemPositionsListener.itemPositions.value;
  final visible = positions.where((p) => p.itemTrailingEdge > 0);
  if (visible.isEmpty) return;
  final firstVisibleAyah =
      visible.map((p) => p.index).reduce((a, b) => a < b ? a : b);
  print('Reading ayah $firstVisibleAyah of ${getVerseCount(1)}');
});
```

---

### 🎯 4. Dynamic Ayah Highlighting

Highlight specific verses for audio tracking, bookmarks, search results, or reading progress by passing a list of `HighlightVerse`.

```dart
List<HighlightVerse> _activeHighlights = [];

// Add a highlight (e.g., Ayatul Kursi)
setState(() {
  _activeHighlights = [
    HighlightVerse(
      surah: 2,
      verseNumber: 255,
      page: getPageNumber(2, 255),
      color: Colors.amber.withValues(alpha: 0.4),
    ),
  ];
});

// Clear all highlights
// setState(() => _activeHighlights = []);
```

You can pass **several highlights at once** (for example bookmarks + the currently playing ayah + a temporary "flash" highlight after a search jump).

#### 🖌️ Ayah highlight styles (`AyahHighlightStyle`)

Pass `ayahHighlightStyle` to `QuranPageView` to control how highlights look.

```dart
// Soft background
AyahHighlightStyle(
  opacity: 0.15,
  borderRadius: BorderRadius.circular(8),
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
);

// Outlined box
AyahHighlightStyle(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decorationBuilder: (color) => BoxDecoration(
    color: color.withValues(alpha: 0.15),
    border: Border.all(color: color, width: 1.5),
    borderRadius: BorderRadius.circular(8),
  ),
);

// Underline only
AyahHighlightStyle(
  decorationBuilder: (color) => BoxDecoration(
    border: Border(bottom: BorderSide(color: color, width: 2)),
  ),
);

// Fully custom wrapper (e.g. a side bar)
AyahHighlightStyle(
  wrapperBuilder: (context, child, color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      border: BorderDirectional(start: BorderSide(color: color, width: 4)),
    ),
    child: child,
  ),
);
```

The same style object can be applied to your own cards in `QuranSurahListView.ayahBuilder`:

```dart
buildAyahHighlightStyle().apply(
  context,
  card,
  isHighlighted ? highlightColor : null,
);
```

---

### 🔤 5. Word-Level Interaction & Highlighting

Every word is tappable. Use `onWordTap` and `WordHighlight` to build memorization tools, word-by-word study, or per-word Tajweed lookups.

```dart
List<WordHighlight> _wordHighlights = [];

QuranPageView(
  pageController: _controller,
  wordHighlights: _wordHighlights,
  onWordTap: (surah, verse, wordIndex, word) {
    setState(() {
      _wordHighlights = [
        WordHighlight(
          surah: surah,
          verseNumber: verse,
          wordIndex: wordIndex,
          backgroundColor: Colors.brown.withValues(alpha: 0.25),
        ),
      ];
    });
  },
);
```

`QuranSurahListView` supports the same `wordHighlights` and `onWordTap` parameters.

#### 🖌️ Word highlight styles (`WordHighlightStyle`)

```dart
// Default background
const WordHighlightStyle();

// Rounded background
WordHighlightStyle(
  backgroundOpacity: 0.25,
  borderRadius: BorderRadius.circular(8),
  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
);

// Bordered (border color follows the highlight color)
WordHighlightStyle(
  backgroundOpacity: 0.1,
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decorationBuilder: (h, bg) {
    final active =
        h.backgroundColor?.withValues(alpha: 1.0) ?? h.textColor ?? Colors.amber;
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: active, width: 1.5),
    );
  },
);

// Raised shadow with white text
WordHighlightStyle(
  backgroundOpacity: 1.0,
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decorationBuilder: (h, bg) {
    final active = bg ?? h.textColor ?? Colors.blueGrey;
    return BoxDecoration(
      color: active,
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(
          color: active.withValues(alpha: 0.5),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  },
  styleBuilder: (h, base) =>
      base.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
);

// Underline
WordHighlightStyle(
  styleBuilder: (h, base) => base.copyWith(
    backgroundColor: Colors.transparent,
    decoration: TextDecoration.underline,
    decorationThickness: 2,
    decorationColor: h.backgroundColor?.withValues(alpha: 1) ?? h.textColor,
  ),
);

// Wavy underline
WordHighlightStyle(
  styleBuilder: (h, base) => base.copyWith(
    backgroundColor: Colors.transparent,
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.wavy,
    decorationThickness: 2,
    decorationColor: h.backgroundColor?.withValues(alpha: 1) ?? h.textColor,
  ),
);
```

Then pass it with `wordHighlightStyle: ...` to `QuranPageView` or `QuranSurahListView`.

---

### 🎨 6. Tajweed Coloring & Rules API

#### Colored Tajweed rendering

```dart
QuranPageView(
  pageController: _controller,
  isTajweed: true,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
);

QuranSurahListView(
  surahNumber: 2,
  isTajweed: true,
  isDarkMode: false,
);
```

#### Tajweed rules for a single word

```dart
final List<TajweedLetterRule> rules = getWordTajweedRules(
  2,   // surah
  255, // verse
  0,   // word index (0-based)
  includeNaturalMadd: false,
  includeTafkhim: true,
);

for (final r in rules) {
  print('${r.letter} (letter #${r.letterIndex + 1}) → ${r.rule.label}');
  print('Range in word: ${r.start}..${r.end}');
}
```

#### Tajweed rules for a whole ayah

```dart
// One list of letter-rules per word
final List<List<TajweedLetterRule>> ayahRules = getAyahTajweedRules(
  2,
  255,
  includeNaturalMadd: false,
  includeTafkhim: true,
);
```

#### Rule metadata

Each `TajweedRule` exposes everything you need to build a rule card:

```dart
final rule = rules.first.rule;

print(rule.label);        // Arabic name
print(rule.englishName);  // English name
print(rule.amount);       // e.g. length of the madd
print(rule.definition);   // definition text
print(rule.letters);      // letters of the rule
print(rule.source);       // reference
print(rule.evidence);     // evidence text
```

#### Theme-aware rule colors

```dart
Color ruleColor(TajweedRule rule, bool isDark) =>
    isDark ? MushafColors.dark.tajweedColor(rule) : rule.color;
```

#### Render a word with colored Tajweed letters

```dart
Widget coloredWord(String word, List<TajweedLetterRule> rules, bool isDark,
    {required Color baseColor, double fontSize = 28}) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final r in rules) {
    if (r.start < cursor || r.end > word.length) continue;
    if (r.start > cursor) spans.add(TextSpan(text: word.substring(cursor, r.start)));
    spans.add(TextSpan(
      text: word.substring(r.start, r.end),
      style: TextStyle(color: ruleColor(r.rule, isDark)),
    ));
    cursor = r.end;
  }
  if (cursor < word.length) spans.add(TextSpan(text: word.substring(cursor)));

  return Text.rich(
    TextSpan(
      style: QuranTextStyles.tajweedHafsStyle(color: baseColor, fontSize: fontSize),
      children: spans,
    ),
    textDirection: TextDirection.rtl,
  );
}
```

> 💡 Use `QuranTextStyles.tajweedHafsStyle(...)` for Tajweed-colored text and `QuranTextStyles.hafsStyle(...)` for plain Hafs text anywhere in your app.

---

### 🔍 7. Smart Arabic Search

A fast, in-memory, diacritic-insensitive search engine. It automatically normalizes Alef variations and unifies Ya/Hamza, and supports an **exact word match** mode.

```dart
final Map results = searchWords(
  "الرحمن",
  limit: 50,
  exactMatch: false, // true → match the whole word only
);

print("Total matches found: ${results['occurences']}");

for (final match in results['result'] as List) {
  final int sNum = match['sora'];
  final int vNum = match['aya_no'];
  final String text = match['text_othmanic'];

  print('Surah: ${getSurahNameArabic(sNum)} - Ayah: $vNum');
  print('Page: ${getPageNumber(sNum, vNum)}');
  print('Verse Text: $text');
}
```

Show how a query is normalized before matching:

```dart
print(normalizeArabicSearchText("الرَّحْمَٰن")); // normalized search form
```

---

### 📊 8. Comprehensive Metadata API

Retrieve Surah names, Juz numbers, Quarters (Rub el Hizb), and page data without parsing large JSON files.

```dart
// Surah info
String arabicName = getSurahNameArabic(1);
String englishName = getSurahNameEnglish(1);
String place = getPlaceOfRevelation(1); // 'Makkah' or 'Madinah'
int totalAyahs = getVerseCount(1);

// Lookups by ayah
int pageNum = getPageNumber(2, 255);
int juzNum = getJuzNumber(2, 255);
int quarterNum = getQuarterNumber(2, 255);

// Page-level info
String hizbText = getCurrentHizbTextForPage(5, isArabic: true);
String hizbStart = getHizbTextByPage(5);       // text if a Hizb starts on this page
int juzOfPage = getCurrentJuzNumberForPage(5);
int surahsOnPage = getSurahCountByPage(5);
int versesOnPage = getVerseCountByPage(5);

// Page content (list of segments: surah / start / end)
final pageData = getPageData(5);
print(pageData.first['surah']);
print(pageData.first['start']);
```

#### Hizb quarters

`quarters` is a list of `{surah, ayah}` entries (8 per Juz, 4 per Hizb), perfect for building an index screen:

```dart
for (var juz = 0; juz < totalJuzCount; juz++) {
  final q = quarters[juz * 8]; // first quarter of each Juz
  print('Juz ${juz + 1} starts at ${q['surah']}:${q['ayah']}');
}
```

---

### 📝 9. Text & Diacritics Helpers

Need the raw text, text without diacritics, or the Othmanic end-of-verse symbol?

```dart
String verse = getVerse(2, 255, verseEndSymbol: false);
String plainText = removeDiacritics(verse);
String endSymbol = getVerseEndSymbol(255); // ۝ with the verse number
String glyph = getaya_noQCF(2, 255);
```

Clean a verse and split it into words:

```dart
String clean = getVerse(2, 255)
    .replaceAll('\n', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

List<String> words = clean.split(' ');
```

---

### 🧮 10. Built-in Constants

```dart
print(totalPagesCount);   // 604
print(totalSurahCount);   // 114
print(totalVerseCount);
print(totalMakkiSurahs);
print(totalMadaniSurahs);
print(totalJuzCount);     // 30
```

---

## 🧩 Customization Power

Every visual part of the Mushaf can be replaced with your own widgets.

### Custom ayah number

```dart
QuranPageView(
  pageController: _controller,
  ayahNumberAlignment: PlaceholderAlignment.middle, // middle / baseline / bottom
  ayahNumberBuilder: (context, surahNumber, verseNumber, glyph, isDark) {
    final color = isDark ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.primary;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        getVerseEndSymbol(verseNumber),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  },
);
```

`ayahNumberBuilder` and `ayahNumberAlignment` are also available on `QuranSurahListView`.

### Custom Surah header & Basmallah

```dart
QuranPageView(
  pageController: _controller,
  surahHeaderBuilder: (context, surahNumber) => SizedBox(
    height: 56,
    child: Center(child: Text('سورة ${getSurahNameArabic(surahNumber)}')),
  ),
  basmallahBuilder: (context, surahNumber) => SizedBox(
    height: 44,
    child: Center(
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        style: QuranTextStyles.hafsStyle(fontSize: 22, color: Colors.black),
      ),
    ),
  ),
);
```

### Top & bottom bars, page background

```dart
QuranPageView(
  pageController: _controller,
  topBarBuilder: (context, pageNumber) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('الجزء ${getCurrentJuzNumberForPage(pageNumber)}'),
        Text(getCurrentHizbTextForPage(pageNumber, isArabic: true)),
      ],
    ),
  ),
  bottomBarBuilder: (context, pageNumber) => Center(child: Text('$pageNumber')),
  pageBackgroundBuilder: (context, pageContent) => Container(
    decoration: BoxDecoration(
      color: Colors.brown.withValues(alpha: 0.02),
      borderRadius: BorderRadius.circular(10),
    ),
    child: pageContent,
  ),
);
```

### Gestures

| Callback | Available on | Description |
|----------|--------------|-------------|
| `onPageChanged(pageNumber)` | `QuranPageView` | Fired when the visible page changes |
| `onWordTap(surah, verse, wordIndex, word)` | Both views | A word was tapped |
| `onAyahNumberTap(surah, verse)` | Both views | The ayah-end number was tapped |
| `onLongPressStart(surah, verse, details)` | `QuranPageView` | Long press began (use `details.globalPosition` for menus) |
| `onLongPress(surah, verse, details)` | `QuranSurahListView` | Long press on an ayah |

---

## 🧪 Recipe Ideas (built with the API above)

The demo app shows how to combine the building blocks into complete features:

- **Context menu on long press** → play from here, copy, bookmark, ayah details.
- **Bookmarks** → keep a list of `(surah, verse)` and pass them as gold `HighlightVerse` entries.
- **Audio-follow mode** → a timer that advances `HighlightVerse` and calls `PageController.animateToPage(getPageNumber(s, v) - 1)`.
- **Ayah details sheet** → page, Juz, quarter, place of revelation, verse count.
- **Tajweed sheets** → per-word and per-ayah rule explanations using `getWordTajweedRules` / `getAyahTajweedRules`.
- **Index screen** → Surahs, Juz and Hizb quarters using `getPageNumber` and `quarters`.
- **Page jump & page info** → `getPageData`, `getSurahCountByPage`, `getVerseCountByPage`.
- **Memorization (hide) mode** → hide the words of the current page by giving each word a transparent `WordHighlight(textColor: Colors.transparent)`, then reveal them one by one on a timer (or on tap) by removing them from the list. Disable `isTajweed` while hiding, so colors don't reveal the words.

```dart
// Hide a word
WordHighlight(
  surah: s,
  verseNumber: v,
  wordIndex: i,
  backgroundColor: Colors.transparent,
  textColor: Colors.transparent,
);

// Style that makes transparent-text highlights truly invisible
WordHighlightStyle(
  backgroundOpacity: 1.0,
  styleBuilder: (h, base) => h.textColor == Colors.transparent
      ? base.copyWith(color: Colors.transparent, backgroundColor: Colors.transparent)
      : base,
);
```

---

## 🆕 Latest Updates

- Two-page layout and vertical scrolling for Mushaf pages
- Runtime Mushaf edition switching (1985 / 2003)
- Tajweed coloring with dark-mode palette and a full rules API
- Word-level tap and highlight, with ready-made styles (bordered, shadow, underline, wavy)
- Ayah highlight styles (soft, outlined, side bar, underline) and custom wrappers
- Exact-match search and Arabic normalization helper
- Richer metadata API (page data, Hizb text, per-page counts, quarters)
- Improved rendering performance and reduced memory usage

---

## 📦 Use Cases

Perfect for:

- Quran apps
- Tafsir apps
- Memorization (Hifz) and revision tools
- Tajweed learning apps
- Educational platforms
- Audio Quran players

---

## 🤝 Contributing

Contributions are welcome!

If you have ideas, improvements, or bug fixes:

- Open an issue
- Submit a pull request

---

## 📬 Contact

**Hussein Khaled**
Package Developer : **Hussein Khaled**
LinkedIn: https://www.linkedin.com/in/hussein-khalid-703228364/

Feel free to reach out for:

- Collaboration
- Freelance work
- Suggestions

---

## 📄 License

MIT License

---

> Built with ❤️ for high-quality Quran applications.
