# qcf_quran_lite 📖

A highly performant, lightweight, and fully customizable Flutter package for building professional Quran applications.

It provides fully **offline Quranic data (Othmanic script)**, advanced normalized Arabic search, rich metadata APIs, and production-ready reading UI components.

---

## ✨ Features

- 📖 **Two Reading Modes**
  - `QuranPageView` — Classic Mushaf page-by-page layout
  - `QuranSurahListView` — Scrollable vertical list layout

- 🔍 **Advanced Arabic Normalized Search**
  - Ignores Tashkeel
  - Normalizes Alef variations
  - Handles Taa Marbuta & Ya forms
  - Accurate matching regardless of user input format

- 🎨 **Full Customization**
  - Custom `ayahBuilder`
  - Custom `surahHeaderBuilder`
  - Custom `basmallahBuilder`
  - Dark / Light mode adaptability

- ⚡ **High-Performance Highlighting**
  - Powered by `ValueNotifier`
  - No full screen rebuilds
  - Supports multiple & temporary highlights

- 🎵 **Audio Sync Ready**
  - Native support for `scrollable_positioned_list`
  - Perfect for syncing with audio players

- 📊 **Rich Metadata APIs**
  - Juz / Quarter / Hizb
  - Page number
  - Makki / Madani
  - Surah names (Arabic & English)

- 🌐 **RTL Ready**
  - Fully optimized for right-to-left rendering

- 🪶 **Lightweight**
  - Optimized JSON data structure

---

## 📸 Screenshots

> Replace with actual repository image links.

<p align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Classic+Mushaf+View" width="250"/>
  &nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=List+View" width="250"/>
  &nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Search+Engine" width="250"/>
</p>

---

# 🚀 Getting Started

## 1️⃣ Add Dependency

```yaml
dependencies:
  qcf_quran_lite: ^latest_version

  # Required for Audio Sync in List Mode
  scrollable_positioned_list: ^0.3.8
```

---

## 2️⃣ Import

```dart
import 'package:qcf_quran_lite/qcf_quran_lite.dart';
```

---

# 🛠 Usage Guide

---

## 1️⃣ Classic Mushaf Mode

```dart
final ValueNotifier<List<HighlightVerse>> _highlights = ValueNotifier([]);
final PageController _pageController = PageController();

QuranPageView(
  pageController: _pageController,
  highlightsNotifier: _highlights,
  ayahStyle: TextStyle(
    color: Theme.of(context).textTheme.bodyLarge!.color,
  ),
  onPageChanged: (pageNumber) {
    print('Current Page: $pageNumber');
  },
  onLongPress: (surahNumber, verseNumber, details) {
    _highlights.value = [
      HighlightVerse(
        surah: surahNumber,
        verseNumber: verseNumber,
        page: _pageController.page!.toInt() + 1,
        color: Colors.amber.withValues(alpha: 0.3),
      ),
    ];
  },
);
```

---

## 2️⃣ List Reading Mode

```dart
QuranSurahListView(
  surahNumber: 1,
  highlightsNotifier: _highlights,
  ayahStyle: const TextStyle(fontSize: 24),
);
```

---

## 3️⃣ Audio Sync & Auto Scrolling

```dart
final ItemScrollController _itemScrollController = ItemScrollController();

QuranSurahListView(
  surahNumber: 1,
  highlightsNotifier: _highlights,
  itemScrollController: _itemScrollController,
);

void syncWithAudio(int ayahIndex) {
  _itemScrollController.scrollTo(
    index: ayahIndex,
    duration: const Duration(milliseconds: 800),
    curve: Curves.easeInOutCubic,
    alignment: 0.3,
  );
}
```

---

## 4️⃣ Custom UI Builders

```dart
QuranSurahListView(
  surahNumber: 1,

  surahHeaderBuilder: (context, surahNum) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/mainframe.jpg',
          width: double.infinity,
          height: 65,
          fit: BoxFit.fill,
        ),
        Text(
          getSurahNameEnglish(surahNum),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  },

  ayahBuilder: (
    context,
    surahNumber,
    verseNumber,
    othmanicText,
    isHighlighted,
    highlightColor,
  ) {
    return Card(
      color: isHighlighted ? highlightColor : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          othmanicText,
          textAlign: TextAlign.right,
          style: QuranTextStyles.hafsStyle(fontSize: 26),
        ),
      ),
    );
  },
);
```

---

## 5️⃣ Smart Search Engine

```dart
String query = normalise("الرّحْمَٰن");

Map results = searchWords(query);

int totalOccurrences = results['occurences'];
List<Map> matches = List<Map>.from(results['result']);

for (var match in matches) {
  print("Surah: ${match['sora']} - Ayah: ${match['aya_no']}");
}
```

---

## 6️⃣ Reactive Highlighting

```dart
// Add highlight
_highlights.value = [
  ..._highlights.value,
  HighlightVerse(
    surah: 1,
    verseNumber: 2,
    page: 1,
    color: Colors.blue,
  ),
];

// Clear all
_highlights.value = [];
```

---

## 7️⃣ Metadata APIs

```dart
print(totalSurahCount);      // 114
print(totalVerseCount);      // 6236

String nameAr = getSurahNameArabic(1);
String nameEn = getSurahNameEnglish(1);
String type = getPlaceOfRevelation(1);
int verseCount = getVerseCount(1);

String text = getVerse(1, 1);
int page = getPageNumber(1, 1);
int juz = getJuzNumber(1, 1);
int quarter = getQuarterNumber(1, 1);

String hizb = getCurrentHizbTextForPage(1, isArabic: true);
String qcfSymbol = getaya_noQCF(1, 1);
```

---

## 📚 Complete Example

Check the `example/` folder for a full production-ready demo showcasing:

- Dark / Light theme adaptability  
- Audio synchronization simulation  
- Custom UI builders  
- Search interface  
- Verse metadata bottom sheets  

---

## 🤝 Contributions

Contributions, issues, and feature requests are welcome.

---

## ❤️ Credits

Special thanks to the King Fahd Complex for the Printing of the Holy Quran for the Othmanic script and metadata.

---

## 📄 License

This project is licensed under the MIT License.
