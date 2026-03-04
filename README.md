# qcf_quran_lite 📖

A lightweight, high-performance, and fully customizable Flutter package for rendering the Holy Quran using the official QCF (Hafs) script.

Built for production Quran apps that need:

• Authentic page-by-page Mushaf rendering  
• Vertical reading mode  
• Reactive highlighting  
• Audio synchronization  
• Advanced Arabic search  
• Fully offline data  

---

## ✨ Features

### 📜 1. Authentic Mushaf PageView (604 Pages)
- Real Madinah Mushaf layout
- PageController support
- Smart Surah Header & Basmallah rendering
- Fully customizable builders
- 60fps smooth rendering

---

### 📖 2. Vertical Reading Mode
- Surah-based scrollable list
- Ideal for Tafsir & translation apps
- Audio sync ready
- Custom ayahBuilder support

---

### 🔍 3. Smart Arabic Search
- Diacritics insensitive
- Alef variations normalized
- Ya/Hamza unified
- Fast in-memory search
- Returns max 50 results

---

### 🎯 4. High Performance Highlighting
- Powered by ValueNotifier
- No full rebuild
- Ideal for audio tracking & bookmarks

---

### 📊 5. Built-in Metadata API
- Surah names (Arabic & English)
- Juz number
- Quarter (Rub el Hizb)
- Page number lookup
- Makki / Madani
- Total counts constants

---

## 📸 Screenshots

> Replace image links with your repo raw images

<p align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Page+View" width="250"/>
  <img src="https://via.placeholder.com/250x500.png?text=Surah+List+View" width="250"/>
</p>

<p align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Search+Engine" width="250"/>
  <img src="https://via.placeholder.com/250x500.png?text=Highlighting" width="250"/>
</p>

---

# 🚀 Getting Started

## Add Dependency

```yaml
dependencies:
  qcf_quran_lite: ^latest_version
  scrollable_positioned_list: ^0.3.8
```

---

## Import

```dart
import 'package:qcf_quran_lite/qcf_quran_lite.dart';
```

---

# 🧩 Usage

---

## 📜 Mushaf Page Mode

```dart
final highlights = ValueNotifier<List<HighlightVerse>>([]);
final controller = PageController();

QuranPageView(
  pageController: controller,
  scaffoldKey: GlobalKey(),
  highlightsNotifier: highlights,
);
```

---

## 📖 Surah List Mode

```dart
QuranSurahListView(
  surahNumber: 1,
  highlightsNotifier: highlights,
);
```

---

## 🔍 Search Example

```dart
String query = normalise("الرحمن");
Map result = searchWords(query);

print(result["occurences"]);
print(result["result"]);
```

---

## 🎯 Highlight Example

```dart
highlights.value = [
  HighlightVerse(
    surah: 1,
    verseNumber: 2,
    page: 1,
    color: Colors.amber,
  ),
];
```

---

# 📦 Core API Examples

```dart
getSurahNameArabic(1);
getSurahNameEnglish(1);
getVerse(1,1);
getPageNumber(2,255);
getJuzNumber(2,255);
getQuarterNumber(2,255);
getCurrentHizbTextForPage(5);
```

---

# ⚡ Performance

• 100% Offline  
• Zero network requests  
• Optimized JSON structure  
• Efficient line rendering with QCF font  
• No expensive rebuild cycles  

---

# 🎨 Customization Power

You can override:

- Surah Header
- Basmallah
- Ayah UI
- Text Style
- Page background
- Top & Bottom bars

---

# 📚 Ideal For

- Quran reading apps  
- Tafsir apps  
- Translation apps  
- Memorization apps  
- Audio synced Quran players  

---

# 📄 License

MIT License

---

Made for serious Quran apps.  
Designed for performance.  
Engineered for flexibility.
