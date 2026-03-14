# 🕌 qcf_quran_lite

[![Pub Version](https://img.shields.io/pub/v/qcf_quran_lite?color=blue&style=flat-square)](https://pub.dev/packages/qcf_quran_lite)
[![Flutter](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter&style=flat-square)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

A **lightweight, high-performance Flutter Quran package** using the official **QCF (Hafs) font**.

Designed for professional Islamic applications, this package provides a fully offline, 60fps optimized Quran rendering engine. It adds **only ~10MB** to your app size while providing full Mushaf rendering, smart search, and a comprehensive metadata API.

---

## 📸 Screenshots

<p align="center">
  <img width="250" alt="Screenshot_20260304_165118" src="[https://github.com/user-attachments/assets/54df12fb-be44-4389-b091-82ce5917e45f](https://github.com/user-attachments/assets/54df12fb-be44-4389-b091-82ce5917e45f)" />
  <img width="250" alt="Screenshot_20260304_165147" src="[https://github.com/user-attachments/assets/99a8e173-c12c-4914-9afd-038b1e688a08](https://github.com/user-attachments/assets/99a8e173-c12c-4914-9afd-038b1e688a08)" />
</p>
<p align="center">
  <img width="250"  alt="Screenshot_20260304_165210" src="[https://github.com/user-attachments/assets/8352b9e6-1b3a-43a0-b185-3e08076cf59b](https://github.com/user-attachments/assets/8352b9e6-1b3a-43a0-b185-3e08076cf59b)" />
  <img width="250" alt="Screenshot_20260304_165812" src="[https://github.com/user-attachments/assets/72d2aaaf-cfd1-44ad-af6d-64ba8f9767dd](https://github.com/user-attachments/assets/72d2aaaf-cfd1-44ad-af6d-64ba8f9767dd)" />
</p>

---

## 🌟 Why `qcf_quran_lite`?

Most Quran packages are either too heavy or require network downloads. This package is:
- **100% Offline-ready:** No internet required.
- **Minimal Size Impact:** Approx. 10MB for the complete 604-page Quran data and fonts.
- **Highly Performant:** Built for 60fps smooth scrolling with optimized JSON structures and efficient line rendering.

---

## 🚀 Getting Started

### 1. Add Dependencies

Update your `pubspec.yaml`:

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
Displays the Quran in the real Madinah Mushaf layout (Page by Page). Fully customizable with PageController support.

**Example:**
```dart
final PageController _controller = PageController(initialPage: 0); // Page 1
List<HighlightVerse> _activeHighlights = [];

QuranPageView(
  pageController: _controller,
  scaffoldKey: GlobalKey<ScaffoldState>(),
  highlights: _activeHighlights,
  onPageChanged: (pageNumber) {
    print("User navigated to page: $pageNumber");
    print(getCurrentHizbTextForPage(pageNumber)); // e.g., "نصف الحزب ١"
  },
  onLongPress: (surahNumber, verseNumber, details) {
    // Perfect for showing a bottom sheet with Tafsir or copying options
    print("Tapped Surah: $surahNumber, Verse: $verseNumber");
  },
);
```

---

### 📖 2. Vertical Reading Mode (Surah List)
A scrollable list view for a specific Surah. Ideal for Tafsir apps, translation views, or audio-synced Quran players.

**Example:**
```dart
final ItemScrollController _itemScrollController = ItemScrollController();
List<HighlightVerse> _activeHighlights = [];

QuranSurahListView(
  surahNumber: 1, // Al-Fatihah
  itemScrollController: _itemScrollController,
  highlights: _activeHighlights,
  // Fully customizable Ayah Builder!
  ayahBuilder: (context, surahNumber, verseNumber, othmanicText, isHighlighted, highlightColor) {
    return Container(
      color: isHighlighted ? highlightColor.withOpacity(0.2) : Colors.transparent,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ayah $verseNumber', style: const TextStyle(color: Colors.grey)),
          othmanicText, // The natively rendered QCF text widget
        ],
      ),
    );
  },
);
```

---

### 🎯 3. Dynamic Ayah Highlighting
Easily highlight specific verses for audio tracking, bookmarks, or reading progress by passing a list of `HighlightVerse`.

**Example:**
```dart
List<HighlightVerse> _activeHighlights = [];

// Add a highlight (e.g., Ayatul Kursi) and update the UI
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

**Example:**
```dart
// 1. Clean the input
String query = normalise("الرحمن");

// 2. Search (Returns up to 50 results)
Map results = searchWords(query);

print("Total matches found: ${results['occurences']}");

// 3. Display results
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

**Example:**
```dart
// Surah Information
String arabicName = getSurahNameArabic(1);    // الفاتحة
String englishName = getSurahNameEnglish(1);  // Al-Faatiha
String place = getPlaceOfRevelation(1);       // Makkah
int totalAyahs = getVerseCount(1);            // 7

// Juz, Quarter, and Page Lookups
int pageNum = getPageNumber(2, 255);          // 42
int juzNum = getJuzNumber(2, 255);            // 3
int quarterNum = getQuarterNumber(2, 255);    // 19

// Hizb Text Generation
String hizbText = getCurrentHizbTextForPage(5, isArabic: true); // نصف الحزب ١
```

---

### 📝 6. Text & Diacritics Helpers
Need the raw text, text without diacritics, or the beautiful Othmanic end-of-verse symbol?

**Example:**
```dart
// Get raw verse text
String verse = getVerse(2, 255, verseEndSymbol: false);

// Get verse text stripped of Tashkeel (diacritics) for fuzzy matching
String plainText = removeDiacritics(verse);

// Get the highly optimized QCF Ayah number glyph (e.g., ۝ )
String glyph = getaya_noQCF(2, 255); 
```

---

### 🧮 7. Built-in Constants
Use these provided constants for quick statistics in your app.

**Example:**
```dart
print(totalPagesCount);    // 604
print(totalSurahCount);    // 114
print(totalVerseCount);    // 6236
print(totalMakkiSurahs);   // 89
print(totalMadaniSurahs);  // 25
print(totalJuzCount);      // 30
```

---

## 🎨 Customization Power

You have full control over the UI components. You can easily override:
- Surah Header
- Basmallah
- Ayah UI
- Text Style
- Page background
- Top & Bottom bars

---

## 📄 License

MIT License

*Made for serious Quran apps. Designed for performance. Engineered for flexibility.*