# 🕌 qcf_quran_lite

[![Pub Version](https://img.shields.io/pub/v/qcf_quran_lite?color=blue&style=flat-square)](https://pub.dev/packages/qcf_quran_lite)
[![Flutter](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter&style=flat-square)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

A **lightweight, high-performance Flutter Quran package** using the official **QCF (Hafs) font**.

Designed for professional Islamic applications, this package provides a fully offline, 60fps optimized Quran rendering engine.

It adds only ~10MB to your app size while providing full Mushaf rendering, smart search, and a comprehensive metadata API.

---

## 📸 Screenshots

<p align="center">
  <img width="250" alt="Screenshot_20260304_165118" src="https://github.com/user-attachments/assets/54df12fb-be44-4389-b091-82ce5917e45f" />
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

## 🚀 Getting Started

### 1. Add Dependencies

```yaml
dependencies:
  qcf_quran_lite: ^latest_version
  scrollable_positioned_list: ^0.3.8
````

### 2. Import

```dart
import 'package:qcf_quran_lite/qcf_quran_lite.dart';
```

---

## ✨ Features & Usage Examples

### 📜 1. Authentic Mushaf Page Mode (604 Pages)

Displays the Quran in the real Madinah Mushaf layout (Page by Page). Fully customizable with PageController support.

```dart
final PageController _controller = PageController(initialPage: 0);
List<HighlightVerse> _activeHighlights = [];

QuranPageView(
pageController: _controller,
scaffoldKey: GlobalKey<ScaffoldState>(),
highlights: _activeHighlights,
onPageChanged: (pageNumber) {
print("User navigated to page: $pageNumber");
print(getCurrentHizbTextForPage(pageNumber));
},
onLongPress: (surahNumber, verseNumber, details) {
print("Tapped Surah: $surahNumber, Verse: $verseNumber");
},
);
```

---

### 📖 2. Vertical Reading Mode (Surah List)

A scrollable list view for a specific Surah. Ideal for Tafsir apps, translation views, or audio-synced Quran players.

```dart
final ItemScrollController _itemScrollController = ItemScrollController();
List<HighlightVerse> _activeHighlights = [];

QuranSurahListView(
  surahNumber: 1,
  itemScrollController: _itemScrollController,
  highlights: _activeHighlights,
  ayahBuilder: (context, surahNumber, verseNumber, othmanicText, isHighlighted, highlightColor) {
    return Container(
      color: isHighlighted ? highlightColor.withOpacity(0.2) : Colors.transparent,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ayah $verseNumber', style: const TextStyle(color: Colors.grey)),
          othmanicText,
        ],
      ),
    );
  },
);
```

---

### 🎯 3. Dynamic Ayah Highlighting

Easily highlight specific verses for audio tracking, bookmarks, or reading progress by passing a list of `HighlightVerse`.

```dart
List<HighlightVerse> _activeHighlights = [];

// Add a highlight (e.g., Ayatul Kursi)
setState(() {
  _activeHighlights = [
    HighlightVerse(
      surah: 2,
      verseNumber: 255,
      page: 42,
      color: Colors.amber.withOpacity(0.4),
    ),
  ];
});

// Clear all highlights
// setState(() => _activeHighlights = []);
```

---

### 🔍 4. Smart Arabic Search

A fast, in-memory, diacritic-insensitive search engine. It automatically normalizes Alef variations and unifies Ya/Hamza.

```dart
String query = normalise("الرحمن");
Map results = searchWords(query);

print("Total matches found: ${results['occurences']}");

for (var match in results['result']) {
  int sNum = match['sora'];
  int vNum = match['aya_no'];
  String text = match['text'];

  print('Surah: ${getSurahNameArabic(sNum)} - Ayah: $vNum');
  print('Verse Text: $text');
}
```

---

### 📊 5. Comprehensive Metadata API

Easily retrieve Surah names, Juz numbers, Quarters (Rub el Hizb), and Pages lookup without parsing large JSON files.

```dart
String arabicName = getSurahNameArabic(1);
String englishName = getSurahNameEnglish(1);
String place = getPlaceOfRevelation(1);
int totalAyahs = getVerseCount(1);

int pageNum = getPageNumber(2, 255);
int juzNum = getJuzNumber(2, 255);
int quarterNum = getQuarterNumber(2, 255);

String hizbText = getCurrentHizbTextForPage(5, isArabic: true);
```

---

### 📝 6. Text & Diacritics Helpers

Need the raw text, text without diacritics, or the beautiful Othmanic end-of-verse symbol?

```dart
String verse = getVerse(2, 255, verseEndSymbol: false);
String plainText = removeDiacritics(verse);
String glyph = getaya_noQCF(2, 255);
```

---

### 🧮 7. Built-in Constants

```dart
print(totalPagesCount);
print(totalSurahCount);
print(totalVerseCount);
print(totalMakkiSurahs);
print(totalMadaniSurahs);
print(totalJuzCount);
```

---

## 🎨 Customization Power

You have full control over the UI components. You can easily override:

* Surah Header
* Basmallah
* Ayah UI
* Text Style
* Page Background
* Top & Bottom Bars

---

## 🆕 Latest Updates

* Improved rendering performance
* Optimized search algorithm
* Better highlighting system
* Cleaner and more flexible API
* Reduced memory usage

---

## 📦 Use Cases

Perfect for:

* Quran apps
* Tafsir apps
* Educational platforms
* Audio Quran players

---

## 🤝 Contributing

Contributions are welcome!

If you have ideas, improvements, or bug fixes:

* Open an issue
* Submit a pull request

---

## 📬 Contact

**Hussein Khaled**
Package Developer : **Hussein Khaled**
LinkedIn: https://www.linkedin.com/in/hussein-khalid-703228364/

Feel free to reach out for:

* Collaboration
* Freelance work
* Suggestions

---

## 📄 License

MIT License

---

> Built with ❤️ for high-quality Quran applications.

```

